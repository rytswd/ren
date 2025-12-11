//! Block type for block-based rendering architecture
//!
//! A Block represents rendered content as lines with metadata.

const std = @import("std");
const unicode = @import("unicode.zig");

/// Minimum width specification for block alignment
pub const MinWidth = union(enum) {
    /// Auto-calculate from content (natural width)
    auto,
    /// Predefined fixed width for uniform alignment across multiple blocks
    fixed: usize,
};

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

    /// Create a Block from text lines, centred within target width
    /// Single-phase allocation - creates and positions in one step
    pub fn initCentred(allocator: std.mem.Allocator, text_lines: []const []const u8, min_width: MinWidth, target_width: usize) !Block {
        // Determine content width based on MinWidth
        const content_width = switch (min_width) {
            .auto => blk: {
                var max_width: usize = 0;
                for (text_lines) |text| {
                    const display_width = unicode.displayWidth(text);
                    if (display_width > max_width) {
                        max_width = display_width;
                    }
                }
                break :blk max_width;
            },
            .fixed => |width| width,
        };

        // If target width is not greater than content, just use regular init
        if (target_width <= content_width) {
            return init(allocator, text_lines);
        }

        // Calculate centring padding
        const available_space = target_width - content_width;
        const left_pad = available_space / 2;

        // Create lines with padding
        var lines = try allocator.alloc(Line, text_lines.len);
        errdefer allocator.free(lines);

        // Create padding string once
        const padding = try allocator.alloc(u8, left_pad);
        defer allocator.free(padding);
        @memset(padding, ' ');

        for (text_lines, 0..) |text, i| {
            const display_width = unicode.displayWidth(text);

            // Build padded content
            const content = try std.fmt.allocPrint(allocator, "{s}{s}", .{
                padding,
                text,
            });

            lines[i] = .{
                .content = content,
                .display_width = left_pad + display_width,
            };
        }

        return .{
            .lines = lines,
            .width = target_width,
            .height = text_lines.len,
        };
    }

    // US spelling alias
    pub const initCentered = initCentred;

    /// Free all memory owned by this Block
    pub fn deinit(self: Block, allocator: std.mem.Allocator) void {
        for (self.lines) |line| {
            allocator.free(line.content);
        }
        allocator.free(self.lines);
    }

    /// For testing:
    /// Get all lines as a single string with newlines
    /// No trailing newline after last line
    /// Caller owns returned memory
    pub fn toString(self: Block, allocator: std.mem.Allocator) ![]u8 {
        if (self.lines.len == 0) return try allocator.alloc(u8, 0);

        // Calculate total size needed
        var total_size: usize = 0;
        for (self.lines, 0..) |line, i| {
            total_size += line.content.len;
            if (i < self.lines.len - 1) total_size += 1; // +1 for newline between lines
        }

        var result = try allocator.alloc(u8, total_size);
        var pos: usize = 0;

        for (self.lines, 0..) |line, i| {
            @memcpy(result[pos .. pos + line.content.len], line.content);
            pos += line.content.len;
            if (i < self.lines.len - 1) {
                result[pos] = '\n';
                pos += 1;
            }
        }

        return result;
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

test "Block toString for testing" {
    const allocator = std.testing.allocator;

    const text = [_][]const u8{ "Line 1", "Line 2", "Line 3" };
    const block = try Block.init(allocator, &text);
    defer block.deinit(allocator);

    const all_lines = try block.toString(allocator);
    defer allocator.free(all_lines);

    const expected =
        \\Line 1
        \\Line 2
        \\Line 3
    ;

    try std.testing.expectEqualStrings(expected, all_lines);
}

test "Block initCentred with auto" {
    const allocator = std.testing.allocator;

    const text = [_][]const u8{"Hello"};
    const block = try Block.initCentred(allocator, &text, .auto, 15);
    defer block.deinit(allocator);

    // "Hello" is 5 chars, centred in 15 = 5 left spaces
    try std.testing.expectEqual(@as(usize, 15), block.width);
    try std.testing.expectEqual(@as(usize, 1), block.height);
    try std.testing.expectEqualStrings("     Hello", block.lines[0].content);
    try std.testing.expectEqual(@as(usize, 10), block.lines[0].display_width);
}

test "Block initCentred with fixed width" {
    const allocator = std.testing.allocator;

    const text = [_][]const u8{"Hi"};
    const block = try Block.initCentred(allocator, &text, .{ .fixed = 10 }, 20);
    defer block.deinit(allocator);

    // "Hi" is 2 chars, but centred as if it's 10 chars wide in 20 = 5 left spaces
    try std.testing.expectEqual(@as(usize, 20), block.width);
    try std.testing.expectEqualStrings("     Hi", block.lines[0].content);
}

test "Block initCentred with overflow" {
    const allocator = std.testing.allocator;

    const text = [_][]const u8{"Very long text"};
    const block = try Block.initCentred(allocator, &text, .auto, 5);
    defer block.deinit(allocator);

    // Content wider than target - use content width (no centring)
    try std.testing.expectEqual(@as(usize, 14), block.width);
    try std.testing.expectEqualStrings("Very long text", block.lines[0].content);
}
