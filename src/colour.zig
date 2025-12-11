//! Colour utilities for terminal output
//!
//! Supports truecolor (24-bit RGB), 256-colour, and 16-colour ANSI.

const std = @import("std");

// Helper: parse two hex characters to byte (comptime)
fn parseHexByte(comptime hex: []const u8) u8 {
    if (hex.len != 2) @compileError("Hex byte must be 2 characters");

    const hi = parseHexDigit(hex[0]);
    const lo = parseHexDigit(hex[1]);

    return hi * 16 + lo;
}

// Helper: parse single hex digit (comptime)
fn parseHexDigit(comptime c: u8) u8 {
    return switch (c) {
        '0'...'9' => c - '0',
        'a'...'f' => c - 'a' + 10,
        'A'...'F' => c - 'A' + 10,
        else => @compileError("Invalid hex digit"),
    };
}

/// RGBA colour value for truecolor support with alpha channel
pub const Colour = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8 = 255, // Alpha: 0 = transparent, 255 = opaque

    /// Create colour from hex string at compile time
    /// Accepts "#RRGGBB", "RRGGBB", "#RGB", or "RGB"
    pub fn hex(comptime str: []const u8) Colour {
        const s = if (str.len > 0 and str[0] == '#') str[1..] else str;

        if (s.len == 3) {
            // Short form: #RGB -> #RRGGBB
            return .{
                .r = comptime parseHexDigit(s[0]) * 17, // F -> FF (15 * 17 = 255)
                .g = comptime parseHexDigit(s[1]) * 17,
                .b = comptime parseHexDigit(s[2]) * 17,
            };
        } else if (s.len == 6) {
            // Full form: #RRGGBB
            return .{
                .r = comptime parseHexByte(s[0..2]),
                .g = comptime parseHexByte(s[2..4]),
                .b = comptime parseHexByte(s[4..6]),
            };
        } else {
            @compileError("Hex colour must be 3 (RGB) or 6 (RRGGBB) characters");
        }
    }

    /// Convert to ANSI truecolor escape code
    /// If alpha < 255, blends with background (default: terminal background ~black)
    pub fn toAnsi(self: Colour, allocator: std.mem.Allocator) ![]u8 {
        if (self.a == 255) {
            // Fully opaque, use as-is
            return try std.fmt.allocPrint(allocator, "\x1b[38;2;{};{};{}m", .{ self.r, self.g, self.b });
        } else {
            // Blend with background (assume dark terminal)
            const bg = Colour{ .r = 20, .g = 20, .b = 20, .a = 255 };
            const blended = self.blend(bg);
            return try std.fmt.allocPrint(allocator, "\x1b[38;2;{};{};{}m", .{ blended.r, blended.g, blended.b });
        }
    }

    /// Write text with this colour to a writer (includes reset)
    pub fn write(self: Colour, allocator: std.mem.Allocator, writer: *std.Io.Writer, text: []const u8) !void {
        const ansi = try self.toAnsi(allocator);
        defer allocator.free(ansi);

        try writer.writeAll(ansi);
        try writer.writeAll(text);
        try writer.writeAll(reset);
    }

    /// Write text with this colour without reset (for continuous sequences)
    pub fn writeNoReset(self: Colour, allocator: std.mem.Allocator, writer: *std.Io.Writer, text: []const u8) !void {
        const ansi = try self.toAnsi(allocator);
        defer allocator.free(ansi);

        try writer.writeAll(ansi);
        try writer.writeAll(text);
    }

    /// Create a new colour with specified alpha
    pub fn withAlpha(self: Colour, alpha: u8) Colour {
        return .{ .r = self.r, .g = self.g, .b = self.b, .a = alpha };
    }

    /// Blend this colour with background based on alpha channel
    /// Returns opaque colour (alpha = 255) that looks like transparent overlay
    pub fn blend(self: Colour, background: Colour) Colour {
        const alpha_f = @as(f32, @floatFromInt(self.a)) / 255.0;
        const inv_alpha = 1.0 - alpha_f;

        return .{
            .r = @intFromFloat(@as(f32, @floatFromInt(self.r)) * alpha_f + @as(f32, @floatFromInt(background.r)) * inv_alpha),
            .g = @intFromFloat(@as(f32, @floatFromInt(self.g)) * alpha_f + @as(f32, @floatFromInt(background.g)) * inv_alpha),
            .b = @intFromFloat(@as(f32, @floatFromInt(self.b)) * alpha_f + @as(f32, @floatFromInt(background.b)) * inv_alpha),
            .a = 255,
        };
    }

    // TODO: Add fallback conversion methods for terminal compatibility
    // pub fn to256Colour(self: Colour) u8 { }
    // pub fn to16Colour(self: Colour) u8 { }
};

test "Colour with alpha channel" {
    const c = Colour{ .r = 255, .g = 128, .b = 64, .a = 128 };
    try std.testing.expectEqual(128, c.a);

    const full_opacity = c.withAlpha(255);
    try std.testing.expectEqual(255, full_opacity.a);
    try std.testing.expectEqual(255, full_opacity.r); // RGB unchanged
}

test "Colour blend with background" {
    const fg = Colour{ .r = 200, .g = 100, .b = 50, .a = 128 }; // 50% transparent
    const bg = Colour{ .r = 0, .g = 0, .b = 0, .a = 255 }; // black background

    const blended = fg.blend(bg);

    // 50% blend: (200*0.5 + 0*0.5) = 100
    try std.testing.expectEqual(100, blended.r);
    try std.testing.expectEqual(50, blended.g);
    try std.testing.expectEqual(25, blended.b);
    try std.testing.expectEqual(255, blended.a); // Result is opaque
}

test "Colour toAnsi with alpha blends automatically" {
    const allocator = std.testing.allocator;

    // Transparent colour
    const transparent = Colour{ .r = 200, .g = 200, .b = 200, .a = 128 };
    const ansi = try transparent.toAnsi(allocator);
    defer allocator.free(ansi);

    // Should contain blended RGB values (not original 200,200,200)
    try std.testing.expect(std.mem.indexOf(u8, ansi, "200;200;200") == null);
    try std.testing.expect(std.mem.startsWith(u8, ansi, "\x1b[38;2;"));
}

test "Colour hex parsing - 6 digit" {
    const c1 = Colour.hex("#FF8040");
    try std.testing.expectEqual(255, c1.r);
    try std.testing.expectEqual(128, c1.g);
    try std.testing.expectEqual(64, c1.b);
    try std.testing.expectEqual(255, c1.a); // Default opaque

    const c2 = Colour.hex("A0B0C0");
    try std.testing.expectEqual(160, c2.r);
    try std.testing.expectEqual(176, c2.g);
    try std.testing.expectEqual(192, c2.b);

    // Case insensitive
    const c3 = Colour.hex("aabbcc");
    try std.testing.expectEqual(170, c3.r);
    try std.testing.expectEqual(187, c3.g);
    try std.testing.expectEqual(204, c3.b);
}

test "Colour hex parsing - 3 digit shorthand" {
    const c1 = Colour.hex("#FFF");
    try std.testing.expectEqual(255, c1.r);
    try std.testing.expectEqual(255, c1.g);
    try std.testing.expectEqual(255, c1.b);

    const c2 = Colour.hex("F80"); // #FF8800
    try std.testing.expectEqual(255, c2.r);
    try std.testing.expectEqual(136, c2.g); // 8 * 17 = 136
    try std.testing.expectEqual(0, c2.b);

    const c3 = Colour.hex("#ABC");
    try std.testing.expectEqual(170, c3.r); // A * 17 = 170
    try std.testing.expectEqual(187, c3.g); // B * 17 = 187
    try std.testing.expectEqual(204, c3.b); // C * 17 = 204
}

test "Colour hex usage in gradients" {
    const grad = Gradient{ .two_colour = .{
        .start = Colour.hex("#9DC8C8"),
        .end = Colour.hex("#9D9DF2"),
    } };

    const start_col = grad.get(0.0);
    try std.testing.expectEqual(157, start_col.r);
    try std.testing.expectEqual(200, start_col.g);
    try std.testing.expectEqual(200, start_col.b);
}

// Compile error tests (these should fail at compile time if uncommented)
// test "Colour hex - invalid length" {
//     const c = Colour.hex("#FFF");  // Error: must be 6 characters
// }
// test "Colour hex - invalid character" {
//     const c = Colour.hex("#GGGGGG");  // Error: invalid hex digit
// }

test "Colour toAnsi conversion" {
    const allocator = std.testing.allocator;
    const colour = Colour{ .r = 255, .g = 128, .b = 64 };
    const ansi = try colour.toAnsi(allocator);
    defer allocator.free(ansi);

    try std.testing.expectEqualStrings("\x1b[38;2;255;128;64m", ansi);
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

test "Colour writeNoReset for sequences" {
    const allocator = std.testing.allocator;

    var output_buffer: [128]u8 = undefined;
    var output_writer = std.Io.Writer.fixed(&output_buffer);

    const c1 = Colour{ .r = 100, .g = 100, .b = 100 };
    const c2 = Colour{ .r = 150, .g = 150, .b = 150 };
    const c3 = Colour{ .r = 200, .g = 200, .b = 200 };

    try c1.writeNoReset(allocator, &output_writer, "A");
    try c2.writeNoReset(allocator, &output_writer, "B");
    try c3.writeNoReset(allocator, &output_writer, "C");
    try output_writer.writeAll(reset);

    const output = output_writer.buffered();
    const expected = "\x1b[38;2;100;100;100mA" ++ "\x1b[38;2;150;150;150mB" ++ "\x1b[38;2;200;200;200mC" ++ "\x1b[0m";

    try std.testing.expectEqualStrings(expected, output);
}

/// Reset colour to default
pub const reset = "\x1b[0m";

test "reset is correct" {
    try std.testing.expectEqualStrings("\x1b[0m", reset);
}

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

/// The Ren palette - default sophisticated palette
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

/// Gradient types for separator lines
pub const Gradient = union(enum) {
    solid: Colour,
    rainbow,
    two_colour: struct {
        start: Colour,
        end: Colour,
    },
    three_colour: struct {
        start: Colour,
        mid: Colour,
        end: Colour,
    },

    /// Get colour at position t (0.0 to 1.0)
    pub fn get(self: Gradient, t: f32) Colour {
        return switch (self) {
            .solid => |c| c,
            .rainbow => rainbow(t),
            .two_colour => |tc| interpolate(tc.start, tc.end, t),
            .three_colour => |tc| interpolateThree(tc.start, tc.mid, tc.end, t),
        };
    }
};

test "Gradient solid" {
    const grad = Gradient{ .solid = .{ .r = 100, .g = 150, .b = 200 } };
    const c = grad.get(0.5);
    try std.testing.expectEqual(100, c.r);
    try std.testing.expectEqual(150, c.g);
}

test "Gradient two_colour" {
    const grad = Gradient{ .two_colour = .{
        .start = .{ .r = 0, .g = 0, .b = 0 },
        .end = .{ .r = 100, .g = 100, .b = 100 },
    } };
    const mid = grad.get(0.5);
    try std.testing.expectEqual(50, mid.r);
}

/// Generate a smooth rainbow colour at position t (0.0 to 1.0)
/// Creates pastel rainbow: soft pink -> peach -> mint -> sky -> lavender
pub fn rainbow(t: f32) Colour {
    const clamped = @max(0.0, @min(1.0, t));

    // Smooth HSV to RGB conversion with pastel tones
    // Hue varies from 0 to 360 degrees
    const hue = clamped * 360.0;
    const saturation: f32 = 0.35; // Low saturation for pastel
    const value: f32 = 0.95; // High value for brightness

    return hsvToRgb(hue, saturation, value);
}

/// Convert HSV to RGB
fn hsvToRgb(h: f32, s: f32, v: f32) Colour {
    const c = v * s;
    const h_prime = h / 60.0;
    const x = c * (1.0 - @abs(@mod(h_prime, 2.0) - 1.0));
    const m = v - c;

    var r: f32 = 0;
    var g: f32 = 0;
    var b: f32 = 0;

    if (h_prime >= 0 and h_prime < 1) {
        r = c;
        g = x;
        b = 0;
    } else if (h_prime >= 1 and h_prime < 2) {
        r = x;
        g = c;
        b = 0;
    } else if (h_prime >= 2 and h_prime < 3) {
        r = 0;
        g = c;
        b = x;
    } else if (h_prime >= 3 and h_prime < 4) {
        r = 0;
        g = x;
        b = c;
    } else if (h_prime >= 4 and h_prime < 5) {
        r = x;
        g = 0;
        b = c;
    } else {
        r = c;
        g = 0;
        b = x;
    }

    return .{
        .r = @intFromFloat((r + m) * 255.0),
        .g = @intFromFloat((g + m) * 255.0),
        .b = @intFromFloat((b + m) * 255.0),
    };
}

/// Linear interpolation between two colours
pub fn interpolate(start: Colour, end: Colour, t: f32) Colour {
    const clamped = @max(0.0, @min(1.0, t));

    const r = @as(f32, @floatFromInt(start.r)) * (1.0 - clamped) + @as(f32, @floatFromInt(end.r)) * clamped;
    const g = @as(f32, @floatFromInt(start.g)) * (1.0 - clamped) + @as(f32, @floatFromInt(end.g)) * clamped;
    const b = @as(f32, @floatFromInt(start.b)) * (1.0 - clamped) + @as(f32, @floatFromInt(end.b)) * clamped;

    return .{
        .r = @intFromFloat(r),
        .g = @intFromFloat(g),
        .b = @intFromFloat(b),
    };
}

test "interpolate at endpoints" {
    const start = Colour{ .r = 0, .g = 0, .b = 0 };
    const end = Colour{ .r = 100, .g = 100, .b = 100 };

    const at_start = interpolate(start, end, 0.0);
    try std.testing.expectEqual(0, at_start.r);

    const at_end = interpolate(start, end, 1.0);
    try std.testing.expectEqual(100, at_end.r);

    const at_mid = interpolate(start, end, 0.5);
    try std.testing.expectEqual(50, at_mid.r);
}

/// Linear interpolation across three colours
pub fn interpolateThree(start: Colour, mid: Colour, end: Colour, t: f32) Colour {
    const clamped = @max(0.0, @min(1.0, t));

    if (clamped < 0.5) {
        // First half: start to mid
        return interpolate(start, mid, clamped * 2.0);
    } else {
        // Second half: mid to end
        return interpolate(mid, end, (clamped - 0.5) * 2.0);
    }
}

test "interpolateThree transitions correctly" {
    const start = Colour{ .r = 0, .g = 0, .b = 0 };
    const mid = Colour{ .r = 100, .g = 100, .b = 100 };
    const end = Colour{ .r = 200, .g = 200, .b = 200 };

    const at_start = interpolateThree(start, mid, end, 0.0);
    try std.testing.expectEqual(0, at_start.r);

    const at_mid = interpolateThree(start, mid, end, 0.5);
    try std.testing.expectEqual(100, at_mid.r);

    const at_end = interpolateThree(start, mid, end, 1.0);
    try std.testing.expectEqual(200, at_end.r);
}

test "rainbow generates pastel colours" {
    const start = rainbow(0.0); // Should be pinkish
    const mid = rainbow(0.5); // Should be cyan/blue-ish

    // All should be pastel (relatively high RGB values)
    try std.testing.expect(start.r > 180 or start.g > 180 or start.b > 180);
    try std.testing.expect(mid.r > 180 or mid.g > 180 or mid.b > 180);
}

test "rainbow clamping" {
    const below = rainbow(-0.5);
    const above = rainbow(1.5);

    // Should clamp to valid range
    _ = below;
    _ = above;
}
