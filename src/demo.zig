//! Demo executable for ren (練)
//! Demonstrates the capabilities of the sophisticated terminal rendering library

const std = @import("std");
const ren = @import("ren");
const Colour = ren.colour.Colour;
const header = ren.header;
const box = ren.box;
const render = ren.render;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer: std.fs.File.Writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout: *std.Io.Writer = &stdout_writer.interface;

    try stdout.print("\n", .{});

    // Detect terminal width early
    const term_width = ren.terminal.detectWidth();

    // ///----------------------------------------
    // //  Title StarterHeader with gradient
    // /------------------------------------------
    const title_config = header.Config{
        .width = null,
        .separator_gradient = .{ .two_colour = .{
            .start = Colour.hex("#FF8C00"),
            .end = Colour.hex("#70B0F0"),
        } },
    };
    const title = header.StarterHeader.init("ren (練) Demo", "sophisticated", title_config);
    const title_width = term_width orelse 60;
    var title_block = try title.toBlock(allocator, title_width);
    try render.render(stdout, title_block);
    title_block.deinit(allocator);
    try stdout.print("\n", .{});

    // ///----------------------------------------
    // //   Show detected width
    // /------------------------------------------
    if (term_width) |w| {
        try stdout.print("  Terminal width: {} columns (auto-detected)\n", .{w});
    } else {
        try stdout.print("  Terminal width: 60 columns (fallback)\n", .{});
    }
    try stdout.print("\n\n", .{});

    // ///========================================
    // //   ProgressHeader
    // /==========================================
    try stdout.print("  ren palette (default):\n\n", .{});
    const ren_config = header.Config{};

    var demo = header.ProgressHeader.init(0, 3, "Initializing", ren_config);
    var block = try demo.toBlock(allocator, 60);
    try render.render(stdout, block);
    block.deinit(allocator);
    try stdout.print("\n", .{});

    demo = header.ProgressHeader.init(1, 3, "Building", ren_config);
    block = try demo.toBlock(allocator, 60);
    try render.render(stdout, block);
    block.deinit(allocator);
    try stdout.print("\n", .{});

    demo = header.ProgressHeader.init(2, 3, "Complete", ren_config);
    block = try demo.toBlock(allocator, 60);
    try render.render(stdout, block);
    block.deinit(allocator);
    try stdout.print("\n", .{});

    demo = header.ProgressHeader.init(3, 3, "All Finished", ren_config);
    block = try demo.toBlock(allocator, 60);
    try render.render(stdout, block);
    block.deinit(allocator);
    try stdout.print("\n\n", .{});

    // ///----------------------------------------
    // //   Warm palette
    // /------------------------------------------
    try stdout.print("  warm palette:\n\n", .{});
    const warm_demo = header.ProgressHeader.init(1, 3, "Warm Earth Tones", header.Config{ .palette = ren.colour.warm });
    block = try warm_demo.toBlock(allocator, 60);
    try render.render(stdout, block);
    block.deinit(allocator);
    try stdout.print("\n\n", .{});

    // ///----------------------------------------
    // //   Cool palette
    // /------------------------------------------
    try stdout.print("  cool palette:\n\n", .{});
    const cool_demo = header.ProgressHeader.init(1, 3, "Cool Blues", header.Config{ .palette = ren.colour.cool });
    block = try cool_demo.toBlock(allocator, 60);
    try render.render(stdout, block);
    block.deinit(allocator);
    try stdout.print("\n\n", .{});

    // ///----------------------------------------
    // //   Monochrome palette
    // /------------------------------------------
    try stdout.print("  monochrome palette:\n\n", .{});
    const mono_demo = header.ProgressHeader.init(1, 3, "Greyscale", header.Config{ .palette = ren.colour.monochrome });
    block = try mono_demo.toBlock(allocator, 60);
    try render.render(stdout, block);
    block.deinit(allocator);
    try stdout.print("\n\n", .{});

    // ///========================================
    // //   StarterHeader
    // /==========================================
    try stdout.print("  Starter headers:\n\n", .{});

    const starter1 = header.StarterHeader.init("Configuration", "ren", header.Config{});
    block = try starter1.toBlock(allocator, 60);
    try render.render(stdout, block);
    block.deinit(allocator);
    try stdout.print("\n", .{});

    const starter2 = header.StarterHeader.init("Status", null, header.Config{});
    block = try starter2.toBlock(allocator, 60);
    try render.render(stdout, block);
    block.deinit(allocator);
    try stdout.print("\n\n", .{});

    // ///========================================
    // //   Gradients
    // /==========================================
    try stdout.print("  Gradient examples:\n\n", .{});

    const sep_width = term_width orelse 60;

    // ///----------------------------------------
    // //   Rainbow
    // /------------------------------------------
    try stdout.print("  Rainbow:\n", .{});
    const rainbow_config = header.Config{ .separator_gradient = .rainbow };
    try rainbow_config.renderSeparator(allocator, stdout, sep_width, 0, sep_width);
    try stdout.print("\n\n", .{});

    // ///----------------------------------------
    // //   2 colour gradient
    // /------------------------------------------
    try stdout.print("  Mint to Sky:\n", .{});
    const mint_sky = header.Config{
        .separator_gradient = .{ .two_colour = .{
            .start = Colour.hex("#9DF29D"),
            .end = Colour.hex("#9D9DF2"),
        } },
    };
    try mint_sky.renderSeparator(allocator, stdout, sep_width, 0, sep_width);
    try stdout.print("\n\n", .{});

    // ///----------------------------------------
    // //   3 colour gradient
    // /------------------------------------------
    try stdout.print("  Peach → Mint → Lavender:\n", .{});
    const three_grad = header.Config{
        .separator_gradient = .{ .three_colour = .{
            .start = Colour.hex("#FFDCD2"),
            .mid = Colour.hex("#9DF29D"),
            .end = Colour.hex("#E6DCFA"),
        } },
    };
    try three_grad.renderSeparator(allocator, stdout, sep_width, 0, sep_width);
    try stdout.print("\n\n", .{});

    // ///========================================
    // //   Block-based architecture demo
    // /==========================================
    try stdout.print("  Block-based rendering:\n\n", .{});

    // Layout configuration
    const box_layout = box.Box{ .margin = 2, .padding = 3 };
    const total_width = term_width orelse 60;

    // Content layer: create header block at correct inner width
    const block_header = header.ProgressHeader.init(1, 3, "Block Architecture", header.Config{});
    const header_block = try block_header.toBlock(allocator, box_layout.innerWidth(total_width));
    defer header_block.deinit(allocator);

    // Layout layer: wrap with box
    const boxed_block = try box_layout.wrap(allocator, header_block, total_width);
    defer boxed_block.deinit(allocator);

    // Render layer: output to terminal
    try render.render(stdout, boxed_block);
    try stdout.print("\n", .{});

    try stdout.flush();
}
