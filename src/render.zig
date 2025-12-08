//! Render layer - outputs Blocks to terminal
//!
//! Handles instant rendering and animation effects.

const std = @import("std");
const Block = @import("block.zig").Block;

/// Render a Block instantly (trims trailing whitespace)
pub fn render(writer: *std.Io.Writer, block: Block) !void {
    for (block.lines) |line| {
        const trimmed = std.mem.trimRight(u8, line.content, " ");
        try writer.writeAll(trimmed);
        try writer.writeAll("\n");
    }
    try writer.flush();
}

test "render outputs block" {
    const allocator = std.testing.allocator;

    const text = [_][]const u8{ "Line 1", "Line 2" };
    const block = try Block.init(allocator, &text);
    defer block.deinit(allocator);

    var output_buffer: [256]u8 = undefined;
    var output_writer = std.Io.Writer.fixed(&output_buffer);

    try render(&output_writer, block);

    const output = output_writer.buffered();
    const expected =
        \\Line 1
        \\Line 2
        \\
    ;

    try std.testing.expectEqualStrings(expected, output);
}
