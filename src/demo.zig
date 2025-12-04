//! Demo executable for ren (練)
//! Demonstrates the capabilities of the sophisticated terminal rendering library

const std = @import("std");
const ren = @import("ren");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer: std.fs.File.Writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout: *std.Io.Writer = &stdout_writer.interface;

    try stdout.print("\n\n", .{});
    try stdout.print("  ren (練) - {any}\n", .{ren.version});
    try stdout.print("  Sophisticated terminal rendering for Zig\n", .{});
    try stdout.print("\n\n", .{});

    try stdout.flush();
}
