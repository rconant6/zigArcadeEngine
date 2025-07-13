const std = @import("std");

const math = @import("math");
pub const GamePoint = math.V2;
pub const ScreenPoint = math.V2I;

const color = @import("color.zig");
pub const Color = color.Color;
pub const Colors = color.Colors;

const prim = @import("primitives.zig");
pub const Circle = prim.Circle;
pub const Line = prim.Line;
pub const Polygon = prim.Polygon;
pub const Rectangle = prim.Rectangle;
pub const Triangle = prim.Triangle;

const core = @import("core.zig");
pub const Renderer = core.Renderer;

const trans = @import("transformation.zig");
const gameToScreen = trans.gameToScreen;
const screenToGame = trans.screenToGame;

const fb = @import("frameBuffer.zig");
pub const FrameBuffer = fb.FrameBuffer;
