//! Header and sequence indicator utilities
//!
//! Provides sophisticated header styles with full configurability.

const std = @import("std");

/// Configuration for header appearance
pub const Config = struct {
    /// Characters used for progress dots
    completed_char: []const u8 = "●",
    current_char: []const u8 = "●",
    upcoming_char: []const u8 = "○",

    /// Character used at the start of header (can be empty)
    starter_char: []const u8 = "⚝",

    /// Separator character
    separator_char: []const u8 = "─",

    /// Default width (columns)
    default_width: usize = 60,

    /// Spacing around title
    title_padding: usize = 7,
};

/// Progress header for sequential operations
pub const ProgressHeader = struct {
    current_step: usize,
    total_steps: usize,
    title: []const u8,
    config: Config,

    pub fn init(current_step: usize, total_steps: usize, title: []const u8, config: Config) ProgressHeader {
        return .{
            .current_step = current_step,
            .total_steps = total_steps,
            .title = title,
            .config = config,
        };
    }
};

test "ProgressHeader init" {
    const config = Config{};
    const header = ProgressHeader.init(0, 3, "Test", config);
    try std.testing.expectEqual(0, header.current_step);
    try std.testing.expectEqual(3, header.total_steps);
    try std.testing.expectEqualStrings("Test", header.title);
}
