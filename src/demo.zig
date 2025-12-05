//! Demo executable for ren (練)
//! Demonstrates the capabilities of the sophisticated terminal rendering library

const std = @import("std");
const ren = @import("ren");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer: std.fs.File.Writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout: *std.Io.Writer = &stdout_writer.interface;

    try stdout.print("\n\n", .{});
    try stdout.print("  ren (練) - Sophisticated terminal rendering for Zig\n", .{});
    try stdout.print("\n\n", .{});

    // Demo: Progress headers
    const config = ren.header.Config{};

    const step1 = ren.header.ProgressHeader.init(0, 3, "Initializing", config);
    try step1.render(allocator, stdout);
    try stdout.print("\n", .{});

    const step2 = ren.header.ProgressHeader.init(1, 3, "Building", config);
    try step2.render(allocator, stdout);
    try stdout.print("\n", .{});

    const step3 = ren.header.ProgressHeader.init(2, 3, "Complete", config);
    try step3.render(allocator, stdout);
    try stdout.print("\n\n", .{});

    try stdout.flush();
}
