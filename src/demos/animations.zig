//! Animations demo - Showcases different animation effects

const std = @import("std");
const ren = @import("ren");
const Colour = ren.colour.Colour;

pub fn run(allocator: std.mem.Allocator, stdout: *std.Io.Writer, is_tty: bool) !void {
    try stdout.print("\n", .{});

    const term_width = ren.terminal.detectWidth();
    const width = term_width orelse 60;

    // ///========================================
    // //  Fade-in animation
    // /==========================================
    try stdout.print("  Fade-in animation - Smooth reveal:\n\n", .{});

    const fade_header = ren.header.StarterHeader.init("Animated Reveal", "fade", ren.header.Config{
        .separator_gradient = .{ .two_colour = .{
            .start = Colour.hex("#9DF29D"),
            .end = Colour.hex("#9D9DF2"),
        } },
    });
    const fade_block = try fade_header.toBlock(allocator, 60);
    defer fade_block.deinit(allocator);

    switch (is_tty) {
        false => try ren.render.instant(stdout, fade_block),
        true => try ren.render.fadeIn(allocator, stdout, fade_block, .{
            .steps = 10,
            .step_delay_ns = 100 * std.time.ns_per_ms,
        }),
    }
    try stdout.print("\n", .{});

    // ///========================================
    // //  Staggered fade-in animation
    // /==========================================
    try stdout.print("  Staggered fade-in - Wave effect:\n\n", .{});

    const staggered_lines = [_][]const u8{
        "  Each line fades in",
        "  with a time offset,",
        "  creating a smooth",
        "  cascading wave effect",
        "  from top to bottom.",
    };
    const staggered_block = try ren.block.Block.init(allocator, &staggered_lines);
    defer staggered_block.deinit(allocator);

    switch (is_tty) {
        false => try ren.render.instant(stdout, staggered_block),
        true => try ren.render.staggeredFadeIn(allocator, stdout, staggered_block, .{
            .steps = 10,
            .step_delay_ns = 50 * std.time.ns_per_ms,
            .line_offset_steps = 2,
        }),
    }
    try stdout.print("\n", .{});

    // ///----------------------------------------
    // //  Rainbow with fade-in
    // /------------------------------------------
    try stdout.print("  Rainbow gradient with fade-in:\n", .{});
    const rainbow_config = ren.header.Config{ .separator_gradient = .rainbow };
    const fade_rainbow_sep = try ren.header.separatorBlock(allocator, width, rainbow_config);
    defer fade_rainbow_sep.deinit(allocator);

    switch (is_tty) {
        false => try ren.render.instant(stdout, fade_rainbow_sep),
        true => try ren.render.fadeIn(allocator, stdout, fade_rainbow_sep, .{
            .steps = 10,
            .step_delay_ns = 100 * std.time.ns_per_ms,
        }),
    }
    try stdout.print("\n", .{});

    // ///----------------------------------------
    // //  Configuration options
    // /------------------------------------------
    try stdout.print("  Fast stagger (line_offset_steps = 1):\n", .{});
    const fast_lines = [_][]const u8{
        "  Quick succession",
        "  between each line",
        "  for rapid reveals",
    };
    const fast_block = try ren.block.Block.init(allocator, &fast_lines);
    defer fast_block.deinit(allocator);

    switch (is_tty) {
        false => try ren.render.instant(stdout, fast_block),
        true => try ren.render.staggeredFadeIn(allocator, stdout, fast_block, .{
            .steps = 8,
            .step_delay_ns = 40 * std.time.ns_per_ms,
            .line_offset_steps = 1,
        }),
    }
    try stdout.print("\n", .{});

    try stdout.print("  Slow stagger (line_offset_steps = 20):\n", .{});
    const slow_lines = [_][]const u8{
        "  Longer delay",
        "  between lines",
        "  for dramatic effect",
    };
    const slow_block = try ren.block.Block.init(allocator, &slow_lines);
    defer slow_block.deinit(allocator);

    switch (is_tty) {
        false => try ren.render.instant(stdout, slow_block),
        true => try ren.render.staggeredFadeIn(allocator, stdout, slow_block, .{
            .steps = 8,
            .step_delay_ns = 40 * std.time.ns_per_ms,
            .line_offset_steps = 20,
        }),
    }
    try stdout.print("\n\n", .{});

    try stdout.flush();
}
