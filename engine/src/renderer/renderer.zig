const std = @import("std");

const math = @import("math");
pub const GamePoint = math.V2;
pub const ScreenPoint = math.V2I;

const color = @import("color.zig");
pub const Color = color.Color;
pub const Colors = color.Colors;

const prim = @import("primitives.zig");
pub const Circle = prim.Circle;
pub const Ellipse = prim.Ellipse;
pub const Line = prim.Line;
pub const Polygon = prim.Polygon;
pub const Rectangle = prim.Rectangle;
pub const Triangle = prim.Triangle;

const core = @import("core.zig");
pub const Renderer = core.Renderer;
pub const ShapeData = core.ShapeData;
pub const Transform = core.Transform;

const trans = @import("transformation.zig");
pub const gameToScreen = trans.gameToScreen;
pub const screenToGame = trans.screenToGame;

const fb = @import("frameBuffer.zig");
pub const FrameBuffer = fb.FrameBuffer;
