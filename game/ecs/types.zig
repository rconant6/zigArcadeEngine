pub const rend = @import("renderer");
pub const Entity = @import("entity.zig").Entity;
pub const EntityConfig = @import("entityConfig.zig");
pub const EntityHandle = @import("entityHandle.zig").EntityHandle;
pub const EntityManager = @import("manager.zig").EntityManager;

const comps = @import("components.zig");
pub const ControlComp = comps.ControlComp;
pub const RenderComp = comps.RenderComp;
pub const TransformComp = comps.TransformComp;

const storage = @import("compStorage.zig");
pub const TransformCompStorage = storage.TransformCompStorage;
pub const RenderCompStorage = storage.RenderCompStorage;
pub const ControlCompStorage = storage.ControlCompStorage;

// MARK: Types
pub const ComponentTag = enum {
    Transform,
    Render,
    Control,
};

pub const ComponentType = union(ComponentTag) {
    Transform: TransformComp,
    Render: RenderComp,
    Control: ControlComp,
};
