//! Header and sequence indicator utilities
//!
//! Provides sophisticated header styles with full configurability.

const std = @import("std");
const colour = @import("colour.zig");
const terminal = @import("terminal.zig");
const unicode = @import("unicode.zig");
const Block = @import("block.zig").Block;

/// Generic helper to centre a block created by a toBlock function
/// Reduces duplication between ProgressHeader and StarterHeader
fn centreBlock(
    allocator: std.mem.Allocator,
    target_width: usize,
    header: anytype,
    comptime toBlockFn: fn (@TypeOf(header), std.mem.Allocator, usize) anyerror!Block,
) !Block {
    // Calculate natural width needed
    const natural_width = @min(target_width, @max(60, target_width * 3 / 4));

    // If no space for centring, just use regular toBlock
    if (target_width <= natural_width) {
        return toBlockFn(header, allocator, target_width);
    }

    // Build block at natural width
    const inner = try toBlockFn(header, allocator, natural_width);
    defer inner.deinit(allocator);

    // Centre the block
    const left_pad = (target_width - natural_width) / 2;
    const padding = try allocator.alloc(u8, left_pad);
    defer allocator.free(padding);
    @memset(padding, ' ');

    var centred_lines = try allocator.alloc(Block.Line, inner.lines.len);
    errdefer allocator.free(centred_lines);

    for (inner.lines, 0..) |line, i| {
        const content = try std.fmt.allocPrint(allocator, "{s}{s}", .{
            padding,
            line.content,
        });

        centred_lines[i] = .{
            .content = content,
            .display_width = left_pad + line.display_width,
        };
    }

    return .{
        .lines = centred_lines,
        .width = target_width,
        .height = inner.height,
    };
}

/// Build a separator line Block (Content layer)
pub fn separatorBlock(allocator: std.mem.Allocator, width: usize, config: Config) !Block {
    var line: std.ArrayList(u8) = .empty;
    errdefer line.deinit(allocator);

    if (config.use_colour and config.separator_gradient != null) {
        const gradient = config.separator_gradient.?;
        for (0..width) |i| {
            const t: f32 = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(width));
            const col = gradient.get(t);
            const ansi = try col.toAnsi(allocator);
            defer allocator.free(ansi);
            try line.appendSlice(allocator, ansi);
            try line.appendSlice(allocator, config.separator_marker);
        }
        try line.appendSlice(allocator, colour.reset);
    } else {
        for (0..width) |_| {
            try line.appendSlice(allocator, config.separator_marker);
        }
    }

    var lines = try allocator.alloc(Block.Line, 1);
    lines[0] = .{
        .content = try line.toOwnedSlice(allocator),
        .display_width = width,
    };

    return .{
        .lines = lines,
        .width = width,
        .height = 1,
    };
}

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

    /// Gradient for separator lines (null = use solid palette colour)
    separator_gradient: ?colour.Gradient = null,

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

    /// Render a separator line (handles rainbow, colour, width)
    /// Does NOT add newline - caller must add it
    /// offset: starting column position for rainbow alignment (0 = start of line)
    /// total_width: total line width for rainbow gradient calculation
    pub fn renderSeparator(
        self: Config,
        allocator: std.mem.Allocator,
        writer: *std.Io.Writer,
        width: usize,
        offset: usize,
        total_width: usize,
    ) !void {
        if (self.use_colour and self.separator_gradient != null) {
            // Gradient rendering aligned to full line width
            const gradient = self.separator_gradient.?;
            for (0..width) |i| {
                const t: f32 = @as(f32, @floatFromInt(offset + i)) / @as(f32, @floatFromInt(total_width));
                const col = gradient.get(t);
                try col.writeNoReset(allocator, writer, self.separator_marker);

                try writer.flush();
                std.posix.nanosleep(0, 3 * std.time.ns_per_ms);
            }
            try writer.writeAll(colour.reset);
        } else {
            // Solid colour or plain
            const total_len = self.separator_marker.len * width;
            const line = try allocator.alloc(u8, total_len);
            defer allocator.free(line);
            var pos: usize = 0;
            for (0..width) |_| {
                for (self.separator_marker) |byte| {
                    line[pos] = byte;
                    pos += 1;
                }
            }
            try self.write_secondary(allocator, writer, line);
        }
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

    /// Produce a Block for this header (Content layer)
    pub fn toBlock(self: ProgressHeader, allocator: std.mem.Allocator, width: usize) !Block {
        var lines = try allocator.alloc(Block.Line, 3);
        errdefer allocator.free(lines);

        lines[0] = try self.buildProgressLine(allocator, width);
        lines[1] = try self.buildTitleLine(allocator, width);
        lines[2] = try self.buildBottomLine(allocator, width);

        return .{
            .lines = lines,
            .width = width,
            .height = 3,
        };
    }

    /// Produce a centred Block for this header
    /// Single-phase: creates content at natural width then centres within target width
    pub fn toBlockCentred(self: ProgressHeader, allocator: std.mem.Allocator, target_width: usize) !Block {
        return centreBlock(allocator, target_width, self, ProgressHeader.toBlock);
    }

    // US spelling alias
    pub const toBlockCentered = toBlockCentred;

    fn buildProgressLine(self: ProgressHeader, allocator: std.mem.Allocator, width: usize) !Block.Line {
        var line: std.ArrayList(u8) = .empty;
        errdefer line.deinit(allocator);

        const all_completed = self.current_step >= self.total_steps;

        // Progress dots
        for (0..self.total_steps) |i| {
            const marker = if (all_completed or i < self.current_step)
                self.completed_marker
            else if (i == self.current_step)
                self.current_marker
            else
                self.upcoming_marker;

            const colour_type: colour.Type = if (all_completed or i < self.current_step)
                .accent
            else if (i == self.current_step)
                .primary
            else
                .subtle;

            if (self.config.use_colour) {
                const col = self.config.palette.get(colour_type);
                const ansi = try col.toAnsi(allocator);
                defer allocator.free(ansi);
                try line.appendSlice(allocator, ansi);
                try line.appendSlice(allocator, marker);
                try line.appendSlice(allocator, colour.reset);
            } else {
                try line.appendSlice(allocator, marker);
            }
            try line.append(allocator, ' ');
        }

        // Separator and counter
        const dots_width = self.total_steps * 2;
        const counter_num = if (self.current_step >= self.total_steps) self.total_steps else self.current_step + 1;
        const counter = try std.fmt.allocPrint(allocator, "[ {} / {} ]", .{ counter_num, self.total_steps });
        defer allocator.free(counter);
        const separator_width = width - dots_width - counter.len - 1;

        for (0..separator_width) |_| {
            try line.appendSlice(allocator, self.config.separator_marker);
        }

        try line.append(allocator, ' ');

        if (self.config.use_colour) {
            const col = self.config.palette.get(.secondary);
            const ansi = try col.toAnsi(allocator);
            defer allocator.free(ansi);
            try line.appendSlice(allocator, ansi);
            try line.appendSlice(allocator, counter);
            try line.appendSlice(allocator, colour.reset);
        } else {
            try line.appendSlice(allocator, counter);
        }

        return .{
            .content = try line.toOwnedSlice(allocator),
            .display_width = width,
        };
    }

    fn buildTitleLine(self: ProgressHeader, allocator: std.mem.Allocator, width: usize) !Block.Line {
        const padding = if (self.title.len < width)
            (width - self.title.len) / 2
        else
            self.config.title_padding;

        const spaces = try allocator.alloc(u8, padding);
        defer allocator.free(spaces);
        @memset(spaces, ' ');

        const content = try std.fmt.allocPrint(allocator, "{s}{s}", .{
            spaces,
            self.title,
        });

        return .{
            .content = content,
            .display_width = padding + self.title.len,
        };
    }

    fn buildBottomLine(self: ProgressHeader, allocator: std.mem.Allocator, width: usize) !Block.Line {
        var line: std.ArrayList(u8) = .empty;
        errdefer line.deinit(allocator);

        if (self.config.use_colour and self.config.separator_gradient != null) {
            const gradient = self.config.separator_gradient.?;
            for (0..width) |i| {
                const t: f32 = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(width));
                const col = gradient.get(t);
                const ansi = try col.toAnsi(allocator);
                defer allocator.free(ansi);
                try line.appendSlice(allocator, ansi);
                try line.appendSlice(allocator, self.config.separator_marker);
            }
            try line.appendSlice(allocator, colour.reset);
        } else {
            for (0..width) |_| {
                try line.appendSlice(allocator, self.config.separator_marker);
            }
        }

        return .{
            .content = try line.toOwnedSlice(allocator),
            .display_width = width,
        };
    }
};

test "ProgressHeader init" {
    const config = Config{};
    const header = ProgressHeader.init(0, 3, "Test", config);
    try std.testing.expectEqual(0, header.current_step);
    try std.testing.expectEqual(3, header.total_steps);
    try std.testing.expectEqualStrings("Test", header.title);
}

test "ProgressHeader toBlock - exact match" {
    const allocator = std.testing.allocator;

    const progress = ProgressHeader.init(1, 3, "Building", Config{ .use_colour = false });
    const block = try progress.toBlock(allocator, 60);
    defer block.deinit(allocator);

    try std.testing.expectEqual(3, block.height);
    try std.testing.expectEqual(60, block.width);

    try std.testing.expectEqualStrings(
        \\● ◉ ○ ──────────────────────────────────────────── [ 2 / 3 ]
    , block.lines[0].content);

    try std.testing.expectEqualStrings(
        \\                          Building
    , block.lines[1].content);

    try std.testing.expectEqualStrings(
        \\────────────────────────────────────────────────────────────
    , block.lines[2].content);
}

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

    /// Produce a Block for this header (Content layer)
    pub fn toBlock(self: StarterHeader, allocator: std.mem.Allocator, width: usize) !Block {
        var lines = try allocator.alloc(Block.Line, 3);
        errdefer allocator.free(lines);

        // Line 1: starter + separator + context
        lines[0] = try self.buildTopLine(allocator, width);

        // Line 2: centred title
        lines[1] = try self.buildTitleLine(allocator, width);

        // Line 3: full separator
        lines[2] = try self.buildBottomLine(allocator, width);

        return .{
            .lines = lines,
            .width = width,
            .height = 3,
        };
    }

    /// Produce a centred Block for this header
    /// Single-phase: creates content at natural width then centres within target width
    pub fn toBlockCentred(self: StarterHeader, allocator: std.mem.Allocator, target_width: usize) !Block {
        return centreBlock(allocator, target_width, self, StarterHeader.toBlock);
    }

    // US spelling alias
    pub const toBlockCentered = toBlockCentred;

    fn buildTopLine(self: StarterHeader, allocator: std.mem.Allocator, width: usize) !Block.Line {
        var line: std.ArrayList(u8) = .empty;
        errdefer line.deinit(allocator);

        var used_width: usize = 0;

        // Starter marker
        if (self.starter_marker.len > 0) {
            if (self.config.use_colour) {
                const col = self.config.palette.get(.primary);
                const ansi = try col.toAnsi(allocator);
                defer allocator.free(ansi);
                try line.appendSlice(allocator, ansi);
                try line.appendSlice(allocator, self.starter_marker);
                try line.appendSlice(allocator, colour.reset);
            } else {
                try line.appendSlice(allocator, self.starter_marker);
            }
            try line.append(allocator, ' ');
            used_width = unicode.displayWidth(self.starter_marker) + 1;
        }

        // Context text
        const context_text = if (self.context) |ctx|
            try std.fmt.allocPrint(allocator, "[ {s} ]", .{ctx})
        else
            try allocator.dupe(u8, "");
        defer allocator.free(context_text);

        // Separator
        const separator_width = if (context_text.len > 0)
            width - used_width - context_text.len - 1
        else
            width - used_width;

        if (self.config.use_colour and self.config.separator_gradient != null) {
            const gradient = self.config.separator_gradient.?;
            for (0..separator_width) |i| {
                const t: f32 = @as(f32, @floatFromInt(used_width + i)) / @as(f32, @floatFromInt(width));
                const col = gradient.get(t);
                const ansi = try col.toAnsi(allocator);
                defer allocator.free(ansi);
                try line.appendSlice(allocator, ansi);
                try line.appendSlice(allocator, self.config.separator_marker);
            }
            try line.appendSlice(allocator, colour.reset);
        } else {
            for (0..separator_width) |_| {
                try line.appendSlice(allocator, self.config.separator_marker);
            }
        }

        // Context
        if (context_text.len > 0) {
            try line.append(allocator, ' ');
            if (self.config.use_colour) {
                const col = self.config.palette.get(.secondary);
                const ansi = try col.toAnsi(allocator);
                defer allocator.free(ansi);
                try line.appendSlice(allocator, ansi);
                try line.appendSlice(allocator, context_text);
                try line.appendSlice(allocator, colour.reset);
            } else {
                try line.appendSlice(allocator, context_text);
            }
        }

        return .{
            .content = try line.toOwnedSlice(allocator),
            .display_width = width,
        };
    }

    fn buildTitleLine(self: StarterHeader, allocator: std.mem.Allocator, width: usize) !Block.Line {
        const padding = if (self.title.len < width)
            (width - self.title.len) / 2
        else
            self.config.title_padding;

        const spaces = try allocator.alloc(u8, padding);
        defer allocator.free(spaces);
        @memset(spaces, ' ');

        const content = try std.fmt.allocPrint(allocator, "{s}{s}", .{
            spaces,
            self.title,
        });

        return .{
            .content = content,
            .display_width = padding + self.title.len,
        };
    }

    fn buildBottomLine(self: StarterHeader, allocator: std.mem.Allocator, width: usize) !Block.Line {
        var line: std.ArrayList(u8) = .empty;
        errdefer line.deinit(allocator);

        if (self.config.use_colour and self.config.separator_gradient != null) {
            const gradient = self.config.separator_gradient.?;
            for (0..width) |i| {
                const t: f32 = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(width));
                const col = gradient.get(t);
                const ansi = try col.toAnsi(allocator);
                defer allocator.free(ansi);
                try line.appendSlice(allocator, ansi);
                try line.appendSlice(allocator, self.config.separator_marker);
            }
            try line.appendSlice(allocator, colour.reset);
        } else {
            for (0..width) |_| {
                try line.appendSlice(allocator, self.config.separator_marker);
            }
        }

        return .{
            .content = try line.toOwnedSlice(allocator),
            .display_width = width,
        };
    }
};

test "Config renderSeparator two_colour gradient - exact 60 char match" {
    const allocator = std.testing.allocator;

    var output_buffer: [8192]u8 = undefined;
    var output_writer = std.Io.Writer.fixed(&output_buffer);

    const config = Config{
        .separator_gradient = .{ .two_colour = .{
            .start = .{ .r = 100, .g = 200, .b = 100 },
            .end = .{ .r = 200, .g = 100, .b = 200 },
        } },
    };

    try config.renderSeparator(allocator, &output_writer, 60, 0, 60);

    const output = output_writer.buffered();

    const expected =
        "\x1b[38;2;100;200;100m─" ++ "\x1b[38;2;101;198;101m─" ++ "\x1b[38;2;103;196;103m─" ++ "\x1b[38;2;105;195;105m─" ++ "\x1b[38;2;106;193;106m─" ++
        "\x1b[38;2;108;191;108m─" ++ "\x1b[38;2;110;190;110m─" ++ "\x1b[38;2;111;188;111m─" ++ "\x1b[38;2;113;186;113m─" ++ "\x1b[38;2;115;185;115m─" ++
        "\x1b[38;2;116;183;116m─" ++ "\x1b[38;2;118;181;118m─" ++ "\x1b[38;2;120;180;120m─" ++ "\x1b[38;2;121;178;121m─" ++ "\x1b[38;2;123;176;123m─" ++
        "\x1b[38;2;125;175;125m─" ++ "\x1b[38;2;126;173;126m─" ++ "\x1b[38;2;128;171;128m─" ++ "\x1b[38;2;130;170;130m─" ++ "\x1b[38;2;131;168;131m─" ++
        "\x1b[38;2;133;166;133m─" ++ "\x1b[38;2;135;165;135m─" ++ "\x1b[38;2;136;163;136m─" ++ "\x1b[38;2;138;161;138m─" ++ "\x1b[38;2;140;160;140m─" ++
        "\x1b[38;2;141;158;141m─" ++ "\x1b[38;2;143;156;143m─" ++ "\x1b[38;2;145;155;145m─" ++ "\x1b[38;2;146;153;146m─" ++ "\x1b[38;2;148;151;148m─" ++
        "\x1b[38;2;150;150;150m─" ++ "\x1b[38;2;151;148;151m─" ++ "\x1b[38;2;153;146;153m─" ++ "\x1b[38;2;155;145;155m─" ++ "\x1b[38;2;156;143;156m─" ++
        "\x1b[38;2;158;141;158m─" ++ "\x1b[38;2;160;140;160m─" ++ "\x1b[38;2;161;138;161m─" ++ "\x1b[38;2;163;136;163m─" ++ "\x1b[38;2;165;135;165m─" ++
        "\x1b[38;2;166;133;166m─" ++ "\x1b[38;2;168;131;168m─" ++ "\x1b[38;2;170;130;170m─" ++ "\x1b[38;2;171;128;171m─" ++ "\x1b[38;2;173;126;173m─" ++
        "\x1b[38;2;175;125;175m─" ++ "\x1b[38;2;176;123;176m─" ++ "\x1b[38;2;178;121;178m─" ++ "\x1b[38;2;180;120;180m─" ++ "\x1b[38;2;181;118;181m─" ++
        "\x1b[38;2;183;116;183m─" ++ "\x1b[38;2;185;115;185m─" ++ "\x1b[38;2;186;113;186m─" ++ "\x1b[38;2;188;111;188m─" ++ "\x1b[38;2;190;110;190m─" ++
        "\x1b[38;2;191;108;191m─" ++ "\x1b[38;2;193;106;193m─" ++ "\x1b[38;2;195;105;195m─" ++ "\x1b[38;2;196;103;196m─" ++ "\x1b[38;2;198;101;198m─" ++ "\x1b[0m";

    try std.testing.expectEqualStrings(expected, output);
}

test "StarterHeader toBlock - exact match" {
    const allocator = std.testing.allocator;

    const starter = StarterHeader.init("Configuration", "ren", Config{ .use_colour = false });
    const block = try starter.toBlock(allocator, 60);
    defer block.deinit(allocator);

    try std.testing.expectEqual(3, block.height);
    try std.testing.expectEqual(60, block.width);

    try std.testing.expectEqualStrings(
        \\⚝ ────────────────────────────────────────────────── [ ren ]
    , block.lines[0].content);

    try std.testing.expectEqualStrings(
        \\                       Configuration
    , block.lines[1].content);

    try std.testing.expectEqualStrings(
        \\────────────────────────────────────────────────────────────
    , block.lines[2].content);
}

test "StarterHeader with custom starter_marker" {
    const allocator = std.testing.allocator;
    const config = Config{ .use_colour = false };
    const header = StarterHeader.init("Custom", null, config);
    const header_with_custom = StarterHeader{
        .title = header.title,
        .context = header.context,
        .config = header.config,
        .starter_marker = "❯",
    };

    const block = try header_with_custom.toBlock(allocator, 60);
    defer block.deinit(allocator);

    const output = try block.toString(allocator);
    defer allocator.free(output);

    const expected =
        \\❯ ──────────────────────────────────────────────────────────
        \\                           Custom
        \\────────────────────────────────────────────────────────────
    ;

    try std.testing.expectEqualStrings(expected, output);
}

test "ProgressHeader toBlockCentred" {
    const allocator = std.testing.allocator;
    const config = Config{ .use_colour = false };
    const header = ProgressHeader.init(1, 3, "Building", config);

    const block = try header.toBlockCentred(allocator, 80);
    defer block.deinit(allocator);

    const output = try block.toString(allocator);
    defer allocator.free(output);

    // Block should be centred within 80 columns with padding on left
    try std.testing.expectEqual(@as(usize, 80), block.width);
    try std.testing.expectEqual(@as(usize, 3), block.height);

    // Check that output starts with spaces (centring)
    const expected =
        \\          ● ◉ ○ ──────────────────────────────────────────── [ 2 / 3 ]
        \\                                    Building
        \\          ────────────────────────────────────────────────────────────
    ;

    try std.testing.expectEqualStrings(expected, output);
}

test "ProgressHeader toBlockCentred with small target" {
    const allocator = std.testing.allocator;
    const config = Config{ .use_colour = false };
    const header = ProgressHeader.init(1, 3, "Test", config);

    // Target too small for centring - should use regular toBlock at target width
    const block = try header.toBlockCentred(allocator, 40);
    defer block.deinit(allocator);

    const output = try block.toString(allocator);
    defer allocator.free(output);

    try std.testing.expectEqual(@as(usize, 40), block.width);

    // Should look like regular toBlock output (no extra padding)
    const expected =
        \\● ◉ ○ ──────────────────────── [ 2 / 3 ]
        \\                  Test
        \\────────────────────────────────────────
    ;

    try std.testing.expectEqualStrings(expected, output);
}

test "StarterHeader toBlockCentred" {
    const allocator = std.testing.allocator;
    const config = Config{ .use_colour = false };
    const header = StarterHeader.init("Welcome", "ren", config);

    const block = try header.toBlockCentred(allocator, 80);
    defer block.deinit(allocator);

    const output = try block.toString(allocator);
    defer allocator.free(output);

    // Block should be centred within 80 columns
    try std.testing.expectEqual(@as(usize, 80), block.width);
    try std.testing.expectEqual(@as(usize, 3), block.height);

    // Expect centred output (10 spaces padding on left)
    const expected =
        \\          ⚝ ────────────────────────────────────────────────── [ ren ]
        \\                                    Welcome
        \\          ────────────────────────────────────────────────────────────
    ;

    try std.testing.expectEqualStrings(expected, output);
}

test "StarterHeader toBlockCentred without context" {
    const allocator = std.testing.allocator;
    const config = Config{ .use_colour = false };
    const header = StarterHeader.init("Status", null, config);

    const block = try header.toBlockCentred(allocator, 80);
    defer block.deinit(allocator);

    const output = try block.toString(allocator);
    defer allocator.free(output);

    try std.testing.expectEqual(@as(usize, 80), block.width);

    const expected =
        \\          ⚝ ──────────────────────────────────────────────────────────
        \\                                     Status
        \\          ────────────────────────────────────────────────────────────
    ;

    try std.testing.expectEqualStrings(expected, output);
}

test "StarterHeader toBlockCentred with small target" {
    const allocator = std.testing.allocator;
    const config = Config{ .use_colour = false };
    const header = StarterHeader.init("Test", null, config);

    const block = try header.toBlockCentred(allocator, 40);
    defer block.deinit(allocator);

    const output = try block.toString(allocator);
    defer allocator.free(output);

    try std.testing.expectEqual(@as(usize, 40), block.width);

    // No centring - regular toBlock output
    const expected =
        \\⚝ ──────────────────────────────────────
        \\                  Test
        \\────────────────────────────────────────
    ;

    try std.testing.expectEqualStrings(expected, output);
}
