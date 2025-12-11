//! Unicode utilities
//!
//! Provides display width calculation for proper text alignment.

const std = @import("std");

/// Calculate display width of a UTF-8 string
/// Accounts for different character widths:
/// - ASCII: 1 column
/// - East Asian Wide: 2 columns
/// - Combining marks: 0 columns
/// - Most other characters: 1 column
/// - ANSI escape sequences: 0 columns (skipped)
pub fn displayWidth(text: []const u8) usize {
    var width: usize = 0;
    var i: usize = 0;

    while (i < text.len) {
        // Skip ANSI escape sequences
        if (i + 1 < text.len and text[i] == '\x1b' and text[i + 1] == '[') {
            // Find the end of the escape sequence (ends with a letter)
            i += 2;
            while (i < text.len) : (i += 1) {
                const c = text[i];
                // ANSI sequences end with a letter (A-Z, a-z)
                if ((c >= 'A' and c <= 'Z') or (c >= 'a' and c <= 'z')) {
                    i += 1;
                    break;
                }
            }
            continue;
        }

        // Regular UTF-8 character
        const cp_len = std.unicode.utf8ByteSequenceLength(text[i]) catch 1;
        if (i + cp_len <= text.len) {
            const codepoint = std.unicode.utf8Decode(text[i .. i + cp_len]) catch {
                i += 1;
                continue;
            };
            width += codepointWidth(codepoint);
            i += cp_len;
        } else {
            i += 1;
        }
    }

    return width;
}

/// Get display width of a single codepoint
fn codepointWidth(codepoint: u21) usize {
    // ASCII printable characters
    if (codepoint >= 0x20 and codepoint < 0x7F) {
        return 1;
    }

    // Control characters
    if (codepoint < 0x20 or (codepoint >= 0x7F and codepoint < 0xA0)) {
        return 0;
    }

    // TODO: Implement proper East Asian Width detection
    // For now, simple heuristic:
    // - CJK Unified Ideographs: U+4E00-U+9FFF
    // - Hangul: U+AC00-U+D7AF
    // - Full-width forms: U+FF00-U+FFEF
    if ((codepoint >= 0x4E00 and codepoint <= 0x9FFF) or
        (codepoint >= 0xAC00 and codepoint <= 0xD7AF) or
        (codepoint >= 0xFF00 and codepoint <= 0xFFEF))
    {
        return 2;
    }

    // Default: 1 column
    return 1;
}

test "displayWidth for ASCII" {
    try std.testing.expectEqual(5, displayWidth("Hello"));
    try std.testing.expectEqual(13, displayWidth("Hello, World!"));
}

test "displayWidth for box-drawing characters" {
    try std.testing.expectEqual(1, displayWidth("─"));
    try std.testing.expectEqual(1, displayWidth("│"));
    try std.testing.expectEqual(1, displayWidth("⚝"));
}

test "displayWidth for multi-byte ASCII markers" {
    try std.testing.expectEqual(3, displayWidth(">>>"));
    try std.testing.expectEqual(2, displayWidth(">>"));
}

test "codepointWidth for common characters" {
    try std.testing.expectEqual(1, codepointWidth('A'));
    try std.testing.expectEqual(1, codepointWidth(' '));
    try std.testing.expectEqual(0, codepointWidth('\n'));
}

test "displayWidth for CJK characters" {
    // 練 (ren) from 洗練
    try std.testing.expectEqual(2, displayWidth("練"));
    // 洗練 (senren)
    try std.testing.expectEqual(4, displayWidth("洗練"));
    // Mixed: ren (練) = r(1) + e(1) + n(1) + space(1) + ((1) + 練(2) + )(1) = 8
    try std.testing.expectEqual(8, displayWidth("ren (練)"));
}

test "displayWidth for various markers" {
    try std.testing.expectEqual(1, displayWidth("⚝"));  // star
    try std.testing.expectEqual(1, displayWidth("❯"));  // right arrow
    try std.testing.expectEqual(1, displayWidth("●"));  // filled circle
    try std.testing.expectEqual(1, displayWidth("○"));  // empty circle
    try std.testing.expectEqual(1, displayWidth("◉"));  // fisheye
}

test "displayWidth ignores ANSI colour codes" {
    // Plain text
    try std.testing.expectEqual(5, displayWidth("Hello"));

    // With ANSI colour (should still be 5)
    try std.testing.expectEqual(5, displayWidth("\x1b[38;2;255;0;0mHello\x1b[0m"));

    // Multiple colours (Hello + space + World = 5 + 1 + 5 = 11)
    try std.testing.expectEqual(11, displayWidth("\x1b[31mHello\x1b[0m \x1b[32mWorld\x1b[0m"));

    // ANSI in middle of text
    try std.testing.expectEqual(3, displayWidth("A\x1b[1mB\x1b[0mC"));
}
