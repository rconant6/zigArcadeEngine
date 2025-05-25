const std = @import("std");
const testing = std.testing;
const test_utils = @import("utils.zig");

// Import your ECS types
const ecs = @import("ecs");
const Entity = ecs.Entity;
const EntityManager = ecs.EntityManager;
const ComponentType = ecs.ComponentType;
const ComponentTag = ecs.ComponentTag;
const TransformComp = ecs.TransformComp;

test "add component to valid entity succeeds" {
    var allocator = test_utils.createTestAllocator();
    var manager = try EntityManager.init(&allocator);
    defer manager.deinit();

    const entity = try manager.createEntity();
    const transform = ComponentType{ .Transform = .{ .x = 0.5, .y = -0.3 } };

    const result = try manager.addComponent(entity, transform);
    try testing.expect(result == true);
}

test "add component to invalid entity fails" {
    var allocator = test_utils.createTestAllocator();
    var manager = try EntityManager.init(&allocator);
    defer manager.deinit();

    // Create and destroy entity to make it invalid
    const entity = try manager.createEntity();
    try manager.destroyEntity(entity);

    const transform = ComponentType{ .Transform = .{ .x = 0.0, .y = 0.0 } };
    const result = try manager.addComponent(entity, transform);
    try testing.expect(result == false);
}

test "add duplicate component fails" {
    var allocator = test_utils.createTestAllocator();
    var manager = try EntityManager.init(&allocator);
    defer manager.deinit();

    const entity = try manager.createEntity();
    const transform = ComponentType{ .Transform = .{ .x = 1.0, .y = 2.0 } };

    // First addition should succeed
    const first_result = try manager.addComponent(entity, transform);
    try testing.expect(first_result == true);

    // Second addition should fail
    const second_result = try manager.addComponent(entity, transform);
    try testing.expect(second_result == false);
}

test "remove component from entity with component succeeds" {
    var allocator = test_utils.createTestAllocator();
    var manager = try EntityManager.init(&allocator);
    defer manager.deinit();

    const entity = try manager.createEntity();
    const transform = ComponentType{ .Transform = .{ .x = 0.0, .y = 1.0 } };

    // Add component first
    _ = try manager.addComponent(entity, transform);

    // Remove should succeed
    const result = try manager.removeComponent(entity, .Transform);
    try testing.expect(result == true);
}

test "remove component from entity without component fails" {
    var allocator = test_utils.createTestAllocator();
    var manager = try EntityManager.init(&allocator);
    defer manager.deinit();

    const entity = try manager.createEntity();

    // Remove component that was never added should fail
    const result = try manager.removeComponent(entity, .Transform);
    try testing.expect(result == false);
}

test "remove component from invalid entity fails" {
    var allocator = test_utils.createTestAllocator();
    var manager = try EntityManager.init(&allocator);
    defer manager.deinit();

    // Create and destroy entity to make it invalid
    const entity = try manager.createEntity();
    try manager.destroyEntity(entity);

    const result = try manager.removeComponent(entity, .Transform);
    try testing.expect(result == false);
}

test "component storage maintains correct dense packing" {
    var allocator = test_utils.createTestAllocator();
    var manager = try EntityManager.init(&allocator);
    defer manager.deinit();

    // Create three entities and add components
    const e1 = try manager.createEntity();
    const e2 = try manager.createEntity();
    const e3 = try manager.createEntity();

    const transform1 = ComponentType{ .Transform = .{ .x = 1.0, .y = 1.0 } };
    const transform2 = ComponentType{ .Transform = .{ .x = 2.0, .y = 2.0 } };
    const transform3 = ComponentType{ .Transform = .{ .x = 3.0, .y = 3.0 } };

    _ = try manager.addComponent(e1, transform1);
    _ = try manager.addComponent(e2, transform2);
    _ = try manager.addComponent(e3, transform3);

    // Verify storage arrays have correct length
    try test_utils.expectLengthEqual(manager.transform.transforms.items.len, 3, "transforms array");
    try test_utils.expectLengthEqual(manager.transform.indexToEntity.items.len, 3, "indexToEntity array");

    // Remove middle component
    const remove_result = try manager.removeComponent(e2, .Transform);
    try testing.expect(remove_result == true);

    // Arrays should shrink and maintain consistency
    try test_utils.expectLengthEqual(manager.transform.transforms.items.len, 2, "transforms array after removal");
    try test_utils.expectLengthEqual(manager.transform.indexToEntity.items.len, 2, "indexToEntity array after removal");
}

test "component remove and re-add cycle works correctly" {
    var allocator = test_utils.createTestAllocator();
    var manager = try EntityManager.init(&allocator);
    defer manager.deinit();

    const entity = try manager.createEntity();
    const transform = ComponentType{ .Transform = .{ .x = 0.5, .y = -0.8 } };

    // Add component
    const add_result = try manager.addComponent(entity, transform);
    try testing.expect(add_result == true);

    // Remove component
    const remove_result = try manager.removeComponent(entity, .Transform);
    try testing.expect(remove_result == true);

    // Re-add component should succeed
    const re_add_result = try manager.addComponent(entity, transform);
    try testing.expect(re_add_result == true);
}

test "multiple entities with same component type" {
    var allocator = test_utils.createTestAllocator();
    var manager = try EntityManager.init(&allocator);
    defer manager.deinit();

    const entities = try test_utils.createTestEntities(&manager, 5, allocator);
    defer allocator.free(entities);

    // Add transform components to all entities
    for (entities, 0..) |entity, i| {
        const transform = ComponentType{ .Transform = .{ .x = @as(f32, @floatFromInt(i)), .y = @as(f32, @floatFromInt(i)) * 2.0 } };
        const result = try manager.addComponent(entity, transform);
        try testing.expect(result == true);
    }

    // Verify all components were added
    try test_utils.expectLengthEqual(manager.transform.transforms.items.len, 5, "all transforms added");

    // Remove components from some entities
    _ = try manager.removeComponent(entities[1], .Transform);
    _ = try manager.removeComponent(entities[3], .Transform);

    // Verify correct number remain
    try test_utils.expectLengthEqual(manager.transform.transforms.items.len, 3, "components after partial removal");
}

test "component storage consistency after complex operations" {
    var allocator = test_utils.createTestAllocator();
    var manager = try EntityManager.init(&allocator);
    defer manager.deinit();

    // Create entities
    const entities = try test_utils.createTestEntities(&manager, 10, allocator);
    defer allocator.free(entities);

    // Add components to half
    for (0..5) |i| {
        const transform = ComponentType{ .Transform = .{ .x = @as(f32, @floatFromInt(i)), .y = @as(f32, @floatFromInt(i)) } };
        _ = try manager.addComponent(entities[i], transform);
    }

    // Remove some components
    _ = try manager.removeComponent(entities[1], .Transform);
    _ = try manager.removeComponent(entities[3], .Transform);

    // Add components to previously unused entities
    for (5..8) |i| {
        const transform = ComponentType{ .Transform = .{ .x = @as(f32, @floatFromInt(i)), .y = @as(f32, @floatFromInt(i)) } };
        _ = try manager.addComponent(entities[i], transform);
    }

    // Verify final state consistency
    const expected_count = 6; // Started with 5, removed 2, added 3
    try test_utils.expectLengthEqual(manager.transform.transforms.items.len, expected_count, "final component count");
    try test_utils.expectLengthEqual(manager.transform.indexToEntity.items.len, expected_count, "final indexToEntity count");

    // Verify arrays are same length (critical invariant)
    try testing.expect(manager.transform.transforms.items.len == manager.transform.indexToEntity.items.len);
}

test "entity destruction removes all components" {
    var allocator = test_utils.createTestAllocator();
    var manager = try EntityManager.init(&allocator);
    defer manager.deinit();

    const entity = try manager.createEntity();
    const transform = ComponentType{ .Transform = .{ .x = 1.0, .y = 2.0 } };

    // Add component
    _ = try manager.addComponent(entity, transform);
    try test_utils.expectLengthEqual(manager.transform.transforms.items.len, 1, "component added");

    // Destroy entity - should remove component
    try manager.destroyEntity(entity);
    try test_utils.expectLengthEqual(manager.transform.transforms.items.len, 0, "component removed after entity destruction");
    try test_utils.expectLengthEqual(manager.transform.indexToEntity.items.len, 0, "index mapping cleared");
}

test "recycled entity has no components from previous incarnation" {
    var allocator = test_utils.createTestAllocator();
    var manager = try EntityManager.init(&allocator);
    defer manager.deinit();

    // Create entity and add component
    const entity1 = try manager.createEntity();
    const transform = ComponentType{ .Transform = .{ .x = 5.0, .y = 10.0 } };
    _ = try manager.addComponent(entity1, transform);

    // Destroy entity
    try manager.destroyEntity(entity1);

    // Create new entity (should recycle the ID)
    const entity2 = try manager.createEntity();
    try testing.expect(entity1.id == entity2.id); // Same ID recycled
    try testing.expect(entity2.generation == entity1.generation + 1); // Different generation

    // New entity should not have the old component
    try test_utils.expectLengthEqual(manager.transform.transforms.items.len, 0, "recycled entity has no old components");

    // Should be able to add component to recycled entity
    const new_transform = ComponentType{ .Transform = .{ .x = -1.0, .y = -2.0 } };
    const add_result = try manager.addComponent(entity2, new_transform);
    try testing.expect(add_result == true);
}

test "component storage consistency after mixed entity destruction" {
    var allocator = test_utils.createTestAllocator();
    var manager = try EntityManager.init(&allocator);
    defer manager.deinit();

    // Create entities with components
    const entities = try test_utils.createTestEntities(&manager, 5, allocator);
    defer allocator.free(entities);

    // Add components to first 4 entities
    for (0..4) |i| {
        const transform = ComponentType{ .Transform = .{ .x = @as(f32, @floatFromInt(i)), .y = @as(f32, @floatFromInt(i * 2)) } };
        _ = try manager.addComponent(entities[i], transform);
    }
    try test_utils.expectLengthEqual(manager.transform.transforms.items.len, 4, "initial components added");

    // Destroy entities 1 and 3 (middle ones)
    try manager.destroyEntity(entities[1]);
    try manager.destroyEntity(entities[3]);

    // Should have 2 components remaining
    try test_utils.expectLengthEqual(manager.transform.transforms.items.len, 2, "components after entity destruction");
    try test_utils.expectLengthEqual(manager.transform.indexToEntity.items.len, 2, "index mappings after entity destruction");

    // Remaining entities (0, 2, 4) should still be valid
    // Note: entity 4 never had a component, so only entities 0 and 2 should have components

    // Verify storage arrays are consistent
    try testing.expect(manager.transform.transforms.items.len == manager.transform.indexToEntity.items.len);
}
