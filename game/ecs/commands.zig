const std = @import("std");

const types = @import("types.zig");
const Entity = types.Entity;

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
