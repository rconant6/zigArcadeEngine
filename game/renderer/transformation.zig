const rTypes = @import("types.zig");

const Point = rTypes.GamePoint;
const Renderer = rTypes.Renderer;
const ScreenPoint = rTypes.ScreenPoint;

pub fn gameToScreen(renderer: *const Renderer, p: Point) ScreenPoint {
    const x: i32 = @intFromFloat((p.x + 1.0) * 0.5 * renderer.fw);
    const y: i32 = @intFromFloat((1.0 - p.y) * 0.5 * renderer.fh);

    return ScreenPoint.init(x, y);
}

pub fn screenToGame(renderer: *const Renderer, sp: ScreenPoint) Point {
    const fw: f32 = @floatFromInt(renderer.width);
    const fh: f32 = @floatFromInt(renderer.height);
    return Point{
        .x = (@as(f32, @floatFromInt(sp.x)) * 2.0 / fw) - 1.0,
        .y = 1.0 - (@as(f32, @floatFromInt(sp.y)) * 2.0 / fh),
    };
}
