//! Simple demo - Shows ren library at a glance with header, docs, and footer

const std = @import("std");
const ren = @import("ren");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_file = std.fs.File.stdout();
    var stdout_writer: std.fs.File.Writer = stdout_file.writer(&stdout_buffer);
    const stdout: *std.Io.Writer = &stdout_writer.interface;
    const is_tty = stdout_file.isTty();

    if (is_tty) {
        try ren.render.hideCursor(stdout);
    }
    defer {
        if (is_tty) {
            ren.render.showCursor(stdout) catch {};
        }
    }

    const term_width = ren.terminal.detectWidth();
    const width = term_width orelse 60;

    // Create and centre a header
    const header = ren.header.StarterHeader.init("Welcome", "ren", .{
        .separator_gradient = .rainbow,
    });
    const block = try header.toBlockCentred(allocator, width);
    defer block.deinit(allocator);

    // Render with animation
    if (is_tty) {
        try ren.render.staggeredFadeIn(allocator, stdout, block, .{});
    } else {
        try ren.render.instant(stdout, block);
    }

    try stdout.flush();
}
