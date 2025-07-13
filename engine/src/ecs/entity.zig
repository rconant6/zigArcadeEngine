const std = @import("std");

pub const Entity = struct {
    id: usize,
    generation: u16,

    pub fn init(id: usize, gen: u16) Entity {
        return .{
            .id = id,
            .generation = gen,
        };
    }
};
