const std = @import("std");
const types = @import("types.zig");

const Entity = types.Entity;
const ComponentTag = types.ComponentTag;
const ComponentType = types.ComponentType;
const TransformCompStorage = types.TransformCompStorage;

pub const EntityManager = struct {
    counter: usize,
    // keep free list for recycling ids
    freeIds: std.fifo.LinearFifo(usize, .Dynamic),
    // generation counter
    generations: std.ArrayList(u16),

    // component storage
    transform: TransformCompStorage, // transform - pos, rot, scale

    // render - info needed to be drawn by the renderer (shapes/colors)
    // physics - speed / accel data for movement
    // collision - data needed for collisions
    // ai - stuff needed for enemy control
    // shooting - way to shoot projectiles
    // playable - boolean flag?

    // systems in the engine (examples)
    // transformSys
    // renderSys
    // physicsSys
    // collisionSys
    // aiSys
    // shootingSys

    // MARK: Component interface
    pub fn addComponent(self: *EntityManager, entity: Entity, cType: ComponentType) !bool {
        std.debug.print("[ECS] - addComponent: Entity: {}, CompType: {}\n", .{ entity.id, cType });
        // validate the entity
        if (!self.isEntityValid(entity)) {
            std.debug.print("[ECS] - addComponent: Cannot add component: EntityID: {} is invalid\n", .{entity.id});
            return false;
        }
        // entity type specific implementations TODO: this should probably be helper functions depending on size
        switch (cType) {
            .Transform => return self.addTransform(entity, cType),
        }
    }

    fn addTransform(self: *EntityManager, entity: Entity, cType: ComponentType) !bool {
        // make sure it isn't already there (no hot reswapping) - make a new entity instead
        if (self.transform.entityToIndex.get(entity.id)) |_| {
            std.debug.print(
                "[ECS] - addComponent: Component {} already exists on EntityID: {}\n",
                .{ @TypeOf(cType), entity.id },
            );
            return false;
        }
        // insert into the storage
        const index = self.transform.transforms.items.len; // old len (next insert)
        try self.transform.transforms.append(cType.Transform); // put it in the dense array
        try self.transform.entityToIndex.put(entity.id, index); // store the index for the entity
        try self.transform.indexToEntity.append(entity.id); // keep the same index store the entity for revLookup
        std.debug.assert(self.transform.indexToEntity.items.len == self.transform.transforms.items.len);
        return true;
    }

    pub fn removeComponent(self: *EntityManager, entity: Entity, cTag: ComponentTag) !bool {
        std.debug.print("[ECS] - removeComponent: Entity: {}, CompType: {}\n", .{ entity.id, cTag });
        if (!self.isEntityValid(entity)) {
            std.debug.print("[ECS] - removeComponent: Cannot remove component: EntityID: {} is invalid\n", .{entity.id});
            return false;
        }
        switch (cTag) {
            .Transform => return try self.removeTransform(entity),
        }
    }

    fn removeTransform(self: *EntityManager, entity: Entity) !bool {
        const remIndex = self.transform.entityToIndex.get(entity.id) orelse {
            std.debug.print("[ECS] - removeComponent: Transform doesn't exist on EntityID: {}\n", .{entity.id});
            return false;
        };

        const lastTransform = self.transform.transforms.pop() orelse return false;
        const lastEntity = self.transform.indexToEntity.pop() orelse return false;

        _ = self.transform.entityToIndex.remove(entity.id);

        if (remIndex < self.transform.transforms.items.len) {
            self.transform.transforms.items[remIndex] = lastTransform;
            self.transform.indexToEntity.items[remIndex] = lastEntity;

            try self.transform.entityToIndex.put(lastEntity, remIndex);
        }

        std.debug.assert(self.transform.indexToEntity.items.len == self.transform.transforms.items.len);
        return true;
    }

    // MARK: Entity interface
    pub fn createEntity(self: *EntityManager) !Entity {
        if (self.freeIds.readItem()) |id| {
            // recycled ID path
            std.debug.assert(id < self.generations.items.len); // NOTE: remove

            std.debug.print("[ECS] - (recycle)createEntity(id: {d}, gen: {d})\n", .{ id, self.generations.items[id] });
            return Entity.init(id, self.generations.items[id]);
        } else {
            // new ID path
            const id = self.counter;
            try self.generations.append(0);
            self.counter += 1;
            std.debug.assert(id < self.generations.items.len); // NOTE: remove
            std.debug.print("[ECS] - (new)createEntity(id: {d}, gen: {d})\n", .{ id, self.generations.items[id] });
            return Entity.init(id, 0);
        }
    }

    pub fn destroyEntity(self: *EntityManager, entity: Entity) void {
        std.debug.assert(self.isEntityValid(entity));
        self.generations.items[entity.id] += 1;
        self.freeIds.writeItemAssumeCapacity(entity.id);
    }

    pub fn isEntityValid(self: *const EntityManager, entity: Entity) bool {
        return entity.id < self.counter and
            entity.generation == self.generations.items[entity.id];
    }

    pub fn update(self: *EntityManager, dt: f32) void {
        _ = dt;
        _ = self;
        // do all the updates through the systems
    }

    // MARK: Memory management
    pub fn init(alloc: *std.mem.Allocator) !EntityManager {
        std.debug.print("[ECS] - manager.init()\n", .{});
        var nextList = std.fifo.LinearFifo(usize, .Dynamic).init(alloc.*);
        try nextList.ensureTotalCapacity(1024);
        const gens = std.ArrayList(u16).init(alloc.*);

        const storage = try TransformCompStorage.init(alloc);
        return .{
            .counter = 0,
            .freeIds = nextList,
            .generations = gens,
            .transform = storage,
        };
    }

    pub fn deinit(self: *EntityManager) void {
        self.freeIds.deinit();
        self.generations.deinit();
        self.transform.deinit();
        std.debug.print("[ECS] - manager.deinit()\n", .{});
    }
};
