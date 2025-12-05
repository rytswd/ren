//! Header and sequence indicator utilities
//!
//! Provides sophisticated header styles with full configurability.

const std = @import("std");
const colour = @import("colour.zig");

/// Configuration for header appearance
pub const Config = struct {
    /// Characters used for progress dots
    completed_char: []const u8 = "●",
    current_char: []const u8 = "●",
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

    /// Colours - sophisticated defaults from Palette
    completed_colour: colour.Colour = colour.Palette.refined_green,
    current_colour: colour.Colour = colour.Palette.warm_amber,
    upcoming_colour: colour.Colour = colour.Palette.subtle_grey,
    separator_colour: colour.Colour = colour.Palette.dim_grey,
    counter_colour: colour.Colour = colour.Palette.dim_grey,
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

    /// Render the progress header
    /// Format: ● ○ ○ ──────────────── [ 1 / 3 ]
    ///              Title
    ///         ────────────────────────────────
    pub fn render(self: ProgressHeader, allocator: std.mem.Allocator, writer: *std.Io.Writer) !void {
        // Get width (use configured width or fallback to 60)
        // TODO: Detect terminal width when config.width is null
        const width = self.config.width orelse 60;

        // First line: render progress dots
        for (0..self.total_steps) |i| {
            if (i < self.current_step) {
                try writer.writeAll(self.config.completed_char);
            } else if (i == self.current_step) {
                try writer.writeAll(self.config.current_char);
            } else {
                try writer.writeAll(self.config.upcoming_char);
            }
            try writer.writeAll(" ");
        }

        // Render separator and counter
        const counter = try std.fmt.allocPrint(allocator, "[ {} / {} ]", .{ self.current_step + 1, self.total_steps });
        defer allocator.free(counter);

        const dots_width = self.total_steps * 2;
        const separator_width = width - dots_width - counter.len - 1;

        for (0..separator_width) |_| {
            try writer.writeAll(self.config.separator_char);
        }
        try writer.writeAll(" ");
        try writer.writeAll(counter);
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
        for (0..width) |_| {
            try writer.writeAll(self.config.separator_char);
        }
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
    try expectProgressRender(0, 3, "Initializing", Config{},
        \\● ○ ○ ──────────────────────────────────────────── [ 1 / 3 ]
        \\                        Initializing
        \\────────────────────────────────────────────────────────────
        \\
    );
}

test "ProgressHeader render - middle step" {
    try expectProgressRender(1, 3, "Building", Config{},
        \\● ● ○ ──────────────────────────────────────────── [ 2 / 3 ]
        \\                          Building
        \\────────────────────────────────────────────────────────────
        \\
    );
}

test "ProgressHeader render - last step" {
    try expectProgressRender(2, 3, "Complete", Config{},
        \\● ● ● ──────────────────────────────────────────── [ 3 / 3 ]
        \\                          Complete
        \\────────────────────────────────────────────────────────────
        \\
    );
}

test "ProgressHeader render - custom width" {
    try expectProgressRender(0, 2, "Test", Config{ .width = 40 },
        \\● ○ ────────────────────────── [ 1 / 2 ]
        \\                  Test
        \\────────────────────────────────────────
        \\
    );
}

test "ProgressHeader render - custom width odd" {
    try expectProgressRender(0, 2, "Odd", Config{ .width = 45 },
        \\● ○ ─────────────────────────────── [ 1 / 2 ]
        \\                     Odd
        \\─────────────────────────────────────────────
        \\
    );
}
