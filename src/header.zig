//! Header and sequence indicator utilities
//!
//! Provides sophisticated header styles with full configurability.

const std = @import("std");
const colour = @import("colour.zig");
const terminal = @import("terminal.zig");

/// Configuration for header appearance
pub const Config = struct {
    /// Characters used for progress dots
    completed_char: []const u8 = "●",
    current_char: []const u8 = "◉",
    upcoming_char: []const u8 = "○",

    /// Character used at the start of header (can be empty)
    starter_char: []const u8 = "⚝",

    /// Separator character
    separator_char: []const u8 = "─",

    /// Width configuration
    /// If null, detect and use terminal width; otherwise uses this value
    width: ?usize = 60,

    /// Spacing around title
    title_padding: usize = 7,

    /// Enable colours (default: true for sophisticated output)
    use_colour: bool = true,

    /// Colour palette to use
    palette: colour.Palette = colour.ren,

    /// Helper: write text with colour based on Type
    pub fn write(
        self: Config,
        allocator: std.mem.Allocator,
        writer: *std.Io.Writer,
        colour_type: colour.Type,
        text: []const u8,
    ) !void {
        if (self.use_colour) {
            const col = self.palette.get(colour_type);
            try col.write(allocator, writer, text);
        } else {
            try writer.writeAll(text);
        }
    }

    /// Convenience methods for common colour types
    pub fn write_neutral(self: Config, allocator: std.mem.Allocator, writer: *std.Io.Writer, text: []const u8) !void {
        try self.write(allocator, writer, .neutral, text);
    }
    pub fn write_primary(self: Config, allocator: std.mem.Allocator, writer: *std.Io.Writer, text: []const u8) !void {
        try self.write(allocator, writer, .primary, text);
    }
    pub fn write_secondary(self: Config, allocator: std.mem.Allocator, writer: *std.Io.Writer, text: []const u8) !void {
        try self.write(allocator, writer, .secondary, text);
    }
    pub fn write_accent(self: Config, allocator: std.mem.Allocator, writer: *std.Io.Writer, text: []const u8) !void {
        try self.write(allocator, writer, .accent, text);
    }
    pub fn write_subtle(self: Config, allocator: std.mem.Allocator, writer: *std.Io.Writer, text: []const u8) !void {
        try self.write(allocator, writer, .subtle, text);
    }
};

/// Progress header for sequential operations
pub const ProgressHeader = struct {
    current_step: usize,
    total_steps: usize,
    title: []const u8,
    config: Config,

    pub fn init(current_step: usize, total_steps: usize, title: []const u8, config: Config) ProgressHeader {
        return .{
            .current_step = current_step,
            .total_steps = total_steps,
            .title = title,
            .config = config,
        };
    }

    /// Render the progress header with colours
    /// Format: ● ○ ○ ──────────────── [ 1 / 3 ]
    ///              Title
    ///         ────────────────────────────────
    pub fn render(self: ProgressHeader, allocator: std.mem.Allocator, writer: *std.Io.Writer) !void {
        // Get width: configured > detected > fallback to 60
        const width = self.config.width orelse terminal.detectWidth() orelse 60;

        // First line: render progress dots with colours
        for (0..self.total_steps) |i| {
            if (i < self.current_step) {
                try self.config.write_accent(allocator, writer, self.config.completed_char);
            } else if (i == self.current_step) {
                try self.config.write_primary(allocator, writer, self.config.current_char);
            } else {
                try self.config.write_subtle(allocator, writer, self.config.upcoming_char);
            }
            try writer.writeAll(" ");
        }

        // Render separator
        const dots_width = self.total_steps * 2;
        const counter = try std.fmt.allocPrint(allocator, "[ {} / {} ]", .{ self.current_step + 1, self.total_steps });
        defer allocator.free(counter);
        const separator_width = width - dots_width - counter.len - 1;

        const separator_line = try allocator.alloc(u8, separator_width * 3); // UTF-8 char can be 3 bytes
        defer allocator.free(separator_line);
        var pos: usize = 0;
        for (0..separator_width) |_| {
            for (self.config.separator_char) |byte| {
                separator_line[pos] = byte;
                pos += 1;
            }
        }
        try self.config.write_secondary(allocator, writer, separator_line[0..pos]);

        try writer.writeAll(" ");
        try self.config.write_secondary(allocator, writer, counter);
        try writer.writeAll("\n");

        // Second line: title (centred or left-aligned)
        const padding = if (self.title.len < width)
            (width - self.title.len) / 2
        else
            self.config.title_padding;

        for (0..padding) |_| {
            try writer.writeAll(" ");
        }
        try writer.writeAll(self.title);
        try writer.writeAll("\n");

        // Third line: full separator
        const bottom_sep = try allocator.alloc(u8, width * 3);
        defer allocator.free(bottom_sep);
        var bottom_pos: usize = 0;
        for (0..width) |_| {
            for (self.config.separator_char) |byte| {
                bottom_sep[bottom_pos] = byte;
                bottom_pos += 1;
            }
        }
        try self.config.write_secondary(allocator, writer, bottom_sep[0..bottom_pos]);
        try writer.writeAll("\n");

        try writer.flush();
    }
};

// Test helper
fn expectProgressRender(
    current_step: usize,
    total_steps: usize,
    title: []const u8,
    config: Config,
    expected: []const u8,
) !void {
    const allocator = std.testing.allocator;
    const header = ProgressHeader.init(current_step, total_steps, title, config);

    var output_buffer: [2048]u8 = undefined;
    var output_writer = std.Io.Writer.fixed(&output_buffer);

    try header.render(allocator, &output_writer);

    const output = output_writer.buffered();

    try std.testing.expectEqualStrings(expected, output);
}

test "ProgressHeader init" {
    const config = Config{};
    const header = ProgressHeader.init(0, 3, "Test", config);
    try std.testing.expectEqual(0, header.current_step);
    try std.testing.expectEqual(3, header.total_steps);
    try std.testing.expectEqualStrings("Test", header.title);
}

test "ProgressHeader render - first step" {
    try expectProgressRender(0, 3, "Initializing", Config{ .use_colour = false },
        \\◉ ○ ○ ──────────────────────────────────────────── [ 1 / 3 ]
        \\                        Initializing
        \\────────────────────────────────────────────────────────────
        \\
    );
}

test "ProgressHeader render - middle step" {
    try expectProgressRender(1, 3, "Building", Config{ .use_colour = false },
        \\● ◉ ○ ──────────────────────────────────────────── [ 2 / 3 ]
        \\                          Building
        \\────────────────────────────────────────────────────────────
        \\
    );
}

test "ProgressHeader render - last step" {
    try expectProgressRender(2, 3, "Complete", Config{ .use_colour = false },
        \\● ● ◉ ──────────────────────────────────────────── [ 3 / 3 ]
        \\                          Complete
        \\────────────────────────────────────────────────────────────
        \\
    );
}

test "ProgressHeader render - custom width" {
    try expectProgressRender(0, 2, "Test", Config{ .use_colour = false, .width = 40 },
        \\◉ ○ ────────────────────────── [ 1 / 2 ]
        \\                  Test
        \\────────────────────────────────────────
        \\
    );
}

test "ProgressHeader render - custom width odd" {
    try expectProgressRender(0, 2, "Odd", Config{ .use_colour = false, .width = 45 },
        \\◉ ○ ─────────────────────────────── [ 1 / 2 ]
        \\                     Odd
        \\─────────────────────────────────────────────
        \\
    );
}
