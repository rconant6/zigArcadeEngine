const std = @import("std");

const ecs = @import("ecs.zig");
const Entity = ecs.Entity;

pub const InputWrapper = struct {
    entity: Entity,
    rotationRate: f32,
    thrustForce: f32,
};

pub const InputCommand = union(enum) {
    Rotate: f32,
    Thrust: f32,
    Shoot: void,
};

pub const Command = union(enum) {
    Input: InputCommand,
    // other commands?
};

pub const EntityCommand = struct {
    entity: Entity,
    command: Command,
};
