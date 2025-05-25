pub const Entity = @import("entity.zig").Entity;
pub const EntityManager = @import("manager.zig").EntityManager;

const comps = @import("components.zig");
pub const TransformComp = comps.TransformComp;

const storage = @import("compStorage.zig");
pub const TransformCompStorage = storage.TransformCompStorage;

// MARK: Types
pub const ComponentTag = enum {
    Transform,
};
pub const ComponentType = union(ComponentTag) {
    Transform: TransformComp,
};
