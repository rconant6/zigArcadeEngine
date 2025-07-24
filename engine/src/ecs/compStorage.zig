const std = @import("std");

const ecs = @import("ecs.zig");
const ComponentType = ecs.ComponentType;
const ControlComp = ecs.ControlComp;
const PlayerComp = ecs.PlayerComp;
const RenderComp = ecs.RenderComp;
const TransformComp = ecs.TransformComp;
const VelocityComp = ecs.VelocityComp;

// TODO: make the generic?
pub const VelocityCompStorage = struct {
    data: std.ArrayList(VelocityComp),
    entityToIndex: std.AutoHashMap(usize, usize),
    indexToEntity: std.ArrayList(usize),

    pub fn init(alloc: std.mem.Allocator) !VelocityCompStorage {
        return .{
            .data = std.ArrayList(VelocityComp).init(alloc),
            .entityToIndex = std.AutoHashMap(usize, usize).init(alloc),
            .indexToEntity = std.ArrayList(usize).init(alloc),
        };
    }

    pub fn deinit(self: *VelocityCompStorage) void {
        self.data.deinit();
        self.indexToEntity.deinit();
        self.entityToIndex.deinit();
    }
};

pub const PlayerCompStorage = struct {
    data: std.ArrayList(PlayerComp),
    entityToIndex: std.AutoHashMap(usize, usize),
    indexToEntity: std.ArrayList(usize),

    pub fn init(alloc: std.mem.Allocator) !PlayerCompStorage {
        return .{
            .data = std.ArrayList(PlayerComp).init(alloc),
            .entityToIndex = std.AutoHashMap(usize, usize).init(alloc),
            .indexToEntity = std.ArrayList(usize).init(alloc),
        };
    }

    pub fn deinit(self: *PlayerCompStorage) void {
        self.data.deinit();
        self.indexToEntity.deinit();
        self.entityToIndex.deinit();
    }
};

pub const ControlCompStorage = struct {
    data: std.ArrayList(ControlComp),
    entityToIndex: std.AutoHashMap(usize, usize),
    indexToEntity: std.ArrayList(usize),

    pub fn init(alloc: std.mem.Allocator) !ControlCompStorage {
        return .{
            .data = std.ArrayList(ControlComp).init(alloc),
            .entityToIndex = std.AutoHashMap(usize, usize).init(alloc),
            .indexToEntity = std.ArrayList(usize).init(alloc),
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

    pub fn init(alloc: std.mem.Allocator) !TransformCompStorage {
        return .{
            .data = std.ArrayList(TransformComp).init(alloc),
            .entityToIndex = std.AutoHashMap(usize, usize).init(alloc),
            .indexToEntity = std.ArrayList(usize).init(alloc),
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

    pub fn init(alloc: std.mem.Allocator) !RenderCompStorage {
        return .{
            .data = std.ArrayList(RenderComp).init(alloc),
            .entityToIndex = std.AutoHashMap(usize, usize).init(alloc),
            .indexToEntity = std.ArrayList(usize).init(alloc),
        };
    }

    pub fn deinit(self: *RenderCompStorage) void {
        for (self.data.items) |renderComp| {
            switch (renderComp.shapeData) {
                .Polygon => |p| self.data.allocator.free(p.vertices),
                else => {},
            }
        }
        self.data.deinit();
        self.indexToEntity.deinit();
        self.entityToIndex.deinit();
    }
};
