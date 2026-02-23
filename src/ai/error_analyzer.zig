//! Error Analyzer - Analyzes command failures and suggests fixes.
//!
//! This module provides intelligent error analysis:
//! - Detects errors via OSC 133 semantic prompts or exit codes
//! - Explains errors in plain English
//! - Suggests fixes and corrected commands
//! - Handles cascading failures with retry limits

const std = @import("std");

/// Context for error analysis.
pub const ErrorContext = struct {
    /// The command that failed.
    command: []const u8,

    /// Exit code from the command.
    exit_code: u32,

    /// Standard error output.
    stderr: ?[]const u8 = null,

    /// Standard output (may contain partial results).
    stdout: ?[]const u8 = null,

    /// Current working directory.
    cwd: ?[]const u8 = null,

    /// Shell type.
    shell: ?[]const u8 = null,

    /// Allocator for strings.
    allocator: std.mem.Allocator,

    pub fn deinit(self: *ErrorContext) void {
        self.allocator.free(self.command);
        if (self.stderr) |stderr| self.allocator.free(stderr);
        if (self.stdout) |stdout| self.allocator.free(stdout);
        if (self.cwd) |cwd| self.allocator.free(cwd);
        if (self.shell) |shell| self.allocator.free(shell);
    }
};

/// Suggested fix for an error.
pub const ErrorSuggestion = struct {
    /// Plain English explanation of the error.
    explanation: []const u8,

    /// Suggested fix command (if available).
    fix_command: ?[]const u8 = null,

    /// Whether the fix can be auto-applied.
    auto_applicable: bool = false,

    /// Confidence level (0.0 - 1.0).
    confidence: f32 = 0.0,

    /// Allocator for strings.
    allocator: std.mem.Allocator,

    pub fn deinit(self: *ErrorSuggestion) void {
        self.allocator.free(self.explanation);
        if (self.fix_command) |cmd| self.allocator.free(cmd);
    }
};

/// Result of error analysis.
pub const AnalysisResult = struct {
    /// Whether an error was detected.
    is_error: bool,

    /// Whether this is an expected non-zero exit (e.g., grep with no matches).
    expected_non_zero: bool = false,

    /// List of suggestions.
    suggestions: []ErrorSuggestion = &.{},

    /// Retry count for cascading failures.
    retry_count: u32 = 0,

    /// Allocator for strings.
    allocator: std.mem.Allocator,

    pub fn deinit(self: *AnalysisResult) void {
        for (self.suggestions) |*suggestion| {
            suggestion.deinit();
        }
        self.allocator.free(self.suggestions);
    }
};

/// Configuration for the error analyzer.
pub const Config = struct {
    /// Maximum retry attempts for cascading failures.
    max_retries: u32 = 3,

    /// Whether to use OSC 133 for error detection.
    use_osc133: bool = true,

    /// Minimum confidence threshold for auto-suggestions.
    confidence_threshold: f32 = 0.7,
};

/// Error analyzer for command failures.
pub const ErrorAnalyzer = struct {
    allocator: std.mem.Allocator,
    config: Config,
    llm: ?@import("llm_interface.zig").LlmInterface = null,

    /// Initialize a new error analyzer.
    pub fn init(allocator: std.mem.Allocator, config: Config) ErrorAnalyzer {
        return .{
            .allocator = allocator,
            .config = config,
        };
    }

    /// Set the LLM interface for AI-powered analysis.
    pub fn setLlm(self: *ErrorAnalyzer, llm: @import("llm_interface.zig").LlmInterface) void {
        self.llm = llm;
    }

    /// Analyze a command failure.
    /// TODO: Implement actual analysis with LLM integration.
    pub fn analyze(self: *ErrorAnalyzer, context: ErrorContext) !AnalysisResult {
        return AnalysisResult{
            .is_error = context.exit_code != 0,
            .allocator = self.allocator,
        };
    }

    /// Detect if the command failure is a real error or expected behavior.
    /// Commands like `grep`, `test`, `diff` may exit non-zero intentionally.
    pub fn isExpectedNonZero(self: *ErrorAnalyzer, command: []const u8, exit_code: u32) bool {
        _ = self;
        _ = exit_code;

        const expected_commands = [_][]const u8{ "grep", "test", "diff", "cmp", "expr" };
        for (expected_commands) |expected| {
            if (std.mem.startsWith(u8, command, expected)) {
                return true;
            }
        }
        return false;
    }

    pub fn deinit(self: *ErrorAnalyzer) void {
        _ = self;
    }
};

test {
    _ = ErrorContext;
    _ = ErrorSuggestion;
    _ = AnalysisResult;
    _ = Config;
    _ = ErrorAnalyzer;
}
