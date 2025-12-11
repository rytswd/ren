//! Demo executable for ren (練)
//! Demonstrates the capabilities of the sophisticated terminal rendering library

const std = @import("std");
const ren = @import("ren");

// Import demo modules
const overview = @import("demos/overview.zig");
const headers = @import("demos/headers.zig");
const palettes = @import("demos/palettes.zig");
const animations = @import("demos/animations.zig");

const DemoType = enum {
    overview,
    headers,
    palettes,
    animations,

    fn fromString(s: []const u8) ?DemoType {
        if (std.mem.eql(u8, s, "overview")) return .overview;
        if (std.mem.eql(u8, s, "headers")) return .headers;
        if (std.mem.eql(u8, s, "palettes")) return .palettes;
        if (std.mem.eql(u8, s, "animations")) return .animations;
        return null;
    }
};

fn printUsage(stdout: *std.Io.Writer) !void {
    try stdout.writeAll(
        \\Usage: ren-demo [--demo <type>]
        \\
        \\Demos:
        \\  overview     Overview of ren library (default)
        \\  headers      Header types and styles
        \\  palettes     Colour palettes and gradients
        \\  animations   Animation effects
        \\
        \\Examples:
        \\  ren-demo
        \\  ren-demo --demo headers
        \\  ren-demo --demo animations
        \\
    );
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_file = std.fs.File.stdout();
    var stdout_writer: std.fs.File.Writer = stdout_file.writer(&stdout_buffer);
    const stdout: *std.Io.Writer = &stdout_writer.interface;
    const is_tty = stdout_file.isTty();

    // Parse command line arguments
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    _ = args.skip(); // Skip program name

    var demo_type: DemoType = .overview;
    var show_help = false;

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--demo")) {
            if (args.next()) |demo_name| {
                if (DemoType.fromString(demo_name)) |dt| {
                    demo_type = dt;
                } else {
                    try stdout.print("Unknown demo type: {s}\n", .{demo_name});
                    try printUsage(stdout);
                    return;
                }
            } else {
                try stdout.writeAll("--demo requires an argument\n");
                try printUsage(stdout);
                return;
            }
        } else if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            show_help = true;
        } else {
            try stdout.print("Unknown argument: {s}\n", .{arg});
            try printUsage(stdout);
            return;
        }
    }

    if (show_help) {
        try printUsage(stdout);
        return;
    }

    // Run the selected demo
    switch (demo_type) {
        .overview => try overview.run(allocator, stdout, is_tty),
        .headers => try headers.run(allocator, stdout),
        .palettes => try palettes.run(allocator, stdout),
        .animations => try animations.run(allocator, stdout, is_tty),
    }
}
