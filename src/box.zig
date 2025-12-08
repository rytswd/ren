//! Box drawing utilities
//!
//! Provides sophisticated box rendering for terminal output.

const std = @import("std");
const colour = @import("colour.zig");
const terminal = @import("terminal.zig");
const unicode = @import("unicode.zig");
const Block = @import("block.zig").Block;

/// Border character set for box drawing
pub const BorderChars = struct {
    top_left: []const u8,
    top_right: []const u8,
    bottom_left: []const u8,
    bottom_right: []const u8,
    horizontal: []const u8,
    vertical: []const u8,
    vertical_right: []const u8, // ├
    vertical_left: []const u8, // ┤
    horizontal_down: []const u8, // ┬
    horizontal_up: []const u8, // ┴
    cross: []const u8, // ┼
};

/// Rounded border characters (default)
pub const rounded = BorderChars{
    .top_left = "╭",
    .top_right = "╮",
    .bottom_left = "╰",
    .bottom_right = "╯",
    .horizontal = "─",
    .vertical = "│",
    .vertical_right = "├",
    .vertical_left = "┤",
    .horizontal_down = "┬",
    .horizontal_up = "┴",
    .cross = "┼",
};

test "rounded border chars" {
    try std.testing.expectEqualStrings("╭", rounded.top_left);
    try std.testing.expectEqualStrings("╰", rounded.bottom_left);
}

/// Full box (Layout layer) - wraps Blocks with borders
pub const Box = struct {
    margin: usize = 0,
    padding: usize = 2,
    border: BorderChars = rounded,

    /// Calculate inner width available for content
    pub fn innerWidth(self: Box, total_width: usize) usize {
        // total - (margin + border + padding) on each side
        const side_width = self.margin + 1 + self.padding; // border is 1 char display width
        if (total_width < side_width * 2) return 0;
        return total_width - (side_width * 2);
    }

    /// Wrap a Block with box borders
    pub fn wrap(self: Box, allocator: std.mem.Allocator, inner: Block, total_width: usize) !Block {
        const new_height = inner.height + 2; // +2 for top and bottom borders
        var lines = try allocator.alloc(Block.Line, new_height);
        errdefer allocator.free(lines);

        // Top border
        lines[0] = try self.buildTopBorder(allocator, total_width);

        // Wrap each inner line
        const inner_w = self.innerWidth(total_width);
        for (inner.lines, 0..) |inner_line, i| {
            lines[i + 1] = try self.wrapLine(allocator, inner_line, inner_w, total_width);
        }

        // Bottom border
        lines[new_height - 1] = try self.buildBottomBorder(allocator, total_width);

        return .{
            .lines = lines,
            .width = total_width,
            .height = new_height,
        };
    }

    fn buildTopBorder(self: Box, allocator: std.mem.Allocator, total_width: usize) !Block.Line {
        const margin_spaces = try allocator.alloc(u8, self.margin);
        defer allocator.free(margin_spaces);
        @memset(margin_spaces, ' ');

        // Horizontal fill: total_width - margins - 2 corners
        const horiz_count = total_width - self.margin * 2 - 2;

        // Account for UTF-8: each character can be multiple bytes
        const horizontal_line = try allocator.alloc(u8, horiz_count * 3);
        defer allocator.free(horizontal_line);
        var pos: usize = 0;
        for (0..horiz_count) |_| {
            for (self.border.horizontal) |byte| {
                horizontal_line[pos] = byte;
                pos += 1;
            }
        }

        const content = try std.fmt.allocPrint(allocator, "{s}{s}{s}{s}{s}", .{
            margin_spaces,
            self.border.top_left,
            horizontal_line[0..pos],
            self.border.top_right,
            margin_spaces,
        });

        return .{
            .content = content,
            .display_width = total_width,
        };
    }

    fn buildBottomBorder(self: Box, allocator: std.mem.Allocator, total_width: usize) !Block.Line {
        const margin_spaces = try allocator.alloc(u8, self.margin);
        defer allocator.free(margin_spaces);
        @memset(margin_spaces, ' ');

        // Horizontal fill: total_width - margins - 2 corners
        const horiz_count = total_width - self.margin * 2 - 2;

        // Account for UTF-8: each character can be multiple bytes
        const horizontal_line = try allocator.alloc(u8, horiz_count * 3);
        defer allocator.free(horizontal_line);
        var pos: usize = 0;
        for (0..horiz_count) |_| {
            for (self.border.horizontal) |byte| {
                horizontal_line[pos] = byte;
                pos += 1;
            }
        }

        const content = try std.fmt.allocPrint(allocator, "{s}{s}{s}{s}{s}", .{
            margin_spaces,
            self.border.bottom_left,
            horizontal_line[0..pos],
            self.border.bottom_right,
            margin_spaces,
        });

        return .{
            .content = content,
            .display_width = total_width,
        };
    }

    fn wrapLine(
        self: Box,
        allocator: std.mem.Allocator,
        inner_line: Block.Line,
        inner_width: usize,
        total_width: usize,
    ) !Block.Line {
        const margin_spaces = try allocator.alloc(u8, self.margin);
        defer allocator.free(margin_spaces);
        @memset(margin_spaces, ' ');

        const padding_spaces = try allocator.alloc(u8, self.padding);
        defer allocator.free(padding_spaces);
        @memset(padding_spaces, ' ');

        // Right padding to fill width
        const right_pad_size = inner_width - inner_line.display_width;
        const right_pad = try allocator.alloc(u8, right_pad_size);
        defer allocator.free(right_pad);
        @memset(right_pad, ' ');

        const content = try std.fmt.allocPrint(allocator, "{s}{s}{s}{s}{s}{s}{s}{s}", .{
            margin_spaces,
            self.border.vertical,
            padding_spaces,
            inner_line.content,
            right_pad,
            padding_spaces,
            self.border.vertical,
            margin_spaces,
        });

        return .{
            .content = content,
            .display_width = total_width,
        };
    }
};

test "Box innerWidth calculation" {
    const box = Box{ .margin = 2, .padding = 4 };
    const inner = box.innerWidth(80);
    // 80 - (2+1+4)*2 = 80 - 14 = 66
    try std.testing.expectEqual(66, inner);
}

test "Box wrap simple block" {
    const allocator = std.testing.allocator;

    const text = [_][]const u8{"Hello"};
    const inner = try Block.init(allocator, &text);
    defer inner.deinit(allocator);

    const box = Box{ .margin = 0, .padding = 2, .border = rounded };
    const wrapped = try box.wrap(allocator, inner, 15);
    defer wrapped.deinit(allocator);

    try std.testing.expectEqual(3, wrapped.height); // +2 for borders
    try std.testing.expectEqual(15, wrapped.width);

    try std.testing.expectEqualStrings(
        \\╭─────────────╮
    , wrapped.lines[0].content);

    try std.testing.expectEqualStrings(
        \\│  Hello      │
    , wrapped.lines[1].content);

    try std.testing.expectEqualStrings(
        \\╰─────────────╯
    , wrapped.lines[2].content);
}

test "Box wrap multi-line block" {
    const allocator = std.testing.allocator;

    const text = [_][]const u8{ "Line 1", "Line 2", "Line 3" };
    const inner = try Block.init(allocator, &text);
    defer inner.deinit(allocator);

    const box = Box{ .margin = 0, .padding = 1, .border = rounded };
    const wrapped = try box.wrap(allocator, inner, 14);
    defer wrapped.deinit(allocator);

    try std.testing.expectEqual(5, wrapped.height);
    try std.testing.expectEqual(14, wrapped.width);

    try std.testing.expectEqualStrings(
        \\╭────────────╮
    , wrapped.lines[0].content);
    try std.testing.expectEqualStrings(
        \\│ Line 1     │
    , wrapped.lines[1].content);
    try std.testing.expectEqualStrings(
        \\│ Line 2     │
    , wrapped.lines[2].content);
    try std.testing.expectEqualStrings(
        \\│ Line 3     │
    , wrapped.lines[3].content);
    try std.testing.expectEqualStrings(
        \\╰────────────╯
    , wrapped.lines[4].content);
}

test "Box wrap with margin" {
    const allocator = std.testing.allocator;

    const text = [_][]const u8{"Hi"};
    const inner = try Block.init(allocator, &text);
    defer inner.deinit(allocator);

    const box = Box{ .margin = 2, .padding = 1, .border = rounded };
    const wrapped = try box.wrap(allocator, inner, 12);
    defer wrapped.deinit(allocator);

    try std.testing.expectEqual(3, wrapped.height);
    try std.testing.expectEqual(12, wrapped.width);

    try std.testing.expectEqualStrings("  ╭──────╮  ", wrapped.lines[0].content);
    try std.testing.expectEqualStrings("  │ Hi   │  ", wrapped.lines[1].content);
    try std.testing.expectEqualStrings("  ╰──────╯  ", wrapped.lines[2].content);
}

test "Box wrap with CJK content" {
    const allocator = std.testing.allocator;

    const text = [_][]const u8{"練"};
    const inner = try Block.init(allocator, &text);
    defer inner.deinit(allocator);

    const box = Box{ .margin = 0, .padding = 2, .border = rounded };
    const wrapped = try box.wrap(allocator, inner, 10);
    defer wrapped.deinit(allocator);

    try std.testing.expectEqual(3, wrapped.height);
    try std.testing.expectEqual(10, wrapped.width);

    try std.testing.expectEqualStrings(
        \\╭────────╮
    , wrapped.lines[0].content);
    try std.testing.expectEqualStrings(
        \\│  練    │
    , wrapped.lines[1].content);
    try std.testing.expectEqualStrings(
        \\╰────────╯
    , wrapped.lines[2].content);
}

pub const Printer = union(enum) {};

/// Left-bordered box for vertical flow
pub const LeftBorderedBox = struct {
    title: ?[]const u8,
    border_chars: BorderChars,
    // margin corresponds to the space before the border char.
    margin: u8 = 0,
    // padding corresponds to the space after the border char.
    padding: u8 = 2,

    pub fn init(title: ?[]const u8, border_chars: BorderChars) LeftBorderedBox {
        return .{
            .title = title,
            .border_chars = border_chars,
        };
    }
};

// test "LeftBorderedBox init" {
//     const box_obj = LeftBorderedBox.init("Section", rounded);
//     try std.testing.expectEqualStrings("Section", box_obj.title.?);
// }
