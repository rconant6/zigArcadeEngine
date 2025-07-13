const std = @import("std");

const engine = @import("engine");

pub fn main() !void {
    std.debug.print("We have a live game {s}\n", .{"it only does this print"});
}
