const std = @import("std");
const testing = std.testing;
const test_utils = @import("utils.zig");

const ecs = @import("ecs");
const Entity = ecs.Entity;
const EntityManager = ecs.EntityManager;

test "entity creation generates sequential IDs" {
    var allocator = test_utils.createTestAllocator();
    var manager = try EntityManager.init(&allocator);
    defer manager.deinit();

    const e1 = try manager.createEntity();
    const e2 = try manager.createEntity();
    const e3 = try manager.createEntity();

    try testing.expect(e1.id == 0);
    try testing.expect(e2.id == 1);
    try testing.expect(e3.id == 2);

    try testing.expect(e1.generation == 0);
    try testing.expect(e2.generation == 0);
    try testing.expect(e3.generation == 0);
}

test "entity validation works correctly" {
    var allocator = test_utils.createTestAllocator();
    var manager = try EntityManager.init(&allocator);
    defer manager.deinit();

    const entity = try manager.createEntity();

    // Valid entity should pass validation
    try testing.expect(manager.isEntityValid(entity));

    // Invalid entity (wrong generation) should fail
    const invalid_entity = Entity.init(entity.id, entity.generation + 1);
    try testing.expect(!manager.isEntityValid(invalid_entity));

    // Invalid entity (out of range ID) should fail
    const out_of_range = Entity.init(999, 0);
    try testing.expect(!manager.isEntityValid(out_of_range));
}

test "entity destruction increments generation" {
    var allocator = test_utils.createTestAllocator();
    var manager = try EntityManager.init(&allocator);
    defer manager.deinit();

    const e1 = try manager.createEntity();
    try test_utils.expectEntityValid(e1.id, e1.generation, 0, 0);

    try manager.destroyEntity(e1);

    // Create new entity - should recycle ID with incremented generation
    const e2 = try manager.createEntity();
    try test_utils.expectEntityValid(e2.id, e2.generation, 0, 1);

    try testing.expect(e1.id == e2.id); // Same ID
    try testing.expect(e2.generation == e1.generation + 1); // Incremented generation
}

test "entity recycling follows FIFO order" {
    var allocator = test_utils.createTestAllocator();
    var manager = try EntityManager.init(&allocator);
    defer manager.deinit();

    // Create entities
    const entities = try test_utils.createTestEntities(&manager, test_utils.TestConfig.BATCH_TEST_ENTITY_COUNT, allocator);
    defer allocator.free(entities);

    // Destroy all in reverse order
    for (0..test_utils.TestConfig.BATCH_TEST_ENTITY_COUNT) |i| {
        const idx = test_utils.TestConfig.BATCH_TEST_ENTITY_COUNT - 1 - i;
        try manager.destroyEntity(entities[idx]);
    }

    // Create 3 new ones - should recycle in FIFO order (0, 1, 2)
    const new1 = try manager.createEntity();
    const new2 = try manager.createEntity();
    const new3 = try manager.createEntity();

    try testing.expect(new1.id == 4);
    try testing.expect(new2.id == 3);
    try testing.expect(new3.id == 2);

    // All should have generation 1 (incremented from 0)
    try testing.expect(new1.generation == 1);
    try testing.expect(new2.generation == 1);
    try testing.expect(new3.generation == 1);
}

test "interleaved create and destroy operations" {
    var allocator = test_utils.createTestAllocator();
    var manager = try EntityManager.init(&allocator);
    defer manager.deinit();

    const e1 = try manager.createEntity();
    const e2 = try manager.createEntity();

    // Destroy first entity
    try manager.destroyEntity(e1);

    // Create new entity - should recycle e1's ID
    const e3 = try manager.createEntity();
    try testing.expect(e3.id == e1.id);
    try testing.expect(e3.generation == e1.generation + 1);

    // Create another - should get new ID
    const e4 = try manager.createEntity();
    try testing.expect(e4.id == 2); // Next sequential ID

    // Destroy e2 and e3
    try manager.destroyEntity(e2);
    try manager.destroyEntity(e3);

    // Create two more - should recycle in FIFO order
    const e5 = try manager.createEntity(); // Should get e2's ID
    const e6 = try manager.createEntity(); // Should get e3's ID (which was e1's ID)

    try testing.expect(e5.id == e2.id);
    try testing.expect(e5.generation == e2.generation + 1);
    try testing.expect(e6.id == e1.id);
    try testing.expect(e6.generation == e3.generation + 1);
}

test "stress test with many entities" {
    var allocator = test_utils.createTestAllocator();
    var manager = try EntityManager.init(&allocator);
    defer manager.deinit();

    // Create many entities
    const entities = try test_utils.createTestEntities(&manager, test_utils.TestConfig.STRESS_TEST_ENTITY_COUNT, allocator);
    defer allocator.free(entities);

    // Verify all entities are valid
    for (entities, 0..) |entity, i| {
        try testing.expect(manager.isEntityValid(entity));
        try testing.expect(entity.id == i);
        try testing.expect(entity.generation == 0);
    }

    // Destroy all entities
    test_utils.destroyTestEntities(&manager, entities);

    // Create half as many new entities - should all recycle
    const new_entities = try test_utils.createTestEntities(&manager, test_utils.TestConfig.STRESS_TEST_ENTITY_COUNT / 2, allocator);
    defer allocator.free(new_entities);

    // Verify recycling worked correctly
    for (new_entities, 0..) |entity, i| {
        try testing.expect(manager.isEntityValid(entity));
        try testing.expect(entity.id == i);
        try testing.expect(entity.generation == 1); // Incremented from destruction
    }
}

test "entity counter increments correctly" {
    var allocator = test_utils.createTestAllocator();
    var manager = try EntityManager.init(&allocator);
    defer manager.deinit();

    try testing.expect(manager.counter == 0);

    _ = try manager.createEntity();
    try testing.expect(manager.counter == 1);

    _ = try manager.createEntity();
    try testing.expect(manager.counter == 2);

    // Counter should not decrement on destroy
    const entity = try manager.createEntity();
    try testing.expect(manager.counter == 3);

    try manager.destroyEntity(entity);
    try testing.expect(manager.counter == 3); // Should remain the same
}
