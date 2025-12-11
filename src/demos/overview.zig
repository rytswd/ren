//! Overview demo - Shows ren library at a glance with header, docs, and footer

const std = @import("std");
const ren = @import("ren");
const Colour = ren.colour.Colour;

pub fn run(allocator: std.mem.Allocator, stdout: *std.Io.Writer) !void {
    try stdout.print("\n", .{});

    const term_width = ren.terminal.detectWidth();
    const width = term_width orelse 60;

    // ///========================================
    // //  Title Header with gradient (full width)
    // /==========================================
    const title_config = ren.header.Config{
        .width = null,
        .separator_gradient = .{ .two_colour = .{
            .start = Colour.hex("#FF8C00"),
            .end = Colour.hex("#70B0F0"),
        } },
    };
    const title = ren.header.StarterHeader.init("ren (練)", "v0.1.0", title_config);
    var title_block = try title.toBlock(allocator, width);
    defer title_block.deinit(allocator);
    try ren.render.fadeIn(stdout, allocator, title_block, .{
        .steps = 12,
        .step_delay_ns = 100 * std.time.ns_per_ms,
    });
    try stdout.print("\n", .{});

    // ///----------------------------------------
    // //  Documentation with staggered fade-in
    // /------------------------------------------
    const doc_lines = [_][]const u8{
        "  A lightweight Zig library for sophisticated terminal output rendering.",
        "  ",
        "  ren embodies the principle of 洗練 (senren) - sophistication through refinement.",
        "  Simple APIs, zero dependencies, beautiful output.",
        "  ",
        "  Features:",
        "    • Block-based rendering architecture",
        "    • Colour gradients and palettes",
        "    • Progressive headers and animations",
        "    • Fade-in and staggered effects",
        "    • Box drawing and layouts",
    };
    const doc_block = try ren.block.Block.initCentred(allocator, &doc_lines, width);
    defer doc_block.deinit(allocator);
    try ren.render.staggeredFadeIn(stdout, allocator, doc_block, .{
        .steps = 12,
        .step_delay_ns = 80 * std.time.ns_per_ms,
        .line_offset_steps = 1,
    });
    try stdout.print("\n", .{});

    // // ///----------------------------------------
    // // //  Quick examples
    // // /------------------------------------------
    // try stdout.print("  Quick examples:\n\n", .{});

    // // Progress header
    // const progress = ren.header.ProgressHeader.init(2, 3, "Building", ren.header.Config{});
    // var progress_block = try progress.toBlock(allocator, 60);
    // defer progress_block.deinit(allocator);
    // try ren.render.instant(stdout, progress_block);
    // try stdout.print("\n", .{});

    // // Gradient separator
    // try stdout.print("  Rainbow gradient:\n", .{});
    // const rainbow_config = ren.header.Config{ .separator_gradient = .rainbow };
    // const rainbow_sep = try ren.header.separatorBlock(allocator, width, rainbow_config);
    // defer rainbow_sep.deinit(allocator);
    // try ren.render.instant(stdout, rainbow_sep);
    // try stdout.print("\n\n", .{});

    // ///========================================
    // //  Bottom bar (shorter separator, centred)
    // /==========================================
    const footer_sep_width = @min(80, width * 3 / 4);

    // Build separator as a single line, then centre it
    const footer_config = ren.header.Config{
        .separator_gradient = .{ .two_colour = .{
            .start = Colour.hex("#9DF29D"),
            .end = Colour.hex("#9D9DF2"),
        } },
    };
    const footer_sep_block = try ren.header.separatorBlock(allocator, footer_sep_width, footer_config);
    defer footer_sep_block.deinit(allocator);

    // Convert to text lines to centre
    const sep_line = footer_sep_block.lines[0].content;
    const sep_lines = [_][]const u8{sep_line};
    const footer_sep = try ren.block.Block.initCentred(allocator, &sep_lines, width);
    defer footer_sep.deinit(allocator);

    try ren.render.fadeIn(stdout, allocator, footer_sep, .{
        .steps = 10,
        .step_delay_ns = 100 * std.time.ns_per_ms,
    });

    // Build footer with coloured command text
    const cmd_colour = Colour.hex("#70B0F0"); // Blue for commands
    const cmd_ansi = try cmd_colour.toAnsi(allocator);
    defer allocator.free(cmd_ansi);

    const footer_line3 = try std.fmt.allocPrint(
        allocator,
        "  Try other demos: {s}--demo headers{s} | {s}palettes{s} | {s}animations{s}",
        .{ cmd_ansi, ren.colour.reset, cmd_ansi, ren.colour.reset, cmd_ansi, ren.colour.reset },
    );
    defer allocator.free(footer_line3);

    const footer_lines = [_][]const u8{
        "  ",
        "  Developed by @rytswd",
        "  ",
        footer_line3,
    };
    const footer_block = try ren.block.Block.initCentred(allocator, &footer_lines, width);
    defer footer_block.deinit(allocator);
    try ren.render.staggeredFadeIn(stdout, allocator, footer_block, .{
        .steps = 12,
        .step_delay_ns = 80 * std.time.ns_per_ms,
        .line_offset_steps = 1,
    });
    try stdout.print("\n", .{});

    try stdout.flush();
}
