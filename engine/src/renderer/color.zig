const std = @import("std");

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,

    pub fn init(r: u8, g: u8, b: u8, a: u8) Color {
        return .{ .r = r, .g = g, .b = b, .a = a };
    }

    fn hexCharToInt(comptime c: u8) u8 {
        return switch (c) {
            '0'...'9' => c - '0',
            'a'...'f' => c - 'a' + 10,
            'A'...'F' => c - 'A' + 10,
            else => @compileError("Invalid hex character"),
        };
    }

    fn parseHexPair(comptime c1: u8, comptime c2: u8) u8 {
        return hexCharToInt(c1) * 16 + hexCharToInt(c2);
    }

    pub fn initFromHex(comptime str: []const u8) Color {
        const len = str.len;
        if ((len != 7 and len != 9) or str[0] != '#')
            @compileError("Invalid hex color format: expected #RRGGBB or #RRGGBBAA\n");

        return .{
            .r = parseHexPair(str[1], str[2]),
            .g = parseHexPair(str[3], str[4]),
            .b = parseHexPair(str[5], str[6]),
            .a = if (len == 9) parseHexPair(str[7], str[8]) else 255,
        };
    }
};

pub const Colors = struct {
    // BASIC COLORS
    pub const RED = Color.init(255, 0, 0, 255);
    pub const DARK_RED = Color.init(128, 0, 0, 255);
    pub const LIGHT_RED = Color.init(255, 179, 179, 255);
    pub const GREEN = Color.init(0, 255, 0, 255);
    pub const DARK_GREEN = Color.init(0, 128, 0, 255);
    pub const LIGHT_GREEN = Color.init(179, 255, 179, 255);
    pub const BLUE = Color.init(0, 0, 255, 255);
    pub const DARK_BLUE = Color.init(0, 0, 128, 255);
    pub const LIGHT_BLUE = Color.init(179, 179, 255, 255);
    pub const CYAN = Color.init(0, 255, 255, 255);
    pub const MAGENTA = Color.init(255, 0, 255, 255);
    pub const YELLOW = Color.init(255, 255, 0, 255);
    // EXTENDED COLORS
    pub const ORANGE = Color.init(255, 128, 0, 255);
    pub const DARK_ORANGE = Color.init(255, 77, 0, 255);
    pub const LIGHT_ORANGE = Color.init(255, 204, 153, 255);
    pub const PURPLE = Color.init(128, 0, 128, 255);
    pub const DARK_PURPLE = Color.init(77, 0, 77, 255);
    pub const LIGHT_PURPLE = Color.init(204, 153, 204, 255);
    pub const PINK = Color.init(255, 191, 204, 255);
    pub const BROWN = Color.init(153, 102, 51, 255);
    pub const LIME = Color.init(191, 255, 0, 255);
    // NON-COLORS
    pub const WHITE = Color.init(255, 255, 255, 255);
    pub const BLACK = Color.init(0, 0, 0, 255);
    pub const CLEAR = Color.init(0, 0, 0, 0);
    pub const LIGHT_GRAY = Color.init(191, 191, 191, 255);
    pub const GRAY = Color.init(128, 128, 128, 255);
    pub const DARK_GRAY = Color.init(64, 64, 64, 255);
    // NEONS
    pub const NEON_RED = Color.init(255, 26, 26, 255);
    pub const NEON_GREEN = Color.init(26, 255, 26, 255);
    pub const NEON_BLUE = Color.init(26, 26, 255, 255);
    pub const NEON_CYAN = Color.init(26, 255, 255, 255);
    pub const NEON_MAGENTA = Color.init(255, 26, 255, 255);
    pub const NEON_YELLOW = Color.init(255, 255, 26, 255);
    pub const NEON_ORANGE = Color.init(255, 102, 26, 255);
    pub const NEON_PURPLE = Color.init(204, 26, 255, 255);
    pub const NEON_PINK = Color.init(255, 26, 153, 255);
    // PASTELS
    pub const PASTEL_RED = Color.init(255, 204, 204, 255);
    pub const PASTEL_GREEN = Color.init(204, 255, 204, 255);
    pub const PASTEL_BLUE = Color.init(204, 204, 255, 255);
    pub const PASTEL_CYAN = Color.init(204, 255, 255, 255);
    pub const PASTEL_MAGENTA = Color.init(255, 204, 255, 255);
    pub const PASTEL_YELLOW = Color.init(255, 255, 204, 255);
    pub const PASTEL_ORANGE = Color.init(255, 230, 204, 255);
    pub const PASTEL_PURPLE = Color.init(230, 204, 255, 255);
    pub const PASTEL_PINK = Color.init(255, 204, 230, 255);
};
