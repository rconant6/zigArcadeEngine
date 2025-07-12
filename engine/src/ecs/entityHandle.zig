const types = @import("types.zig");
const Entity = types.Entity;
const EntityManager = types.EntityManager;

pub const EntityHandle = struct {
    entity: Entity,
    manager: *EntityManager,
};
