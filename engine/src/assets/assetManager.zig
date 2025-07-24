const std = @import("std");

const asset = @import("assets.zig");
const FontManager = asset.FontManager;
const Font = asset.Font;

pub const AssetManager = struct {
    allocator: std.mem.Allocator,
    fonts: std.StringHashMap(Font),
    fontPath: []const u8 = undefined,

    pub fn setFontPath(self: *AssetManager, path: []const u8) void {
        self.fontPath = path;
    }

    pub fn loadFont(self: *AssetManager, name: []const u8) !Font {
        const fullPath = try std.fmt.allocPrint(self.allocator, "{s}/{s}", .{ self.fontPath, name });
        defer self.allocator.free(fullPath);

        std.debug.print("{s}\n", .{fullPath});

        var font = try Font.init(self.allocator, fullPath);
        errdefer font.deinit();
        try self.fonts.put(name, font);

        return font;
    }

    pub fn init(alloc: std.mem.Allocator) !AssetManager {
        return AssetManager{
            .allocator = alloc,
            .fonts = std.StringHashMap(Font).init(alloc),
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
