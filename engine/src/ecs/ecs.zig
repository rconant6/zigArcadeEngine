const std = @import("std");

const math = @import("math");
pub const V2 = math.V2;

const rend = @import("renderer");
pub const Color = rend.Color;
pub const Renderer = rend.Renderer;

pub const EntityHandle = @import("entityHandle.zig").EntityHandle;

pub const Entity = @import("entity.zig").Entity;

pub const EntityManager = @import("ecsManager.zig").EntityManager;

// TODO: refactor and move to the game / engine split
// const cmd = @import("commands.zig");
// pub const Command = cmd.Command;
// pub const EntityCommand = cmd.EntityCommand;
// pub const InputCommand = cmd.InputCommand;
// pub const InputWrapper = cmd.InputWrapper;

const comp = @import("components.zig");
pub const ControlComp = comp.ControlComp;
pub const PlayerComp = comp.PlayerComp;
pub const RenderComp = comp.RenderComp;
pub const TextComp = comp.TextComp;
pub const TransformComp = comp.TransformComp;
pub const VelocityComp = comp.VelocityComp;

const store = @import("compStorage.zig");
pub const VelocityCompStorage = store.VelocityCompStorage;
pub const RenderCompStorage = store.RenderCompStorage;
pub const TransformCompStorage = store.TransformCompStorage;
pub const ControlCompStorage = store.ControlCompStorage;
pub const PlayerCompStorage = store.PlayerCompStorage;
