//! Context Collector - Gathers terminal context for AI processing.
//!
//! This module collects relevant context from the terminal state:
//! - Current working directory
//! - Screen content
//! - Command history
//! - Git repository status
//! - Environment information

const std = @import("std");
const os = @import("../os/main.zig");

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

    /// Build a prompt context string for AI processing.
    pub fn formatPrompt(self: *const Context, writer: anytype) !void {
        if (self.cwd) |cwd| {
            try writer.print("Current directory: {s}\n", .{cwd});
        }
        if (self.shell) |shell| {
            try writer.print("Shell: {s}\n", .{shell});
        }
        if (self.git_status) |git| {
            try writer.writeAll("Git status:");
            if (git.branch) |branch| {
                try writer.print(" branch={s}", .{branch});
            }
            if (git.has_changes) {
                try writer.writeAll(" has_changes");
            }
            if (git.ahead > 0) {
                try writer.print(" ahead={}", .{git.ahead});
            }
            if (git.behind > 0) {
                try writer.print(" behind={}", .{git.behind});
            }
            try writer.writeAll("\n");
        }
        if (self.screen_content) |screen| {
            try writer.print("Screen content:\n{s}\n", .{screen});
        }
        if (self.command_history.len > 0) {
            try writer.writeAll("Recent commands:\n");
            for (self.command_history) |cmd| {
                try writer.print("  {s}\n", .{cmd});
            }
        }
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

    /// Parse git status output into GitStatus.
    pub fn parse(allocator: std.mem.Allocator, output: []const u8) !GitStatus {
        var result = GitStatus{};

        // Parse branch from first line: "On branch <name>"
        if (std.mem.indexOf(u8, output, "On branch ")) |idx| {
            const start = idx + 10;
            if (std.mem.indexOfScalar(u8, output[start..], '\n')) |end| {
                result.branch = try allocator.dupe(u8, output[start .. start + end]);
            }
        }

        // Check for changes
        result.has_changes = std.mem.indexOf(u8, output, "Changes not staged") != null or
            std.mem.indexOf(u8, output, "Changes to be committed") != null or
            std.mem.indexOf(u8, output, "Untracked files") != null;

        // Parse ahead/behind from "Your branch is ahead/behind"
        if (std.mem.indexOf(u8, output, "ahead")) |idx| {
            const ahead_start = idx + 6;
            var iter = std.mem.splitScalar(u8, output[ahead_start..], ' ');
            if (iter.next()) |num_str| {
                if (std.fmt.parseInt(u32, num_str, 10)) |num| {
                    result.ahead = num;
                } else |_| {}
            }
        }
        if (std.mem.indexOf(u8, output, "behind")) |idx| {
            const behind_start = idx + 7;
            var iter = std.mem.splitScalar(u8, output[behind_start..], ' ');
            if (iter.next()) |num_str| {
                if (std.fmt.parseInt(u32, num_str, 10)) |num| {
                    result.behind = num;
                } else |_| {}
            }
        }

        return result;
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
    /// Note: This is a simplified implementation. Full implementation would
    /// integrate with the Terminal and Screen structures to capture actual
    /// screen content and command history.
    pub fn collect(self: *ContextCollector) !Context {
        var context = Context{
            .allocator = self.allocator,
        };

        // Capture current working directory
        context.cwd = self.captureCwd();

        // Capture shell type
        context.shell = self.detectShell();

        // Capture git status if enabled
        if (self.config.include_git_status and context.cwd) |cwd| {
            context.git_status = self.captureGitStatus(cwd) catch null;
        }

        // Capture screen content (placeholder - would integrate with Screen)
        // context.screen_content = self.captureScreenContent();

        // Capture command history (placeholder - would integrate with history)
        // context.command_history = self.captureCommandHistory();

        return context;
    }

    /// Capture the current working directory.
    fn captureCwd(self: *ContextCollector) ?[]const u8 {
        _ = self;
        // In full implementation, this would get the cwd from the terminal's Exec state
        // For now, we use the OS getcwd
        var buf: [4096]u8 = undefined;
        return std.os.getcwd(&buf) catch return null;
    }

    /// Detect the current shell type.
    fn detectShell(self: *ContextCollector) ?[]const u8 {
        // Check SHELL environment variable
        if (std.posix.getenv("SHELL")) |shell_path| {
            // Extract shell name from path
            if (std.mem.lastIndexOfScalar(u8, shell_path, '/')) |idx| {
                return self.allocator.dupe(u8, shell_path[idx + 1 ..]) catch return null;
            }
            return self.allocator.dupe(u8, shell_path) catch return null;
        }
        return null;
    }

    /// Capture git repository status.
    fn captureGitStatus(self: *ContextCollector, cwd: []const u8) !?GitStatus {
        // Run git status --porcelain=v2 --branch to get status
        const result = std.process.Child.run(.{
            .allocator = self.allocator,
            .argv = &.{ "git", "status", "--porcelain=v2", "--branch" },
            .cwd = cwd,
            .max_output_bytes = 4096,
        }) catch return null;
        defer {
            self.allocator.free(result.stdout);
            self.allocator.free(result.stderr);
        }

        if (result.term.Exited != 0) return null;

        return try GitStatus.parse(self.allocator, result.stdout);
    }

    /// Capture visible screen content.
    /// TODO: Integrate with Terminal.Screen to capture actual visible lines.
    pub fn captureScreenContent(self: *ContextCollector, screen: anytype) !?[]const u8 {
        _ = self;
        _ = screen;
        // Full implementation would:
        // 1. Get the visible rows from the Screen
        // 2. Extract text content from each cell
        // 3. Preserve line breaks and formatting
        // 4. Limit to config.screen_lines
        return null;
    }

    /// Capture recent command history.
    /// TODO: Integrate with shell history or terminal command history.
    pub fn captureCommandHistory(self: *ContextCollector) ![]const []const u8 {
        // Full implementation would:
        // 1. Read from shell history file (~/.zsh_history, ~/.bash_history, etc.)
        // 2. Or capture from terminal's internal command history
        // 3. Limit to config.history_lines
        return try self.allocator.alloc([]const u8, 0);
    }

    /// Sanitize context by redacting sensitive information.
    pub fn sanitize(self: *ContextCollector, context: *Context) void {
        // Redact patterns that match sensitive data
        if (context.cwd) |cwd| {
            if (self.containsSensitivePattern(cwd)) {
                context.cwd = null;
            }
        }

        if (context.screen_content) |screen| {
            // TODO: Implement actual pattern-based redaction
            _ = screen;
        }

        for (context.command_history) |cmd| {
            if (self.containsSensitivePattern(cmd)) {
                // Remove sensitive commands from history
                // TODO: Implement proper filtering
            }
        }
    }

    /// Check if a string contains sensitive patterns.
    fn containsSensitivePattern(self: *ContextCollector, str: []const u8) bool {
        // Check against configured exclude patterns
        for (self.config.exclude_patterns) |pattern| {
            if (std.mem.indexOf(u8, str, pattern) != null) {
                return true;
            }
        }

        // Default sensitive patterns
        const sensitive_patterns = [_][]const u8{
            ".env",
            "password",
            "secret",
            "api_key",
            "apikey",
            "token",
            "credential",
        };

        for (sensitive_patterns) |pattern| {
            if (std.mem.indexOf(u8, str, pattern) != null) {
                return true;
            }
        }

        return false;
    }

    pub fn deinit(self: *ContextCollector) void {
        _ = self;
    }
};

test "Context deinit" {
    const allocator = std.testing.allocator;
    var context = Context{
        .cwd = try allocator.dupe(u8, "/test/path"),
        .shell = try allocator.dupe(u8, "zsh"),
        .allocator = allocator,
    };
    context.command_history = try allocator.alloc([]const u8, 2);
    context.command_history[0] = try allocator.dupe(u8, "ls -la");
    context.command_history[1] = try allocator.dupe(u8, "cd ..");

    context.deinit();
}

test "GitStatus parse" {
    const allocator = std.testing.allocator;
    const git_output =
        \\# branch.oid abc123
        \\# branch.head main
        \\# branch.upstream origin/main
        \\# branch.ab +2 -1
    ;

    var status = try GitStatus.parse(allocator, git_output);
    defer status.deinit(allocator);

    try std.testing.expect(status.branch != null);
    try std.testing.expectEqualStrings("main", status.branch.?);
}

test "ContextCollector init and collect" {
    const allocator = std.testing.allocator;
    var collector = ContextCollector.init(allocator, .{});
    defer collector.deinit();

    var context = try collector.collect();
    defer context.deinit();

    try std.testing.expect(context.cwd != null);
    try std.testing.expect(context.shell != null);
}

test "ContextCollector with custom config" {
    const allocator = std.testing.allocator;
    const config = Config{
        .screen_lines = 50,
        .history_lines = 25,
        .include_git_status = false,
    };
    var collector = ContextCollector.init(allocator, config);
    defer collector.deinit();

    try std.testing.expectEqual(@as(u32, 50), collector.config.screen_lines);
    try std.testing.expectEqual(@as(u32, 25), collector.config.history_lines);
    try std.testing.expect(!collector.config.include_git_status);
}

test "containsSensitivePattern" {
    const allocator = std.testing.allocator;
    var collector = ContextCollector.init(allocator, .{});
    defer collector.deinit();

    try std.testing.expect(collector.containsSensitivePattern("/path/to/.env"));
    try std.testing.expect(collector.containsSensitivePattern("export API_KEY=secret"));
    try std.testing.expect(!collector.containsSensitivePattern("/path/to/project"));
}

test "Context.formatPrompt" {
    const allocator = std.testing.allocator;
    var context = Context{
        .cwd = try allocator.dupe(u8, "/test/path"),
        .shell = try allocator.dupe(u8, "zsh"),
        .allocator = allocator,
    };
    defer context.deinit();

    var buf = std.ArrayList(u8).init(allocator);
    defer buf.deinit();

    try context.formatPrompt(buf.writer());
    try std.testing.expect(buf.items.len > 0);
    try std.testing.expect(std.mem.indexOf(u8, buf.items, "Current directory:") != null);
    try std.testing.expect(std.mem.indexOf(u8, buf.items, "Shell:") != null);
}
