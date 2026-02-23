//! Context Collector - Gathers terminal context for AI processing.
//!
//! This module collects relevant context from the terminal state:
//! - Current working directory
//! - Screen content
//! - Command history
//! - Git repository status
//! - Environment information

const std = @import("std");

/// Collected context for AI processing.
pub const Context = struct {
    /// Current working directory.
    cwd: ?[]const u8 = null,

    /// Visible screen content.
    screen_content: ?[]const u8 = null,

    /// Recent command history.
    command_history: []const []const u8 = &.{},

    /// Git repository status (if in a git repo).
    git_status: ?GitStatus = null,

    /// Shell type (zsh, bash, fish, etc.).
    shell: ?[]const u8 = null,

    /// Allocator used for strings.
    allocator: std.mem.Allocator,

    pub fn deinit(self: *Context) void {
        if (self.cwd) |cwd| self.allocator.free(cwd);
        if (self.screen_content) |screen| self.allocator.free(screen);
        for (self.command_history) |cmd| {
            self.allocator.free(cmd);
        }
        self.allocator.free(self.command_history);
        if (self.shell) |shell| self.allocator.free(shell);
        if (self.git_status) |*git| git.deinit(self.allocator);
    }
};

/// Git repository status information.
pub const GitStatus = struct {
    /// Current branch name.
    branch: ?[]const u8 = null,

    /// Whether there are uncommitted changes.
    has_changes: bool = false,

    /// Number of ahead commits.
    ahead: u32 = 0,

    /// Number of behind commits.
    behind: u32 = 0,

    pub fn deinit(self: *GitStatus, allocator: std.mem.Allocator) void {
        if (self.branch) |branch| allocator.free(branch);
    }
};

/// Context collector configuration.
pub const Config = struct {
    /// Maximum lines of screen content to capture.
    screen_lines: u32 = 100,

    /// Maximum commands in history to include.
    history_lines: u32 = 50,

    /// Whether to include git status.
    include_git_status: bool = true,

    /// Patterns to exclude from context (e.g., .env paths).
    exclude_patterns: []const []const u8 = &.{},
};

/// Context collector for gathering terminal state.
pub const ContextCollector = struct {
    allocator: std.mem.Allocator,
    config: Config,

    /// Initialize a new context collector.
    pub fn init(allocator: std.mem.Allocator, config: Config) ContextCollector {
        return .{
            .allocator = allocator,
            .config = config,
        };
    }

    /// Collect context from the current terminal state.
    /// TODO: Implement actual context collection from terminal state.
    pub fn collect(self: *ContextCollector) !Context {
        return Context{
            .allocator = self.allocator,
        };
    }

    /// Sanitize context by redacting sensitive information.
    /// TODO: Implement pattern-based redaction.
    pub fn sanitize(_: *ContextCollector, _: *Context) void {}

    pub fn deinit(self: *ContextCollector) void {
        _ = self;
    }
};

test {
    _ = Context;
    _ = GitStatus;
    _ = Config;
    _ = ContextCollector;
}
