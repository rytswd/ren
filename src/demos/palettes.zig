//! Colour palettes demo - Showcases different colour schemes

const std = @import("std");
const ren = @import("ren");
const Colour = ren.colour.Colour;

pub fn run(allocator: std.mem.Allocator, stdout: *std.Io.Writer) !void {
    try stdout.print("\n", .{});

    // ///========================================
    // //  Default palette (Ren)
    // /==========================================
    try stdout.print("  Ren palette (default):\n\n", .{});
    const ren_config = ren.header.Config{};

    var demo = ren.header.ProgressHeader.init(0, 3, "Initializing", ren_config);
    var block = try demo.toBlock(allocator, 60);
    try ren.render.render(stdout, block);
    block.deinit(allocator);
    try stdout.print("\n", .{});

    demo = ren.header.ProgressHeader.init(1, 3, "Building", ren_config);
    block = try demo.toBlock(allocator, 60);
    try ren.render.render(stdout, block);
    block.deinit(allocator);
    try stdout.print("\n", .{});

    demo = ren.header.ProgressHeader.init(2, 3, "Testing", ren_config);
    block = try demo.toBlock(allocator, 60);
    try ren.render.render(stdout, block);
    block.deinit(allocator);
    try stdout.print("\n", .{});

    demo = ren.header.ProgressHeader.init(3, 3, "Complete", ren_config);
    block = try demo.toBlock(allocator, 60);
    try ren.render.render(stdout, block);
    block.deinit(allocator);
    try stdout.print("\n\n", .{});

    // ///----------------------------------------
    // //  Warm palette
    // /------------------------------------------
    try stdout.print("  warm palette - Earth tones:\n\n", .{});
    const warm_demo = ren.header.ProgressHeader.init(1, 3, "Warm Earth Tones", ren.header.Config{ .palette = ren.colour.warm });
    block = try warm_demo.toBlock(allocator, 60);
    try ren.render.render(stdout, block);
    block.deinit(allocator);
    try stdout.print("\n\n", .{});

    // ///----------------------------------------
    // //  Cool palette
    // /------------------------------------------
    try stdout.print("  cool palette - Ocean blues:\n\n", .{});
    const cool_demo = ren.header.ProgressHeader.init(1, 3, "Cool Blues", ren.header.Config{ .palette = ren.colour.cool });
    block = try cool_demo.toBlock(allocator, 60);
    try ren.render.render(stdout, block);
    block.deinit(allocator);
    try stdout.print("\n\n", .{});

    // ///----------------------------------------
    // //  Monochrome palette
    // /------------------------------------------
    try stdout.print("  monochrome palette - Greyscale:\n\n", .{});
    const mono_demo = ren.header.ProgressHeader.init(1, 3, "Greyscale", ren.header.Config{ .palette = ren.colour.monochrome });
    block = try mono_demo.toBlock(allocator, 60);
    try ren.render.render(stdout, block);
    block.deinit(allocator);
    try stdout.print("\n\n", .{});

    // ///========================================
    // //  Custom gradients
    // /==========================================
    try stdout.print("  Custom gradients:\n\n", .{});

    const term_width = ren.terminal.detectWidth();
    const sep_width = term_width orelse 60;

    // Rainbow
    try stdout.print("  Rainbow:\n", .{});
    const rainbow_config = ren.header.Config{ .separator_gradient = .rainbow };
    const rainbow_sep = try ren.header.separatorBlock(allocator, sep_width, rainbow_config);
    defer rainbow_sep.deinit(allocator);
    try ren.render.instant(stdout, rainbow_sep);
    try stdout.print("\n", .{});

    // Mint to Sky
    try stdout.print("  Mint to Sky:\n", .{});
    const mint_sky_config = ren.header.Config{
        .separator_gradient = .{ .two_colour = .{
            .start = Colour.hex("#9DF29D"),
            .end = Colour.hex("#9D9DF2"),
        } },
    };
    const mint_sep = try ren.header.separatorBlock(allocator, sep_width, mint_sky_config);
    defer mint_sep.deinit(allocator);
    try ren.render.instant(stdout, mint_sep);
    try stdout.print("\n", .{});

    // Three colour gradient
    try stdout.print("  Peach → Mint → Lavender:\n", .{});
    const three_grad_config = ren.header.Config{
        .separator_gradient = .{ .three_colour = .{
            .start = Colour.hex("#FFDCD2"),
            .mid = Colour.hex("#9DF29D"),
            .end = Colour.hex("#E6DCFA"),
        } },
    };
    const three_sep = try ren.header.separatorBlock(allocator, sep_width, three_grad_config);
    defer three_sep.deinit(allocator);
    try ren.render.instant(stdout, three_sep);
    try stdout.print("\n\n", .{});

    try stdout.flush();
}
