//! Block type for block-based rendering architecture
//!
//! A Block represents rendered content as lines with metadata.

const std = @import("std");
const unicode = @import("unicode.zig");

/// A Block represents rendered content as an array of lines
pub const Block = struct {
    lines: []Line,
    width: usize,
    height: usize,

    pub const Line = struct {
        content: []const u8,
        display_width: usize,
    };

    /// Create a Block from simple text lines
    pub fn init(allocator: std.mem.Allocator, text_lines: []const []const u8) !Block {
        var lines = try allocator.alloc(Line, text_lines.len);
        errdefer allocator.free(lines);

        var max_width: usize = 0;

        for (text_lines, 0..) |text, i| {
            const content = try allocator.dupe(u8, text);
            const display_width = unicode.displayWidth(content);

            lines[i] = .{
                .content = content,
                .display_width = display_width,
            };

            if (display_width > max_width) {
                max_width = display_width;
            }
        }

        return .{
            .lines = lines,
            .width = max_width,
            .height = text_lines.len,
        };
    }

    /// Free all memory owned by this Block
    pub fn deinit(self: Block, allocator: std.mem.Allocator) void {
        for (self.lines) |line| {
            allocator.free(line.content);
        }
        allocator.free(self.lines);
    }
};

test "Block init from text lines" {
    const allocator = std.testing.allocator;

    const text = [_][]const u8{ "Hello", "World!" };
    const block = try Block.init(allocator, &text);
    defer block.deinit(allocator);

    try std.testing.expectEqual(2, block.height);
    try std.testing.expectEqual(6, block.width); // "World!" is 6 chars
    try std.testing.expectEqualStrings("Hello", block.lines[0].content);
}

test "Block with CJK characters" {
    const allocator = std.testing.allocator;

    const text = [_][]const u8{ "ren", "練" };
    const block = try Block.init(allocator, &text);
    defer block.deinit(allocator);

    try std.testing.expectEqual(2, block.height);
    try std.testing.expectEqual(3, block.lines[0].display_width); // "ren" = 3
    try std.testing.expectEqual(2, block.lines[1].display_width); // "練" = 2 (CJK)
    try std.testing.expectEqual(3, block.width); // max width
}
