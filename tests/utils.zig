const std = @import("std");
const testing = std.testing;

const ecs = @import("ecs");
const Entity = ecs.Entity;
const EntityManager = ecs.EntityManager;

pub fn createTestAllocator() std.mem.Allocator {
    return std.testing.allocator;
}

pub fn printTestSection(comptime sectionName: []const u8) void {
    std.debug.print("\n=== {s} ===\n", .{sectionName});
}

pub fn expectEntityValid(
    entityID: usize,
    generation: u16,
    expectedID: usize,
    expectedGen: u16,
) !void {
    try testing.expect(entityID == expectedID);
    try testing.expect(generation == expectedGen);
}

pub fn expectLengthEqual(actual: usize, expected: usize, context: []const u8) !void {
    if (actual != expected) {
        std.debug.print("Length mismatch in {s}: expected {d}, got {d}\n", .{ context, expected, actual });
        return error.LengthMismatch;
    }
}

pub fn createTestEntities(manager: anytype, count: usize, allocator: std.mem.Allocator) ![]Entity {
    var entities = try allocator.alloc(Entity, count);
    for (0..count) |i| {
        entities[i] = try manager.createEntity();
    }
    return entities;
}

pub fn destroyTestEntities(manager: anytype, entities: []Entity) void {
    for (entities) |entity| {
        manager.destroyEntity(entity) catch {};
    }
}

pub const TestConfig = struct {
    pub const STRESS_TEST_ENTITY_COUNT = 100;
    pub const BATCH_TEST_ENTITY_COUNT = 5;
    pub const RENDER_TEST_WIDTH = 800;
    pub const RENDER_TEST_HEIGHT = 600;
};
