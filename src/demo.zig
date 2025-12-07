//! Demo executable for ren (練)
//! Demonstrates the capabilities of the sophisticated terminal rendering library

const std = @import("std");
const ren = @import("ren");
const Colour = ren.colour.Colour;
const header = ren.header;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer: std.fs.File.Writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout: *std.Io.Writer = &stdout_writer.interface;

    try stdout.print("\n", .{});

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
    try title.render(allocator, stdout);
    try stdout.print("\n", .{});

    // ///----------------------------------------
    // //   Show detected width
    // /------------------------------------------
    const term_width = ren.terminal.detectWidth();
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
    try demo.render(allocator, stdout);
    try stdout.print("\n", .{});

    demo = header.ProgressHeader.init(1, 3, "Building", ren_config);
    try demo.render(allocator, stdout);
    try stdout.print("\n", .{});

    demo = header.ProgressHeader.init(2, 3, "Complete", ren_config);
    try demo.render(allocator, stdout);
    try stdout.print("\n", .{});

    demo = header.ProgressHeader.init(3, 3, "All Finished", ren_config);
    try demo.render(allocator, stdout);
    try stdout.print("\n\n", .{});

    // ///----------------------------------------
    // //   Warm palette
    // /------------------------------------------
    try stdout.print("  warm palette:\n\n", .{});
    const warm_demo = header.ProgressHeader.init(1, 3, "Warm Earth Tones", header.Config{ .palette = ren.colour.warm });
    try warm_demo.render(allocator, stdout);
    try stdout.print("\n\n", .{});

    // ///----------------------------------------
    // //   Cool palette
    // /------------------------------------------
    try stdout.print("  cool palette:\n\n", .{});
    const cool_demo = header.ProgressHeader.init(1, 3, "Cool Blues", header.Config{ .palette = ren.colour.cool });
    try cool_demo.render(allocator, stdout);
    try stdout.print("\n\n", .{});

    // ///----------------------------------------
    // //   Monochrome palette
    // /------------------------------------------
    try stdout.print("  monochrome palette:\n\n", .{});
    const mono_demo = header.ProgressHeader.init(1, 3, "Greyscale", header.Config{ .palette = ren.colour.monochrome });
    try mono_demo.render(allocator, stdout);
    try stdout.print("\n\n", .{});

    // ///========================================
    // //   StarterHeader
    // /==========================================
    try stdout.print("  Starter headers:\n\n", .{});

    const starter1 = header.StarterHeader.init("Configuration", "ren", header.Config{});
    try starter1.render(allocator, stdout);
    try stdout.print("\n", .{});

    const starter2 = header.StarterHeader.init("Status", null, header.Config{});
    try starter2.render(allocator, stdout);
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

    try stdout.flush();
}
