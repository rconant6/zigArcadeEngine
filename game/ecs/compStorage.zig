const std = @import("std");
const types = @import("types.zig");

const ComponentType = types.ComponentType;
const ControlComp = types.ControlComp;
const RenderComp = types.RenderComp;
const TransformComp = types.TransformComp;

pub const ControlCompStorage = struct {
    data: std.ArrayList(ControlComp),
    entityToIndex: std.AutoHashMap(usize, usize),
    indexToEntity: std.ArrayList(usize),

    pub fn init(alloc: *std.mem.Allocator) !ControlCompStorage {
        return .{
            .data = std.ArrayList(ControlComp).init(alloc.*),
            .entityToIndex = std.AutoHashMap(usize, usize).init(alloc.*),
            .indexToEntity = std.ArrayList(usize).init(alloc.*),
        };
    }

    pub fn deinit(self: *ControlCompStorage) void {
        self.data.deinit();
        self.indexToEntity.deinit();
        self.entityToIndex.deinit();
    }
};

pub const TransformCompStorage = struct {
    data: std.ArrayList(TransformComp),
    entityToIndex: std.AutoHashMap(usize, usize),
    indexToEntity: std.ArrayList(usize),

    pub fn init(alloc: *std.mem.Allocator) !TransformCompStorage {
        return .{
            .data = std.ArrayList(TransformComp).init(alloc.*),
            .entityToIndex = std.AutoHashMap(usize, usize).init(alloc.*),
            .indexToEntity = std.ArrayList(usize).init(alloc.*),
        };
    }

    pub fn deinit(self: *TransformCompStorage) void {
        self.data.deinit();
        self.indexToEntity.deinit();
        self.entityToIndex.deinit();
    }
};

pub const RenderCompStorage = struct {
    data: std.ArrayList(RenderComp),
    entityToIndex: std.AutoHashMap(usize, usize),
    indexToEntity: std.ArrayList(usize),

    pub fn init(alloc: *std.mem.Allocator) !RenderCompStorage {
        return .{
            .data = std.ArrayList(RenderComp).init(alloc.*),
            .entityToIndex = std.AutoHashMap(usize, usize).init(alloc.*),
            .indexToEntity = std.ArrayList(usize).init(alloc.*),
        };
    }

    pub fn deinit(self: *RenderCompStorage) void {
        self.data.deinit();
        self.indexToEntity.deinit();
        self.entityToIndex.deinit();
    }
};
