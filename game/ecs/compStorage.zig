const std = @import("std");
const types = @import("types.zig");

const ComponentType = types.ComponentType;
const TransformComp = types.TransformComp;

// MARK: Transform
pub const TransformCompStorage = struct {
    transforms: std.ArrayList(TransformComp),
    entityToIndex: std.AutoHashMap(usize, usize),
    indexToEntity: std.ArrayList(usize),

    pub fn init(alloc: *std.mem.Allocator) !TransformCompStorage {
        std.debug.print("[ECS] - transformStorage.init()\n", .{});
        return .{
            .transforms = std.ArrayList(TransformComp).init(alloc.*),
            .entityToIndex = std.AutoHashMap(usize, usize).init(alloc.*),
            .indexToEntity = std.ArrayList(usize).init(alloc.*),
        };
    }

    pub fn deinit(self: *TransformCompStorage) void {
        self.transforms.deinit();
        self.indexToEntity.deinit();
        self.entityToIndex.deinit();
        std.debug.print("[ECS] - transformStorage.deinit()\n", .{});
    }
};
