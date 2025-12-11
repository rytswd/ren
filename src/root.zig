//! Ren (練) - A sophisticated terminal rendering library for Zig
//!
//! Embodies the principle of 洗練 (senren) - refinement and sophistication.
//! Simple, small, sophisticated.

const std = @import("std");

// Version information
pub const version = std.SemanticVersion{
    .major = 0,
    .minor = 1,
    .patch = 0,
};

// Modules
pub const colour = @import("colour.zig");
pub const terminal = @import("terminal.zig");
pub const unicode = @import("unicode.zig");
pub const block = @import("block.zig");
pub const render = @import("render.zig");
pub const header = @import("header.zig");
pub const box = @import("box.zig");

test "version is defined" {
    try std.testing.expect(version.major == 0);
    try std.testing.expect(version.minor == 1);
    try std.testing.expect(version.patch == 0);
}

test {
    // Run all tests in submodules
    std.testing.refAllDecls(@This());
}
