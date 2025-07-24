const std = @import("std");

pub const V2 = @import("math").V2;

const rend = @import("renderer");
pub const Color = rend.Color;
pub const Polygon = rend.Polygon;
pub const Renderer = rend.Renderer;
pub const ShapeData = rend.ShapeData;
pub const Transform = rend.Transform;

pub const EntityHandle = @import("entityHandle.zig").EntityHandle;

pub const Entity = @import("entity.zig").Entity;

pub const EntityManager = @import("ecsManager.zig").EntityManager;

const comp = @import("components.zig");
pub const ComponentTag = comp.ComponentTag;
pub const ComponentType = comp.ComponentType;
pub const ControlComp = comp.ControlComp;
pub const PlayerComp = comp.PlayerComp;
pub const RenderComp = comp.RenderComp;
pub const TextComp = comp.TextComp;
pub const TransformComp = comp.TransformComp;
pub const VelocityComp = comp.VelocityComp;

const config = @import("entityConfig.zig");
pub const ControllableConfig = config.ControllableConfig;
pub const ShapeConfig = config.ShapeConfigs;
pub const CircleConfig = config.CircleConfig;
pub const LineConfig = config.LineConfig;
pub const EllipseConfig = config.EllipseConfig;
pub const RectangleConfig = config.RectangleConfig;
pub const TriangleConfig = config.TriangleConfig;
pub const PolygonConfig = config.PolygonConfig;

const store = @import("compStorage.zig");
pub const VelocityCompStorage = store.VelocityCompStorage;
pub const RenderCompStorage = store.RenderCompStorage;
pub const TransformCompStorage = store.TransformCompStorage;
pub const ControlCompStorage = store.ControlCompStorage;
pub const PlayerCompStorage = store.PlayerCompStorage;
