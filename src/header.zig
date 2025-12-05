//! Header and sequence indicator utilities
//!
//! Provides sophisticated header styles with full configurability.

const std = @import("std");
const colour = @import("colour.zig");
const terminal = @import("terminal.zig");
const unicode = @import("unicode.zig");

/// Configuration for header appearance
pub const Config = struct {
    /// Separator marker
    separator_marker: []const u8 = "─",

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
    title: []const u8,
    current_step: usize,
    total_steps: usize,
    config: Config,

    /// Markers for progress states
    completed_marker: []const u8 = "●",
    current_marker: []const u8 = "◉",
    upcoming_marker: []const u8 = "○",

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

        // Check if all steps are completed
        const all_completed = self.current_step >= self.total_steps;

        // First line: render progress dots with colours
        for (0..self.total_steps) |i| {
            if (all_completed or i < self.current_step) {
                try self.config.write_accent(allocator, writer, self.completed_marker);
            } else if (i == self.current_step) {
                try self.config.write_primary(allocator, writer, self.current_marker);
            } else {
                try self.config.write_subtle(allocator, writer, self.upcoming_marker);
            }
            try writer.writeAll(" ");
        }

        // Render separator
        const dots_width = self.total_steps * 2;
        const counter_num = if (self.current_step >= self.total_steps) self.total_steps else self.current_step + 1;
        const counter = try std.fmt.allocPrint(allocator, "[ {} / {} ]", .{ counter_num, self.total_steps });
        defer allocator.free(counter);
        const separator_width = width - dots_width - counter.len - 1;

        const separator_line = try buildSeparatorLine(allocator, self.config.separator_marker, separator_width);
        defer allocator.free(separator_line);
        try self.config.write_secondary(allocator, writer, separator_line);

        try writer.writeAll(" ");
        try self.config.write_secondary(allocator, writer, counter);
        try writer.writeAll("\n");

        // Second line: title (centred)
        try renderCentredTitle(writer, self.title, width, self.config.title_padding);

        // Third line: full separator
        try renderBottomSeparator(allocator, writer, self.config, width);

        try writer.flush();
    }
};

/// Starter header for single operations
pub const StarterHeader = struct {
    title: []const u8,
    context: ?[]const u8,
    config: Config,

    /// Starter marker (can be empty)
    starter_marker: []const u8 = "⚝",

    pub fn init(title: []const u8, context: ?[]const u8, config: Config) StarterHeader {
        return .{
            .title = title,
            .context = context,
            .config = config,
        };
    }

    /// Render the starter header
    /// Format: ⚝ ──────────────── [ context ]
    ///              Title
    ///         ────────────────────────────────
    pub fn render(self: StarterHeader, allocator: std.mem.Allocator, writer: *std.Io.Writer) !void {
        // Get width: configured > detected > fallback to 60
        const width = self.config.width orelse terminal.detectWidth() orelse 60;

        // First line: starter marker (if not empty), separator, optional context
        var used_width: usize = 0;

        if (self.starter_marker.len > 0) {
            try self.config.write_primary(allocator, writer, self.starter_marker);
            try writer.writeAll(" ");
            used_width = unicode.displayWidth(self.starter_marker) + 1; // marker + space
        }

        const context_text = if (self.context) |ctx|
            try std.fmt.allocPrint(allocator, "[ {s} ]", .{ctx})
        else
            try allocator.dupe(u8, "");
        defer allocator.free(context_text);

        // Calculate separator width based on whether we have context
        const separator_width = if (context_text.len > 0)
            width - used_width - context_text.len - 1 // -1 for space before context
        else
            width - used_width; // no space needed when no context

        const separator_line = try buildSeparatorLine(allocator, self.config.separator_marker, separator_width);
        defer allocator.free(separator_line);
        try self.config.write_secondary(allocator, writer, separator_line);

        if (context_text.len > 0) {
            try writer.writeAll(" ");
            try self.config.write_secondary(allocator, writer, context_text);
        }
        try writer.writeAll("\n");

        // Second line: title (centred)
        try renderCentredTitle(writer, self.title, width, self.config.title_padding);

        // Third line: full separator
        try renderBottomSeparator(allocator, writer, self.config, width);

        try writer.flush();
    }
};

// Helper: build separator line from separator char repeated count times
fn buildSeparatorLine(allocator: std.mem.Allocator, separator_char: []const u8, count: usize) ![]u8 {
    const total_len = separator_char.len * count;
    const line = try allocator.alloc(u8, total_len);
    var pos: usize = 0;
    for (0..count) |_| {
        for (separator_char) |byte| {
            line[pos] = byte;
            pos += 1;
        }
    }
    return line;
}

// Helper: render centred title line
fn renderCentredTitle(writer: *std.Io.Writer, title: []const u8, width: usize, title_padding: usize) !void {
    const padding = if (title.len < width)
        (width - title.len) / 2
    else
        title_padding;

    for (0..padding) |_| {
        try writer.writeAll(" ");
    }
    try writer.writeAll(title);
    try writer.writeAll("\n");
}

// Helper: render full-width separator line at bottom
fn renderBottomSeparator(allocator: std.mem.Allocator, writer: *std.Io.Writer, config: Config, width: usize) !void {
    const separator_line = try buildSeparatorLine(allocator, config.separator_marker, width);
    defer allocator.free(separator_line);
    try config.write_secondary(allocator, writer, separator_line);
    try writer.writeAll("\n");
}

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

test "ProgressHeader render - all completed" {
    try expectProgressRender(3, 3, "All Done", Config{ .use_colour = false },
        \\● ● ● ──────────────────────────────────────────── [ 3 / 3 ]
        \\                          All Done
        \\────────────────────────────────────────────────────────────
        \\
    );
}

// Test helper for StarterHeader
fn expectStarterRender(
    title: []const u8,
    context: ?[]const u8,
    config: Config,
    expected: []const u8,
) !void {
    const allocator = std.testing.allocator;
    const header = StarterHeader.init(title, context, config);

    var output_buffer: [2048]u8 = undefined;
    var output_writer = std.Io.Writer.fixed(&output_buffer);

    try header.render(allocator, &output_writer);

    const output = output_writer.buffered();

    try std.testing.expectEqualStrings(expected, output);
}

test "StarterHeader with context" {
    try expectStarterRender("Configuration", "ren", Config{ .use_colour = false },
        \\⚝ ────────────────────────────────────────────────── [ ren ]
        \\                       Configuration
        \\────────────────────────────────────────────────────────────
        \\
    );
}

test "StarterHeader without context" {
    try expectStarterRender("Status", null, Config{ .use_colour = false },
        \\⚝ ──────────────────────────────────────────────────────────
        \\                           Status
        \\────────────────────────────────────────────────────────────
        \\
    );
}

test "StarterHeader with empty starter_marker" {
    const config = Config{ .use_colour = false };
    const header = StarterHeader.init("Title", "info", config);
    const header_with_empty = StarterHeader{
        .title = header.title,
        .context = header.context,
        .config = header.config,
        .starter_marker = "",
    };

    var output_buffer: [2048]u8 = undefined;
    var output_writer = std.Io.Writer.fixed(&output_buffer);

    const allocator = std.testing.allocator;
    try header_with_empty.render(allocator, &output_writer);

    const output = output_writer.buffered();
    const expected =
        \\─────────────────────────────────────────────────── [ info ]
        \\                           Title
        \\────────────────────────────────────────────────────────────
        \\
    ;

    try std.testing.expectEqualStrings(expected, output);
}

test "StarterHeader with custom starter_marker" {
    const config = Config{ .use_colour = false };
    const header = StarterHeader.init("Custom", null, config);
    const header_with_custom = StarterHeader{
        .title = header.title,
        .context = header.context,
        .config = header.config,
        .starter_marker = "❯",
    };

    var output_buffer: [2048]u8 = undefined;
    var output_writer = std.Io.Writer.fixed(&output_buffer);

    const allocator = std.testing.allocator;
    try header_with_custom.render(allocator, &output_writer);

    const output = output_writer.buffered();
    const expected =
        \\❯ ──────────────────────────────────────────────────────────
        \\                           Custom
        \\────────────────────────────────────────────────────────────
        \\
    ;

    try std.testing.expectEqualStrings(expected, output);
}
