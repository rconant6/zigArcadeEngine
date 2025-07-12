const std = @import("std");
const rTypes = @import("types.zig");

const Point = rTypes.GamePoint;
const Color = rTypes.Color;

/// Represents a line segment between two points in game space.
///
/// Lines are defined by their start and end points, each using the game space
/// coordinate system (-1,1).
///
/// Example:
///     const horizontalLine = Line{
///         .start = Point{ .x = -1, .y = 0 },
///         .end = Point{ .x = 1, .y = 0 },
///     };
pub const Line = struct {
    start: Point,
    end: Point,
    color: ?Color = null,
};

/// Represents a triangle defined by three vertices in game space.
///
/// The vertices are automatically sorted by y-coordinate to facilitate
/// rendering. This makes drawing filled triangles more efficient.
///
/// Example:
///     var points = [_]Point{
///         Point{ .x = 0, .y = 0.5 },     // Top vertex
///         Point{ .x = -0.5, .y = -0.5 }, // Bottom-left vertex
///         Point{ .x = 0.5, .y = -0.5 },  // Bottom-right vertex
///     };
///     const triangle = Triangle.init(&points);
pub const Triangle = struct {
    vertices: [3]Point,
    outlineColor: ?Color = null,
    fillColor: ?Color = null,

    /// Points are sorted from top to bottm via y, and then left to right via x for rendering
    pub fn init(points: []Point) Triangle {
        std.mem.sort(Point, points, {}, sortPointByYThenX);
        return .{
            .vertices = points,
        };
    }
};

/// Represents a rectangle in game space.
///
/// Rectangles are defined by a center point and half-dimensions, making it
/// easy to perform transformations and collision checks. The coordinate system
/// uses the (-1,1) range for both axes.
///
/// Example:
///     // Create a square centered at origin with width and height of 0.5
///     const square = Rectangle.initSquare(Point{ .x = 0, .y = 0 }, 0.5);
///
///     // Create a rectangle centered at (0.2, 0.3) with width 0.4 and height 0.6
///     const rect = Rectangle.initFromCenter(Point{ .x = 0.2, .y = 0.3 }, 0.4, 0.6);
pub const Rectangle = struct {
    center: Point,
    halfWidth: f32,
    halfHeight: f32,
    outlineColor: ?Color = null,
    fillColor: ?Color = null,

    pub fn initSquare(center: Point, size: f32) Rectangle {
        return .{
            .center = center,
            .halfWidth = size * 0.5,
            .halfHeight = size * 0.5,
        };
    }

    pub fn initFromCenter(center: Point, width: f32, height: f32) Rectangle {
        return .{
            .center = center,
            .halfWidth = width * 0.5,
            .halfHeight = height * 0.5,
        };
    }

    pub fn initFromTopLeft(topLeft: Point, width: f32, height: f32) Rectangle {
        return .{
            .center = .{
                .x = topLeft.x + width * 0.5,
                .y = topLeft.y + height * 0.5,
            },
            .halfWidth = width,
            .halfHeight = height,
        };
    }

    pub fn getWidth(self: Rectangle) f32 {
        return self.halfWidth * 2;
    }

    pub fn getHeight(self: Rectangle) f32 {
        return self.halfHeight * 2;
    }

    /// Returns the points corners of a Rectangle [topLeft, topRight, bottomRight, bottomLeft]
    pub fn getCorners(self: *const Rectangle) [4]Point {
        const topLeft: Point = .{ .x = self.center.x - self.halfWidth, .y = self.center.y + self.halfHeight };
        const topRight: Point = .{ .x = self.center.x + self.halfWidth, .y = self.center.y + self.halfHeight };
        const bottomRight: Point = .{ .x = self.center.x + self.halfWidth, .y = self.center.y - self.halfHeight };
        const bottomLeft: Point = .{ .x = self.center.x - self.halfWidth, .y = self.center.y - self.halfHeight };
        return .{ topLeft, topRight, bottomRight, bottomLeft };
    }
};

/// Represents a polygon with any number of vertices in game space.
///
/// Polygons are defined by an array of vertices and maintain a calculated
/// center point. The vertices are automatically sorted in clockwise order
/// around the centroid for proper rendering.
///
/// Example:
///     // Create a pentagon
///     var points = [_]Point{
///         Point{ .x = 0.0, .y = 0.5 },
///         Point{ .x = 0.4, .y = 0.2 },
///         Point{ .x = 0.3, .y = -0.3 },
///         Point{ .x = -0.3, .y = -0.3 },
///         Point{ .x = -0.4, .y = 0.2 },
///     };
///     const pentagon = Polygon.init(&points);
pub const Polygon = struct {
    vertices: []const Point,
    center: Point,
    outlineColor: ?Color = null,
    fillColor: ?Color = null,

    /// Creates a new Polygon with the given points.
    ///
    /// The center (centroid) is automatically calculated, and the vertices
    /// are sorted in clockwise order around this center.
    pub fn init(alloc: std.mem.Allocator, points: []const Point) !Polygon {
        const center = calculateCentroid(points);
        const newPoints = try alloc.dupe(Point, points);
        const sortContext = PolygonSortContext{ .centroid = center };
        std.mem.sort(Point, newPoints, sortContext, sortPointsClockwise);

        return .{
            .center = center,
            .vertices = newPoints,
            .outlineColor = null,
            .fillColor = null,
        };
    }
};

/// Represents a circle in game space.
///
/// Circles are defined by an origin point and a radius. Coordinates
/// use the (-1,1) range for both axes.
///
/// Example:
///     // Create a circle at the center of the screen with radius 0.5
///     const circle = Circle{
///         .origin = Point{ .x = 0, .y = 0 },
///         .radius = 0.5,
///     };
pub const Circle = struct {
    origin: Point,
    radius: f32,
    outlineColor: ?Color = null,
    fillColor: ?Color = null,
};

pub const Ellipse = struct {
    origin: Point,
    semiMinor: f32,
    semiMajor: f32,
    outlineColor: ?Color = null,
    fillColor: ?Color = null,
};

fn sortPointByX(context: void, a: Point, b: Point) bool {
    _ = context;
    return a.x > b.x;
}

fn sortPointByY(context: void, a: Point, b: Point) bool {
    _ = context;
    return a.y > b.y;
}

fn sortPointByYThenX(context: void, a: Point, b: Point) bool {
    _ = context;
    if (a.y == b.y) {
        return a.x < b.x;
    }
    return a.y > b.y;
}

fn calculateCentroid(points: []const Point) Point {
    if (points.len == 0) return Point{ .x = 0, .y = 0 };

    var sumX: f32 = 0;
    var sumY: f32 = 0;

    for (points) |p| {
        sumX += p.x;
        sumY += p.y;
    }

    const flen: f32 = @floatFromInt(points.len);

    return Point{
        .x = sumX / flen,
        .y = sumY / flen,
    };
}

const PolygonSortContext = struct {
    centroid: Point,
};

fn sortPointsClockwise(context: PolygonSortContext, a: Point, b: Point) bool {
    const center = context.centroid;

    const angleA = std.math.atan2(a.y - center.y, a.x - center.x);
    const angleB = std.math.atan2(b.y - center.y, b.x - center.x);

    return angleA > angleB;
}
