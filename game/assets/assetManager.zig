const std = @import("std");

const types = @import("types.zig");
const FontManager = types.FontManager;
const Font = types.Font;

pub const AssetManager = struct {
    allocator: *std.mem.Allocator,
    fonts: std.StringHashMap(Font),

    pub fn loadFont(self: *AssetManager, name: []const u8, path: []const u8) !Font {
        const font = try Font.init(self.allocator, path);
        // errdefer font.deinit();

        try self.fonts.put(name, font);
        return font;
    }

    pub fn init(alloc: *std.mem.Allocator) !AssetManager {
        return AssetManager{
            .allocator = alloc,
            .fonts = std.StringHashMap(Font).init(alloc.*),
        };
    }

    pub fn deinit(self: *AssetManager) void {
        self.fonts.deinit();
    }
};
