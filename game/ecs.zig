const types = @import("ecs/types.zig");

pub const Entity = types.Entity;
pub const EntityHandle = type.EntityHandle;
pub const ComponentTag = types.ComponentTag;
pub const ComponentType = types.ComponentType;
pub const EntityManager = types.EntityManager;
pub const TransformComp = types.TransformComp;
pub const RenderComp = types.RenderComp;

pub const InputCommand = types.InputCommand;
pub const Command = types.Command;
pub const EntityCommand = types.EntityCommand;
pub const InputWrapper = types.InputWrapper;
