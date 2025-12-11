//! Overview demo - Shows ren library at a glance with header, docs, and footer

const std = @import("std");
const ren = @import("ren");
const Colour = ren.colour.Colour;

pub fn run(allocator: std.mem.Allocator, stdout: *std.Io.Writer) !void {
    try stdout.print("\n", .{});

    const term_width = ren.terminal.detectWidth();
    const width = term_width orelse 60;

    // ///========================================
    // //  Title Header with gradient
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
        .steps = 20,
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
    const doc_block = try ren.block.Block.init(allocator, &doc_lines);
    defer doc_block.deinit(allocator);
    try ren.render.staggeredFadeIn(stdout, allocator, doc_block, .{
        .steps = 8,
        .step_delay_ns = 40 * std.time.ns_per_ms,
        .line_offset_steps = 1,
    });
    try stdout.print("\n", .{});

    // ///----------------------------------------
    // //  Quick examples
    // /------------------------------------------
    try stdout.print("  Quick examples:\n\n", .{});

    // Progress header
    const progress = ren.header.ProgressHeader.init(2, 3, "Building", ren.header.Config{});
    var progress_block = try progress.toBlock(allocator, 60);
    defer progress_block.deinit(allocator);
    try ren.render.instant(stdout, progress_block);
    try stdout.print("\n", .{});

    // Gradient separator
    try stdout.print("  Rainbow gradient:\n", .{});
    const rainbow_config = ren.header.Config{ .separator_gradient = .rainbow };
    const rainbow_sep = try ren.header.separatorBlock(allocator, width, rainbow_config);
    defer rainbow_sep.deinit(allocator);
    try ren.render.instant(stdout, rainbow_sep);
    try stdout.print("\n\n", .{});

    // ///========================================
    // //  Bottom bar
    // /==========================================
    const footer_config = ren.header.Config{
        .separator_gradient = .{ .two_colour = .{
            .start = Colour.hex("#9DF29D"),
            .end = Colour.hex("#9D9DF2"),
        } },
    };
    const footer_sep = try ren.header.separatorBlock(allocator, width, footer_config);
    defer footer_sep.deinit(allocator);
    try ren.render.instant(stdout, footer_sep);

    const footer_lines = [_][]const u8{
        "  Developed by @rytswd",
        "  ",
        "  Try other demos: --demo headers | palettes | animations",
    };
    const footer_block = try ren.block.Block.init(allocator, &footer_lines);
    defer footer_block.deinit(allocator);
    try ren.render.instant(stdout, footer_block);
    try stdout.print("\n", .{});

    try stdout.flush();
}
