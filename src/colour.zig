//! Colour utilities for terminal output
//!
//! Supports truecolor (24-bit RGB), 256-colour, and 16-colour ANSI.

const std = @import("std");

/// RGB colour value for truecolor support
pub const Colour = struct {
    r: u8,
    g: u8,
    b: u8,

    /// Convert to ANSI truecolor escape code
    pub fn toAnsi(self: Colour, allocator: std.mem.Allocator) ![]u8 {
        return try std.fmt.allocPrint(allocator, "\x1b[38;2;{};{};{}m", .{ self.r, self.g, self.b });
    }

    /// Write text with this colour to a writer
    pub fn write(self: Colour, allocator: std.mem.Allocator, writer: *std.Io.Writer, text: []const u8) !void {
        const ansi = try self.toAnsi(allocator);
        defer allocator.free(ansi);

        try writer.writeAll(ansi);
        try writer.writeAll(text);
        try writer.writeAll(reset);
    }

    // TODO: Add fallback conversion methods for terminal compatibility
    // pub fn to256Colour(self: Colour) u8 { }
    // pub fn to16Colour(self: Colour) u8 { }
};

/// Reset colour to default
pub const reset = "\x1b[0m";

/// Semantic colour types
pub const Type = enum {
    neutral,
    primary,
    secondary,
    accent,
    subtle,
    info,
    warning,
};

/// Colour palette - maps Types to Colours
pub const Palette = struct {
    neutral: Colour,
    primary: ?Colour = null,
    secondary: ?Colour = null,
    accent: ?Colour = null,
    subtle: ?Colour = null,
    info: ?Colour = null,
    warning: ?Colour = null,

    /// Get colour for a type, fallback to neutral if not defined
    pub fn get(self: Palette, colour_type: Type) Colour {
        return switch (colour_type) {
            .neutral => self.neutral,
            .primary => self.primary orelse self.neutral,
            .secondary => self.secondary orelse self.neutral,
            .accent => self.accent orelse self.neutral,
            .subtle => self.subtle orelse self.neutral,
            .info => self.info orelse self.neutral,
            .warning => self.warning orelse self.neutral,
        };
    }
};

/// The ren palette - default sophisticated palette
pub const ren = Palette{
    .neutral = .{ .r = 180, .g = 180, .b = 180 },
    .primary = .{ .r = 230, .g = 180, .b = 100 }, // warm amber
    .secondary = .{ .r = 140, .g = 140, .b = 145 }, // dim grey
    .accent = .{ .r = 120, .g = 200, .b = 140 }, // refined green
    .subtle = .{ .r = 160, .g = 160, .b = 165 }, // subtle grey
    .info = .{ .r = 120, .g = 180, .b = 220 },
    .warning = .{ .r = 220, .g = 160, .b = 100 },
};

/// Warm earth tones palette
pub const warm = Palette{
    .neutral = .{ .r = 180, .g = 175, .b = 170 },
    .primary = .{ .r = 220, .g = 140, .b = 80 },
    .secondary = .{ .r = 150, .g = 145, .b = 140 },
    .accent = .{ .r = 200, .g = 160, .b = 100 },
    .subtle = .{ .r = 180, .g = 170, .b = 160 },
};

/// Cool blues and cyans palette
pub const cool = Palette{
    .neutral = .{ .r = 170, .g = 175, .b = 180 },
    .primary = .{ .r = 120, .g = 180, .b = 230 },
    .secondary = .{ .r = 140, .g = 145, .b = 155 },
    .accent = .{ .r = 100, .g = 200, .b = 180 },
    .subtle = .{ .r = 160, .g = 170, .b = 180 },
};

/// Monochrome greyscale palette
pub const monochrome = Palette{
    .neutral = .{ .r = 160, .g = 160, .b = 160 },
    .primary = .{ .r = 200, .g = 200, .b = 200 },
    .secondary = .{ .r = 120, .g = 120, .b = 120 },
    .accent = .{ .r = 220, .g = 220, .b = 220 },
    .subtle = .{ .r = 140, .g = 140, .b = 140 },
};

test "Colour toAnsi conversion" {
    const allocator = std.testing.allocator;
    const colour = Colour{ .r = 255, .g = 128, .b = 64 };
    const ansi = try colour.toAnsi(allocator);
    defer allocator.free(ansi);

    try std.testing.expectEqualStrings("\x1b[38;2;255;128;64m", ansi);
}

test "Palette get method" {
    const palette = ren;

    const primary_colour = palette.get(.primary);

    // Can be converted to ANSI
    const allocator = std.testing.allocator;
    const primary_ansi = try primary_colour.toAnsi(allocator);
    defer allocator.free(primary_ansi);

    try std.testing.expect(std.mem.startsWith(u8, primary_ansi, "\x1b[38;2;"));
}

test "Palette fallback to neutral" {
    const minimal = Palette{ .neutral = .{ .r = 100, .g = 100, .b = 100 } };

    // Undefined types should fallback to neutral
    const primary_colour = minimal.get(.primary);
    try std.testing.expectEqual(100, primary_colour.r);
}

test "Colour write helper" {
    const allocator = std.testing.allocator;

    var output_buffer: [64]u8 = undefined;
    var output_writer = std.Io.Writer.fixed(&output_buffer);

    const test_colour = Colour{ .r = 255, .g = 128, .b = 64 };
    try test_colour.write(allocator, &output_writer, "Hello");

    const output = output_writer.buffered();
    const expected = "\x1b[38;2;255;128;64mHello\x1b[0m";

    try std.testing.expectEqualStrings(expected, output);
}

test "reset is correct" {
    try std.testing.expectEqualStrings("\x1b[0m", reset);
}
