//! Ollama Provider - HTTP client for Ollama LLM server.
//!
//! This module provides an LLM interface implementation that connects
//! to a local Ollama server via HTTP API.
//!
//! API Documentation: https://github.com/ollama/ollama/blob/main/docs/api.md

const std = @import("std");
const LlmInterface = @import("../llm_interface.zig").LlmInterface;
const GenerationOptions = @import("../llm_interface.zig").GenerationOptions;
const GenerationResult = @import("../llm_interface.zig").GenerationResult;
const StreamCallback = @import("../llm_interface.zig").StreamCallback;
const LlmError = @import("../llm_interface.zig").LlmError;

pub const Config = struct {
    endpoint: []const u8 = "http://localhost:11434",
    model: []const u8 = "gemma:7b",
    timeout_ms: u32 = 30000,
    keep_alive: []const u8 = "5m",
};

pub const OllamaProvider = struct {
    allocator: std.mem.Allocator,
    config: Config,
    http_client: ?*std.http.Client = null,
    owned_endpoint: []const u8,
    owned_model: []const u8,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, config: Config) !*Self {
        const self = try allocator.create(Self);
        errdefer allocator.destroy(self);

        self.allocator = allocator;
        self.owned_endpoint = try allocator.dupe(u8, config.endpoint);
        self.owned_model = try allocator.dupe(u8, config.model);

        const client = try allocator.create(std.http.Client);
        client.* = .{ .allocator = allocator };
        self.http_client = client;
        self.config = config;

        return self;
    }

    pub fn interface(self: *Self) LlmInterface {
        return .{
            .ptr = self,
            .vtable = &.{
                .generate = generate,
                .generateStream = generateStream,
                .deinit = deinit,
            },
        };
    }

    fn generate(
        ctx: *anyopaque,
        allocator: std.mem.Allocator,
        prompt: []const u8,
        options: GenerationOptions,
    ) anyerror!GenerationResult {
        const self: *Self = @ptrCast(@alignCast(ctx));
        return self.generateImpl(allocator, prompt, options);
    }

    fn generateImpl(self: *Self, allocator: std.mem.Allocator, prompt: []const u8, options: GenerationOptions) !GenerationResult {
        const client = self.http_client orelse return LlmError.ConnectionFailed;

        var body = std.ArrayList(u8).init(allocator);
        defer body.deinit();

        try self.buildRequestBody(body.writer(), prompt, options, false);

        _ = try std.Uri.parse(self.owned_endpoint);
        const full_uri = try std.Uri.parse("/api/generate");

        const server_header_buf = try allocator.alloc(u8, 16384);
        errdefer allocator.free(server_header_buf);

        var req = client.open(.POST, full_uri, .{
            .server_header_buffer = server_header_buf,
            .extra_headers = &.{
                .{ .name = "Content-Type", .value = "application/json" },
            },
        }) catch |err| {
            allocator.free(server_header_buf);
            return mapHttpError(err);
        };
        defer {
            req.deinit();
            allocator.free(server_header_buf);
        }

        req.transfer_encoding = .{ .content_length = body.items.len };
        req.send() catch |err| return mapHttpError(err);
        req.writer().writeAll(body.items) catch |err| return mapHttpError(err);
        req.finish() catch |err| return mapHttpError(err);

        req.wait() catch |err| return mapHttpError(err);

        if (req.response.status != .ok) {
            return LlmError.HttpError;
        }

        var response_body = std.ArrayList(u8).init(allocator);
        defer response_body.deinit();
        try req.reader().readAllArrayList(&response_body, 1024 * 1024);

        return self.parseResponse(allocator, response_body.items);
    }

    fn generateStream(
        ctx: *anyopaque,
        allocator: std.mem.Allocator,
        prompt: []const u8,
        options: GenerationOptions,
        callback: StreamCallback,
        callback_ctx: *anyopaque,
    ) anyerror!void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        return self.generateStreamImpl(allocator, prompt, options, callback, callback_ctx);
    }

    fn generateStreamImpl(
        self: *Self,
        allocator: std.mem.Allocator,
        prompt: []const u8,
        options: GenerationOptions,
        callback: StreamCallback,
        callback_ctx: *anyopaque,
    ) !void {
        const client = self.http_client orelse return LlmError.ConnectionFailed;

        var body = std.ArrayList(u8).init(allocator);
        defer body.deinit();

        try self.buildRequestBody(body.writer(), prompt, options, true);

        const full_uri = try std.Uri.parse("/api/generate");
        const server_header_buf = try allocator.alloc(u8, 16384);
        defer allocator.free(server_header_buf);

        var req = client.open(.POST, full_uri, .{
            .server_header_buffer = server_header_buf,
            .extra_headers = &.{
                .{ .name = "Content-Type", .value = "application/json" },
            },
        }) catch |err| return mapHttpError(err);
        defer req.deinit();

        req.transfer_encoding = .{ .content_length = body.items.len };
        req.send() catch |err| return mapHttpError(err);
        req.writer().writeAll(body.items) catch |err| return mapHttpError(err);
        req.finish() catch |err| return mapHttpError(err);

        req.wait() catch |err| return mapHttpError(err);

        if (req.response.status != .ok) {
            return LlmError.HttpError;
        }

        var line_buf = std.ArrayList(u8).init(allocator);
        defer line_buf.deinit();

        var reader = req.reader();
        while (true) {
            line_buf.clearRetainingCapacity();
            reader.streamUntilDelimiter(line_buf.writer(), '\n', null) catch |err| {
                if (err == error.EndOfStream) break;
                return mapHttpError(err);
            };

            if (line_buf.items.len == 0) continue;

            const chunk = self.parseStreamChunk(allocator, line_buf.items) catch |err| {
                if (err == error.EndOfStream) break;
                continue;
            };
            if (chunk.len > 0) {
                callback(callback_ctx, chunk);
                allocator.free(chunk);
            }
        }
    }

    fn buildRequestBody(self: *Self, writer: anytype, prompt: []const u8, options: GenerationOptions, stream: bool) !void {
        try writer.print("{{\"model\":\"{s}\",\"prompt\":", .{self.owned_model});
        try writeJsonString(writer, prompt);
        try writer.print(",\"stream\":{s}", .{if (stream) "true" else "false"});

        if (options.max_tokens != 512) {
            try writer.print(",\"num_predict\":{}", .{options.max_tokens});
        }
        if (options.temperature != 0.7) {
            try writer.print(",\"temperature\":{d:.2}", .{options.temperature});
        }
        if (options.top_p != 0.9) {
            try writer.print(",\"top_p\":{d:.2}", .{options.top_p});
        }
        if (options.top_k != 40) {
            try writer.print(",\"top_k\":{}", .{options.top_k});
        }
        if (options.seed) |seed| {
            try writer.print(",\"seed\":{}", .{seed});
        }
        if (options.stop_sequences.len > 0) {
            try writer.writeAll(",\"stop\":[");
            for (options.stop_sequences, 0..) |stop, i| {
                if (i > 0) try writer.writeAll(",");
                try writeJsonString(writer, stop);
            }
            try writer.writeAll("]");
        }

        try writer.print(",\"keep_alive\":\"{s}\"", .{self.config.keep_alive});
        try writer.writeAll("}");
    }

    fn parseResponse(self: *Self, allocator: std.mem.Allocator, body: []const u8) !GenerationResult {
        _ = self;
        const parsed = std.json.parseFromSlice(std.json.Value, allocator, body, .{}) catch
            return LlmError.JsonParseError;
        defer parsed.deinit();

        const root = parsed.value;

        if (root.object.get("error")) |err_val| {
            _ = err_val;
            return LlmError.GenerationFailed;
        }

        const response_text = if (root.object.get("response")) |resp| resp.string else "";

        const prompt_tokens: u32 = blk: {
            if (root.object.get("prompt_eval_count")) |pec| {
                break :blk @intCast(pec.integer);
            }
            break :blk 0;
        };

        const completion_tokens: u32 = blk: {
            if (root.object.get("eval_count")) |ec| {
                break :blk @intCast(ec.integer);
            }
            break :blk 0;
        };

        return GenerationResult{
            .text = try allocator.dupe(u8, response_text),
            .prompt_tokens = prompt_tokens,
            .completion_tokens = completion_tokens,
            .allocator = allocator,
        };
    }

    fn parseStreamChunk(self: *Self, allocator: std.mem.Allocator, line: []const u8) ![]const u8 {
        _ = self;
        const parsed = std.json.parseFromSlice(std.json.Value, allocator, line, .{}) catch
            return LlmError.JsonParseError;
        defer parsed.deinit();

        const root = parsed.value;

        if (root.object.get("done")) |done| {
            if (done.bool) return error.EndOfStream;
        }

        if (root.object.get("response")) |resp| {
            return allocator.dupe(u8, resp.string);
        }

        return "";
    }

    fn deinit(ctx: *anyopaque) void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        if (self.http_client) |client| {
            client.deinit();
            self.allocator.destroy(client);
        }
        self.allocator.free(self.owned_endpoint);
        self.allocator.free(self.owned_model);
        self.allocator.destroy(self);
    }
};

fn writeJsonString(writer: anytype, s: []const u8) !void {
    try writer.writeByte('"');
    for (s) |c| {
        switch (c) {
            '"' => try writer.writeAll("\\\""),
            '\\' => try writer.writeAll("\\\\"),
            '\n' => try writer.writeAll("\\n"),
            '\r' => try writer.writeAll("\\r"),
            '\t' => try writer.writeAll("\\t"),
            else => try writer.writeByte(c),
        }
    }
    try writer.writeByte('"');
}

fn mapHttpError(err: anyerror) LlmError {
    return switch (err) {
        error.ConnectionRefused => LlmError.ConnectionRefused,
        error.ConnectionTimedOut => LlmError.Timeout,
        error.NetworkUnreachable, error.HostUnreachable => LlmError.ConnectionFailed,
        else => LlmError.HttpError,
    };
}

test "Config defaults" {
    const config = Config{};
    try std.testing.expectEqualStrings("http://localhost:11434", config.endpoint);
    try std.testing.expectEqualStrings("gemma:7b", config.model);
    try std.testing.expectEqual(@as(u32, 30000), config.timeout_ms);
}

test "OllamaProvider init and deinit" {
    const allocator = std.testing.allocator;
    const provider = try OllamaProvider.init(allocator, .{});
    defer provider.interface().deinit();
    try std.testing.expect(provider.http_client != null);
}

test "OllamaProvider with custom config" {
    const allocator = std.testing.allocator;
    const provider = try OllamaProvider.init(allocator, .{
        .endpoint = "http://192.168.1.100:11434",
        .model = "llama3:8b",
    });
    defer provider.interface().deinit();
    try std.testing.expectEqualStrings("http://192.168.1.100:11434", provider.owned_endpoint);
    try std.testing.expectEqualStrings("llama3:8b", provider.owned_model);
}

test "writeJsonString escapes special characters" {
    const allocator = std.testing.allocator;
    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();

    try writeJsonString(buf.writer(), "hello\nworld\"test");
    try std.testing.expectEqualStrings("\"hello\\nworld\\\"test\"", buf.items);
}

test "buildRequestBody generates valid JSON structure" {
    const allocator = std.testing.allocator;
    var provider = try OllamaProvider.init(allocator, .{ .model = "test-model" });
    defer provider.interface().deinit();

    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();

    try provider.buildRequestBody(buf.writer(), "test prompt", .{}, false);
    try std.testing.expect(std.mem.indexOf(u8, buf.items, "\"model\":\"test-model\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, buf.items, "\"prompt\":\"test prompt\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, buf.items, "\"stream\":false") != null);
}

test "buildRequestBody with custom options" {
    const allocator = std.testing.allocator;
    var provider = try OllamaProvider.init(allocator, .{});
    defer provider.interface().deinit();

    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();

    const opts = GenerationOptions{
        .max_tokens = 1024,
        .temperature = 0.5,
        .top_p = 0.8,
        .seed = 42,
    };

    try provider.buildRequestBody(buf.writer(), "prompt", opts, true);
    try std.testing.expect(std.mem.indexOf(u8, buf.items, "\"num_predict\":1024") != null);
    try std.testing.expect(std.mem.indexOf(u8, buf.items, "\"temperature\":0.50") != null);
    try std.testing.expect(std.mem.indexOf(u8, buf.items, "\"top_p\":0.80") != null);
    try std.testing.expect(std.mem.indexOf(u8, buf.items, "\"seed\":42") != null);
    try std.testing.expect(std.mem.indexOf(u8, buf.items, "\"stream\":true") != null);
}

test "mapHttpError converts errors correctly" {
    try std.testing.expectEqual(LlmError.ConnectionRefused, mapHttpError(error.ConnectionRefused));
    try std.testing.expectEqual(LlmError.Timeout, mapHttpError(error.ConnectionTimedOut));
    try std.testing.expectEqual(LlmError.HttpError, mapHttpError(error.Unknown));
}

test "parseResponse extracts text from valid JSON" {
    const allocator = std.testing.allocator;
    var provider = try OllamaProvider.init(allocator, .{});
    defer provider.interface().deinit();

    const json_response = "{\"model\":\"gemma:7b\",\"response\":\"Hello, world!\",\"done\":true,\"prompt_eval_count\":10,\"eval_count\":5}";
    var result = try provider.parseResponse(allocator, json_response);
    defer result.deinit();

    try std.testing.expectEqualStrings("Hello, world!", result.text);
    try std.testing.expectEqual(@as(u32, 10), result.prompt_tokens);
    try std.testing.expectEqual(@as(u32, 5), result.completion_tokens);
}
