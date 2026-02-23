//! llama.cpp Provider - FFI bindings for llama.cpp library.
//!
//! This module provides an LLM interface implementation that directly
//! interfaces with llama.cpp via FFI for maximum performance.
//!
//! See: https://github.com/ggerganov/llama.cpp

const std = @import("std");
const LlmInterface = @import("../llm_interface.zig").LlmInterface;
const GenerationOptions = @import("../llm_interface.zig").GenerationOptions;
const GenerationResult = @import("../llm_interface.zig").GenerationResult;

/// Configuration for llama.cpp provider.
pub const Config = struct {
    /// Path to the GGUF model file.
    model_path: []const u8,

    /// Number of GPU layers to offload (0 = CPU only).
    n_gpu_layers: u32 = 0,

    /// Context window size.
    n_ctx: u32 = 4096,

    /// Number of threads for inference.
    n_threads: u32 = 4,

    /// Memory mapped mode.
    use_mmap: bool = true,
};

/// llama.cpp provider implementation.
pub const LlamaProvider = struct {
    allocator: std.mem.Allocator,
    config: Config,

    const Self = @This();

    /// Initialize a new llama.cpp provider.
    /// TODO: Implement actual llama.cpp initialization.
    pub fn init(allocator: std.mem.Allocator, config: Config) !*Self {
        const self = try allocator.create(Self);
        self.* = .{
            .allocator = allocator,
            .config = config,
        };
        return self;
    }

    /// Get the LLM interface for this provider.
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

    /// Generate text from a prompt.
    /// TODO: Implement llama.cpp FFI calls.
    fn generate(
        ctx: *anyopaque,
        allocator: std.mem.Allocator,
        prompt: []const u8,
        options: GenerationOptions,
    ) anyerror!GenerationResult {
        const self: *Self = @ptrCast(@alignCast(ctx));
        _ = self;
        _ = options;

        return GenerationResult{
            .text = try allocator.dupe(u8, prompt),
            .allocator = allocator,
        };
    }

    /// Generate text with streaming.
    /// TODO: Implement streaming llama.cpp calls.
    fn generateStream(
        ctx: *anyopaque,
        _: std.mem.Allocator,
        _: []const u8,
        _: GenerationOptions,
        _: anytype,
    ) anyerror!void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        _ = self;
    }

    /// Free resources.
    fn deinit(ctx: *anyopaque) void {
        const self: *Self = @ptrCast(@alignCast(ctx));
        self.allocator.destroy(self);
    }
};

test {
    _ = Config;
    _ = LlamaProvider;
}
