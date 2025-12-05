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

    try stdout.print("\n", .{});

    // Demo title using StarterHeader
    const title_config = ren.header.Config{ .width = null };
    const title = ren.header.StarterHeader.init("ren (練) Demo", "sophisticated", title_config);
    try title.render(allocator, stdout);
    try stdout.print("\n", .{});

    // Show detected width
    const term_width = ren.terminal.detectWidth();
    if (term_width) |w| {
        try stdout.print("  Terminal width: {} columns (auto-detected)\n", .{w});
    } else {
        try stdout.print("  Terminal width: 60 columns (fallback)\n", .{});
    }
    try stdout.print("\n\n", .{});

    // Demo: Default (ren) palette - all steps
    try stdout.print("  ren palette (default):\n\n", .{});
    const ren_config = ren.header.Config{};

    var demo = ren.header.ProgressHeader.init(0, 3, "Initializing", ren_config);
    try demo.render(allocator, stdout);
    try stdout.print("\n", .{});

    demo = ren.header.ProgressHeader.init(1, 3, "Building", ren_config);
    try demo.render(allocator, stdout);
    try stdout.print("\n", .{});

    demo = ren.header.ProgressHeader.init(2, 3, "Complete", ren_config);
    try demo.render(allocator, stdout);
    try stdout.print("\n", .{});

    // Show all-completed state (current_step >= total_steps)
    demo = ren.header.ProgressHeader.init(3, 3, "All Finished", ren_config);
    try demo.render(allocator, stdout);
    try stdout.print("\n\n", .{});

    // Demo: Warm palette
    try stdout.print("  warm palette:\n\n", .{});
    const warm_demo = ren.header.ProgressHeader.init(1, 3, "Warm Earth Tones", ren.header.Config{ .palette = ren.colour.warm });
    try warm_demo.render(allocator, stdout);
    try stdout.print("\n\n", .{});

    // Demo: Cool palette
    try stdout.print("  cool palette:\n\n", .{});
    const cool_demo = ren.header.ProgressHeader.init(1, 3, "Cool Blues", ren.header.Config{ .palette = ren.colour.cool });
    try cool_demo.render(allocator, stdout);
    try stdout.print("\n\n", .{});

    // Demo: Monochrome palette
    try stdout.print("  monochrome palette:\n\n", .{});
    const mono_demo = ren.header.ProgressHeader.init(1, 3, "Greyscale", ren.header.Config{ .palette = ren.colour.monochrome });
    try mono_demo.render(allocator, stdout);
    try stdout.print("\n\n", .{});

    // Demo: StarterHeader with various options
    try stdout.print("  Starter headers:\n\n", .{});

    const starter1 = ren.header.StarterHeader.init("Configuration", "ren", ren.header.Config{});
    try starter1.render(allocator, stdout);
    try stdout.print("\n", .{});

    const starter2 = ren.header.StarterHeader.init("Status", null, ren.header.Config{});
    try starter2.render(allocator, stdout);
    try stdout.print("\n\n", .{});

    try stdout.flush();
}
