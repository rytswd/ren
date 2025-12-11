//! Header types demo - Showcases different header styles

const std = @import("std");
const ren = @import("ren");
const Colour = ren.colour.Colour;

pub fn run(allocator: std.mem.Allocator, stdout: *std.Io.Writer) !void {
    try stdout.print("\n", .{});

    // ///========================================
    // //  ProgressHeader
    // /==========================================
    try stdout.print("  ProgressHeader - Track multi-step processes:\n\n", .{});

    var demo = ren.header.ProgressHeader.init(0, 3, "Initializing", ren.header.Config{});
    var block = try demo.toBlock(allocator, 60);
    try ren.render.render(stdout, block);
    block.deinit(allocator);
    try stdout.print("\n", .{});

    demo = ren.header.ProgressHeader.init(1, 3, "Building", ren.header.Config{});
    block = try demo.toBlock(allocator, 60);
    try ren.render.render(stdout, block);
    block.deinit(allocator);
    try stdout.print("\n", .{});

    demo = ren.header.ProgressHeader.init(2, 3, "Testing", ren.header.Config{});
    block = try demo.toBlock(allocator, 60);
    try ren.render.render(stdout, block);
    block.deinit(allocator);
    try stdout.print("\n", .{});

    demo = ren.header.ProgressHeader.init(3, 3, "Complete", ren.header.Config{});
    block = try demo.toBlock(allocator, 60);
    try ren.render.render(stdout, block);
    block.deinit(allocator);
    try stdout.print("\n\n", .{});

    // ///========================================
    // //  StarterHeader
    // /==========================================
    try stdout.print("  StarterHeader - Section headers with optional tags:\n\n", .{});

    const starter1 = ren.header.StarterHeader.init("Configuration", "ren", ren.header.Config{});
    block = try starter1.toBlock(allocator, 60);
    try ren.render.render(stdout, block);
    block.deinit(allocator);
    try stdout.print("\n", .{});

    const starter2 = ren.header.StarterHeader.init("Status", null, ren.header.Config{});
    block = try starter2.toBlock(allocator, 60);
    try ren.render.render(stdout, block);
    block.deinit(allocator);
    try stdout.print("\n", .{});

    const starter3 = ren.header.StarterHeader.init("Build Results", "success", ren.header.Config{
        .separator_gradient = .{ .two_colour = .{
            .start = Colour.hex("#9DF29D"),
            .end = Colour.hex("#9D9DF2"),
        } },
    });
    block = try starter3.toBlock(allocator, 60);
    try ren.render.render(stdout, block);
    block.deinit(allocator);
    try stdout.print("\n\n", .{});

    // ///========================================
    // //  Separator blocks
    // /==========================================
    try stdout.print("  Separator blocks - Visual dividers:\n\n", .{});

    const term_width = ren.terminal.detectWidth();
    const sep_width = term_width orelse 60;

    const sep1 = try ren.header.separatorBlock(allocator, sep_width, ren.header.Config{});
    defer sep1.deinit(allocator);
    try ren.render.instant(stdout, sep1);
    try stdout.print("\n", .{});

    const sep2 = try ren.header.separatorBlock(allocator, sep_width, ren.header.Config{
        .separator_gradient = .{ .two_colour = .{
            .start = Colour.hex("#FF8C00"),
            .end = Colour.hex("#70B0F0"),
        } },
    });
    defer sep2.deinit(allocator);
    try ren.render.instant(stdout, sep2);
    try stdout.print("\n", .{});

    const sep3 = try ren.header.separatorBlock(allocator, sep_width, ren.header.Config{
        .separator_gradient = .rainbow,
    });
    defer sep3.deinit(allocator);
    try ren.render.instant(stdout, sep3);
    try stdout.print("\n\n", .{});

    try stdout.flush();
}
