pub const rend = @import("renderer");
pub const Entity = @import("entity.zig").Entity;
pub const EntityConfig = @import("entityConfig.zig");
pub const EntityHandle = @import("entityHandle.zig").EntityHandle;
pub const EntityManager = @import("manager.zig").EntityManager;

const comps = @import("components.zig");
pub const TransformComp = comps.TransformComp;
pub const RenderComp = comps.RenderComp;

const storage = @import("compStorage.zig");
pub const TransformCompStorage = storage.TransformCompStorage;
pub const RenderCompStorage = storage.RenderCompStorage;

// MARK: Types
pub const ComponentTag = enum {
    Transform,
    Render,
};

pub const ComponentType = union(ComponentTag) {
    Transform: TransformComp,
    Render: RenderComp,
};
