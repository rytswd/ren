//! Fade-in animation - progressive reveal with alpha blending

const std = @import("std");
const Block = @import("../block.zig").Block;
const colour = @import("../colour.zig");
const common = @import("common.zig");

/// Fade-in animation configuration
pub const Config = struct {
    steps: usize = 10,
    step_delay_ns: u64 = 30 * std.time.ns_per_ms,
};

/// Fade in a Block with increasing opacity
/// Smoothly reveals content by progressively increasing alpha channel
pub fn fadeIn(
    writer: *std.Io.Writer,
    allocator: std.mem.Allocator,
    block: Block,
    config: Config,
) !void {
    // Hide cursor during animation to prevent flashing
    try common.hideCursor(writer);
    try writer.flush();
    defer {
        common.showCursor(writer) catch {};
        writer.flush() catch {};
    }

    // 1. Reserve space with blank lines. This ensures that the same space would
    // be used for animation, and thus there is no line jumping while
    // re-rendering takes place.
    for (0..block.height) |_| {
        try writer.writeAll("\n");
    }
    try writer.flush();

    // 2. Rewind cursor to start of reserved space
    try common.cursorUp(writer, block.height);

    // Default colour for plain text content
    const default_text = colour.Colour{ .r = 200, .g = 200, .b = 200 };

    // 3. Reveal progressively with opacity
    for (0..config.steps) |step| {
        if (step > 0) {
            try common.cursorUp(writer, block.height);
        }

        // Calculate alpha (0-255)
        const alpha_f = @as(f32, @floatFromInt(step + 1)) / @as(f32, @floatFromInt(config.steps));
        const alpha: u8 = @intFromFloat(alpha_f * 255.0);

        // Render each line with modified alpha
        for (block.lines) |line| {
            const faded = try applyAlpha(allocator, line.content, alpha, default_text);
            defer allocator.free(faded);

            const trimmed = std.mem.trimRight(u8, faded, " ");
            try writer.writeAll(trimmed);
            try writer.writeAll("\n");
        }
        try writer.flush();

        if (step < config.steps - 1) {
            std.posix.nanosleep(0, config.step_delay_ns);
        }
    }
}

/// Apply alpha to all ANSI colour codes and plain text in a line
/// Parses existing colour codes and modifies alpha, wraps plain text with alpha-applied colour
fn applyAlpha(allocator: std.mem.Allocator, content: []const u8, alpha: u8, default_text: colour.Colour) ![]u8 {
    var result: std.ArrayList(u8) = .empty;
    errdefer result.deinit(allocator);

    var i: usize = 0;
    var in_colour = false;

    while (i < content.len) {
        // Look for ANSI escape sequence
        if (i + 1 < content.len and content[i] == '\x1b' and content[i + 1] == '[') {
            // Reset sequence
            if (i + 3 < content.len and content[i + 2] == '0' and content[i + 3] == 'm') {
                try result.appendSlice(allocator, "\x1b[0m");
                in_colour = false;
                i += 4;
                continue;
            }

            // Truecolor sequence
            if (std.mem.indexOf(u8, content[i..], "38;2;")) |_| {
                const seq_start = i;
                var end = i + 5;
                while (end < content.len and content[end] != 'm') : (end += 1) {}

                if (end < content.len) {
                    if (common.parseRgbFromAnsi(content[seq_start .. end + 1])) |original| {
                        const with_alpha = original.withAlpha(alpha);
                        const new_ansi = try with_alpha.toAnsi(allocator);
                        defer allocator.free(new_ansi);
                        try result.appendSlice(allocator, new_ansi);
                        in_colour = true;
                        i = end + 1;
                        continue;
                    }
                }
            }
        }

        // Plain text - wrap with default colour if not already coloured
        if (!in_colour and content[i] != ' ' and content[i] != '\n') {
            const text_with_alpha = default_text.withAlpha(alpha);
            const text_ansi = try text_with_alpha.toAnsi(allocator);
            defer allocator.free(text_ansi);
            try result.appendSlice(allocator, text_ansi);
            in_colour = true;
        }

        try result.append(allocator, content[i]);

        // Reset colour at newline
        if (content[i] == '\n' and in_colour) {
            try result.appendSlice(allocator, "\x1b[0m");
            in_colour = false;
        }

        i += 1;
    }

    return try result.toOwnedSlice(allocator);
}
