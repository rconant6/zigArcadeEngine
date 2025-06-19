pub const rend = @import("renderer");
pub const Entity = @import("entity.zig").Entity;
pub const EntityConfig = @import("entityConfig.zig");
pub const EntityHandle = @import("entityHandle.zig").EntityHandle;
pub const EntityManager = @import("manager.zig").EntityManager;

const comps = @import("components.zig");
pub const ControlComp = comps.ControlComp;
pub const PlayerComp = comps.PlayerComp;
pub const RenderComp = comps.RenderComp;
pub const TransformComp = comps.TransformComp;

const storage = @import("compStorage.zig");
pub const ControlCompStorage = storage.ControlCompStorage;
pub const PlayerCompStorage = storage.PlayerCompStorage;
pub const RenderCompStorage = storage.RenderCompStorage;
pub const TransformCompStorage = storage.TransformCompStorage;

const command = @import("commands.zig");
pub const InputCommand = command.InputCommand;
pub const Command = command.Command;
pub const EntityCommand = command.EntityCommand;

// MARK: Types
pub const ComponentTag = enum {
    Control,
    Player,
    Render,
    Transform,
};

pub const ComponentType = union(ComponentTag) {
    Control: ControlComp,
    Player: PlayerComp,
    Render: RenderComp,
    Transform: TransformComp,
};
