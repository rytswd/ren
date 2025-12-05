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

    // TODO: Add fallback conversion methods for terminal compatibility
    // pub fn to256Colour(self: Colour) u8 { }
    // pub fn to16Colour(self: Colour) u8 { }
};

/// Reset colour to default
pub const reset = "\x1b[0m";

/// Default sophisticated colour palette
pub const Palette = struct {
    /// Refined green for completed states
    pub const refined_green = Colour{ .r = 120, .g = 200, .b = 140 };

    /// Warm amber for current/active states
    pub const warm_amber = Colour{ .r = 230, .g = 180, .b = 100 };

    /// Subtle grey for upcoming/inactive elements
    pub const subtle_grey = Colour{ .r = 160, .g = 160, .b = 165 };

    /// Dim grey for separators and secondary elements
    pub const dim_grey = Colour{ .r = 140, .g = 140, .b = 145 };
};

test "Colour toAnsi conversion" {
    const allocator = std.testing.allocator;
    const colour = Colour{ .r = 255, .g = 128, .b = 64 };
    const ansi = try colour.toAnsi(allocator);
    defer allocator.free(ansi);

    try std.testing.expectEqualStrings("\x1b[38;2;255;128;64m", ansi);
}

test "Palette colours can be converted to ANSI" {
    const allocator = std.testing.allocator;

    const green_ansi = try Palette.refined_green.toAnsi(allocator);
    defer allocator.free(green_ansi);

    const amber_ansi = try Palette.warm_amber.toAnsi(allocator);
    defer allocator.free(amber_ansi);

    // Verify they produce valid escape codes
    try std.testing.expect(std.mem.startsWith(u8, green_ansi, "\x1b[38;2;"));
    try std.testing.expect(std.mem.startsWith(u8, amber_ansi, "\x1b[38;2;"));
}

test "reset is correct" {
    try std.testing.expectEqualStrings("\x1b[0m", reset);
}
