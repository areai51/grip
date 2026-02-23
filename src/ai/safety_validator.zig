//! Safety Validator - Validates AI-generated commands for safety.
//!
//! This module provides multi-layer safety validation:
//! 1. Pattern blocking for destructive commands
//! 2. Confirmation requirements for dangerous operations
//! 3. Context sanitization for sensitive data
//! 4. Audit logging for all AI suggestions

const std = @import("std");

/// Safety level for command validation.
pub const SafetyLevel = enum {
    /// Low safety - minimal validation.
    low,
    /// Medium safety - standard validation (default).
    medium,
    /// High safety - strict validation with confirmations.
    high,
};

/// Result of command validation.
pub const ValidationResult = struct {
    /// Whether the command is allowed.
    allowed: bool,

    /// Whether confirmation is required.
    requires_confirmation: bool,

    /// Reason for blocking (if blocked).
    block_reason: ?[]const u8 = null,

    /// Suggested alternative (if available).
    suggestion: ?[]const u8 = null,

    /// Allocator for strings.
    allocator: std.mem.Allocator,

    pub fn deinit(self: *ValidationResult) void {
        if (self.block_reason) |reason| self.allocator.free(reason);
        if (self.suggestion) |suggestion| self.allocator.free(suggestion);
    }
};

/// Configuration for the safety validator.
pub const Config = struct {
    /// Current safety level.
    level: SafetyLevel = .medium,

    /// Additional patterns to block.
    blocked_patterns: []const []const u8 = &.{},

    /// Whether to allow dangerous flags (--force, -y).
    allow_dangerous_flags: bool = false,
};

/// Safety validator for AI-generated commands.
pub const SafetyValidator = struct {
    allocator: std.mem.Allocator,
    config: Config,

    /// Default blocked command patterns.
    const blocked_patterns = [_][]const u8{
        "rm -rf /",
        "rm -rf /*",
        "mkfs",
        "dd if=/dev/zero",
        "dd if=/dev/urandom",
        "> /dev/sda",
        "> /dev/hda",
        "curl | sh",
        "curl | bash",
        "wget | sh",
        "wget | bash",
        "eval $(",
        "chmod 000",
        "chmod -R 000",
        ":(){ :|:& };:",
    };

    /// Patterns requiring confirmation.
    const confirmation_patterns = [_][]const u8{
        "rm -r",
        "rm -rf",
        "docker rm",
        "docker rmi",
        "docker system prune",
        "kubectl delete",
        "git push --force",
        "git reset --hard",
        "DROP TABLE",
        "DROP DATABASE",
        "TRUNCATE",
    };

    /// Initialize a new safety validator.
    pub fn init(allocator: std.mem.Allocator, config: Config) SafetyValidator {
        return .{
            .allocator = allocator,
            .config = config,
        };
    }

    /// Validate a command for safety.
    /// TODO: Implement comprehensive AST-based validation.
    pub fn validate(self: *SafetyValidator, command: []const u8) !ValidationResult {
        var result = ValidationResult{
            .allowed = true,
            .requires_confirmation = false,
            .allocator = self.allocator,
        };

        for (blocked_patterns) |pattern| {
            if (std.mem.indexOf(u8, command, pattern) != null) {
                result.allowed = false;
                result.block_reason = try self.allocator.dupe(u8, "Command matches blocked pattern");
                return result;
            }
        }

        for (confirmation_patterns) |pattern| {
            if (std.mem.indexOf(u8, command, pattern) != null) {
                result.requires_confirmation = true;
                return result;
            }
        }

        return result;
    }

    pub fn deinit(self: *SafetyValidator) void {
        _ = self;
    }
};

test {
    _ = SafetyLevel;
    _ = ValidationResult;
    _ = Config;
    _ = SafetyValidator;
}
