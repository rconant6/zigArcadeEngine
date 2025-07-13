const ecs = @import("ecs.zig");
const Entity = ecs.Entity;
const EntityManager = ecs.EntityManager;

pub const EntityHandle = struct {
    entity: Entity,
    manager: *EntityManager,
};
