const std = @import("std");

const asset = @import("assets.zig");
const FontManager = asset.FontManager;
const Font = asset.Font;

pub const AssetManager = struct {
    allocator: *std.mem.Allocator,
    fonts: std.StringHashMap(Font),

    pub fn loadFont(self: *AssetManager, name: []const u8, path: []const u8) !Font {
        var font = try Font.init(self.allocator, path);
        errdefer font.deinit();

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
        var iter = self.fonts.iterator();
        while (iter.next()) |font| {
            font.value_ptr.*.deinit();
        }
        self.fonts.deinit();
    }
};
