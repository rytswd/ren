//! Common utilities for render effects

const std = @import("std");
const colour = @import("../colour.zig");

/// Move cursor up N lines (CPL - Cursor Previous Line)
pub fn cursorUp(writer: *std.Io.Writer, lines: usize) !void {
    if (lines == 0) return;
    try writer.print("\x1b[{}F", .{lines});
    try writer.flush();
}

/// Hide terminal cursor
pub fn hideCursor(writer: *std.Io.Writer) !void {
    try writer.writeAll("\x1b[?25l");
}

/// Show terminal cursor
pub fn showCursor(writer: *std.Io.Writer) !void {
    try writer.writeAll("\x1b[?25h");
}

/// Parse RGB from ANSI truecolor sequence like "\x1b[38;2;255;128;64m"
pub fn parseRgbFromAnsi(seq: []const u8) ?colour.Colour {
    const rgb_start = std.mem.indexOf(u8, seq, "38;2;") orelse return null;
    const rgb_part = seq[rgb_start + 5 ..];

    var parts = std.mem.splitScalar(u8, rgb_part, ';');
    const r_str = parts.next() orelse return null;
    const g_str = parts.next() orelse return null;
    const b_str_with_m = parts.rest();
    const b_str = std.mem.trimRight(u8, b_str_with_m, "m");

    const r = std.fmt.parseInt(u8, r_str, 10) catch return null;
    const g = std.fmt.parseInt(u8, g_str, 10) catch return null;
    const b = std.fmt.parseInt(u8, b_str, 10) catch return null;

    return .{ .r = r, .g = g, .b = b };
}
