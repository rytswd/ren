//! Terminal utilities
//!
//! Provides terminal capability detection and information.

const std = @import("std");
const posix = std.posix;

/// Detect terminal width in columns
/// Returns null if detection fails
pub fn detectWidth() ?usize {
    if (@import("builtin").os.tag == .windows) {
        // TODO: Windows Console API implementation
        return null;
    } else {
        // POSIX: use ioctl TIOCGWINSZ
        return detectWidthPosix();
    }
}

fn detectWidthPosix() ?usize {
    const fd = std.fs.File.stdout().handle;

    var ws: posix.winsize = .{
        .row = 0,
        .col = 0,
        .xpixel = 0,
        .ypixel = 0,
    };

    const err = posix.system.ioctl(fd, posix.T.IOCGWINSZ, @intFromPtr(&ws));
    if (posix.errno(err) != .SUCCESS) {
        // Not a TTY (pipes, redirects, non-terminal environments) - use fallback
        return null;
    }

    return if (ws.col > 0) ws.col else null;
}

test "detectWidth with /dev/tty" {
    // Try to open /dev/tty directly for more reliable testing
    const tty = std.fs.openFileAbsolute("/dev/tty", .{}) catch {
        // No TTY available in test environment - skip
        return error.SkipZigTest;
    };
    defer tty.close();

    var ws: posix.winsize = .{
        .row = 0,
        .col = 0,
        .xpixel = 0,
        .ypixel = 0,
    };

    const err = posix.system.ioctl(tty.handle, posix.T.IOCGWINSZ, @intFromPtr(&ws));

    // If we successfully opened /dev/tty, ioctl should work
    try std.testing.expectEqual(posix.E.SUCCESS, posix.errno(err));

    // Verify we got valid dimensions
    try std.testing.expect(ws.col > 0);
    try std.testing.expect(ws.row > 0);
}
