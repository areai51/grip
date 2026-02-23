//! LLM Interface - Model-agnostic interface for LLM backends.
//!
//! This module defines a vtable-based interface that allows the terminal
//! to work with different LLM backends (Ollama, llama.cpp, Jan, etc.)
//! without being coupled to any specific implementation.

const std = @import("std");

pub const LlmError = error{
    OutOfMemory,
    ConnectionFailed,
    ConnectionRefused,
    Timeout,
    InvalidResponse,
    ModelNotFound,
    ContextTooLong,
    GenerationFailed,
    InvalidEndpoint,
    StreamAborted,
    HttpError,
    JsonParseError,
};

pub const StreamCallback = *const fn (ctx: *anyopaque, chunk: []const u8) void;

pub const GenerationOptions = struct {
    max_tokens: u32 = 512,
    temperature: f32 = 0.7,
    top_p: f32 = 0.9,
    top_k: u32 = 40,
    stop_sequences: []const []const u8 = &.{},
    stream: bool = false,
    seed: ?u32 = null,
};

pub const GenerationResult = struct {
    text: []const u8,
    prompt_tokens: u32 = 0,
    completion_tokens: u32 = 0,
    total_duration_us: u64 = 0,
    allocator: std.mem.Allocator,

    pub fn deinit(self: *GenerationResult) void {
        self.allocator.free(self.text);
    }
};

pub const VTable = struct {
    generate: *const fn (ctx: *anyopaque, allocator: std.mem.Allocator, prompt: []const u8, options: GenerationOptions) anyerror!GenerationResult,
    generateStream: *const fn (ctx: *anyopaque, allocator: std.mem.Allocator, prompt: []const u8, options: GenerationOptions, callback: StreamCallback, callback_ctx: *anyopaque) anyerror!void,
    deinit: *const fn (ctx: *anyopaque) void,
};

pub const LlmInterface = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub fn generate(
        self: LlmInterface,
        allocator: std.mem.Allocator,
        prompt: []const u8,
        options: GenerationOptions,
    ) !GenerationResult {
        return self.vtable.generate(self.ptr, allocator, prompt, options);
    }

    pub fn generateStream(
        self: LlmInterface,
        allocator: std.mem.Allocator,
        prompt: []const u8,
        options: GenerationOptions,
        callback: StreamCallback,
        callback_ctx: *anyopaque,
    ) !void {
        return self.vtable.generateStream(self.ptr, allocator, prompt, options, callback, callback_ctx);
    }

    pub fn deinit(self: LlmInterface) void {
        self.vtable.deinit(self.ptr);
    }
};

test "GenerationOptions defaults" {
    const opts = GenerationOptions{};
    try std.testing.expectEqual(@as(u32, 512), opts.max_tokens);
    try std.testing.expectEqual(@as(f32, 0.7), opts.temperature);
    try std.testing.expectEqual(@as(f32, 0.9), opts.top_p);
    try std.testing.expectEqual(@as(u32, 40), opts.top_k);
    try std.testing.expectEqual(@as(usize, 0), opts.stop_sequences.len);
    try std.testing.expect(!opts.stream);
    try std.testing.expect(opts.seed == null);
}

test "GenerationResult deinit" {
    const allocator = std.testing.allocator;
    var result = GenerationResult{
        .text = try allocator.dupe(u8, "test output"),
        .allocator = allocator,
    };
    result.deinit();
}

test "VTable function signatures" {
    const TestProvider = struct {
        fn generate(_: *anyopaque, _: std.mem.Allocator, prompt: []const u8, _: GenerationOptions) anyerror!GenerationResult {
            const allocator = std.testing.allocator;
            return GenerationResult{
                .text = try allocator.dupe(u8, prompt),
                .allocator = allocator,
            };
        }
        fn generateStream(_: *anyopaque, _: std.mem.Allocator, _: []const u8, _: GenerationOptions, _: StreamCallback, _: *anyopaque) anyerror!void {}
        fn deinit(_: *anyopaque) void {}
    };

    const vtable = VTable{
        .generate = TestProvider.generate,
        .generateStream = TestProvider.generateStream,
        .deinit = TestProvider.deinit,
    };

    var dummy: u8 = 0;
    const iface = LlmInterface{ .ptr = &dummy, .vtable = &vtable };

    var result = try iface.generate(std.testing.allocator, "test", .{});
    defer result.deinit();
    try std.testing.expectEqualStrings("test", result.text);
}
