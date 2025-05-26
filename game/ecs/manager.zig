const std = @import("std");
const types = @import("types.zig");

const Entity = types.Entity;
const ComponentTag = types.ComponentTag;
const ComponentType = types.ComponentType;
const TransformComp = types.TransformComp;
const TransformCompStorage = types.TransformCompStorage;
const RenderComp = types.RenderComp;
const RenderCompStorage = types.RenderCompStorage;

pub const EntityManager = struct {
    counter: usize,
    freeIds: std.fifo.LinearFifo(usize, .Dynamic),
    generations: std.ArrayList(u16),

    // component storage
    transform: TransformCompStorage, // transform - pos, rot, scale
    render: RenderCompStorage,
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
        // validate the entity
        if (!self.isEntityValid(entity)) {
            return false;
        }
        switch (cType) {
            .Transform => return self.addTransform(entity, cType.Transform),
            .Render => return self.addRender(entity, cType.Render),
        }
    }

    fn addTransform(self: *EntityManager, entity: Entity, comp: TransformComp) !bool {
        if (self.transform.entityToIndex.get(entity.id)) |_| {
            return false;
        }
        // insert into the storage
        const index = self.transform.data.items.len; // old len (next insert)
        try self.transform.data.append(comp); // put it in the dense array
        try self.transform.entityToIndex.put(entity.id, index); // store the index for the entity
        try self.transform.indexToEntity.append(entity.id); // keep the same index store the entity for revLookup
        std.debug.assert(self.transform.indexToEntity.items.len == self.transform.data.items.len);
        return true;
    }

    fn addRender(self: *EntityManager, entity: Entity, comp: RenderComp) !bool {
        if (self.render.entityToIndex.get(entity.id)) |_| {
            return false;
        }
        // insert into the storage
        const index = self.render.data.items.len; // old len (next insert)
        try self.render.data.append(comp); // put it in the dense array
        try self.render.entityToIndex.put(entity.id, index); // store the index for the entity
        try self.render.indexToEntity.append(entity.id); // keep the same index store the entity for revLookup
        std.debug.assert(self.render.indexToEntity.items.len == self.render.data.items.len);
        return true;
    }

    // MARK: Removal
    pub fn removeComponent(self: *EntityManager, entity: Entity, cTag: ComponentTag) !bool {
        if (!self.isEntityValid(entity)) {
            return false;
        }
        switch (cTag) {
            .Transform => return try self.removeTransform(entity),
            .Render => return try self.removeRender(entity),
        }
    }

    fn removeTransform(self: *EntityManager, entity: Entity) !bool {
        const remIndex = self.transform.entityToIndex.get(entity.id) orelse {
            return false;
        };

        const lastTransform = self.transform.data.pop() orelse return false;
        const lastEntity = self.transform.indexToEntity.pop() orelse return false;

        _ = self.transform.entityToIndex.remove(entity.id);

        if (remIndex < self.transform.data.items.len) {
            self.transform.data.items[remIndex] = lastTransform;
            self.transform.indexToEntity.items[remIndex] = lastEntity;

            try self.transform.entityToIndex.put(lastEntity, remIndex);
        }

        std.debug.assert(self.transform.indexToEntity.items.len == self.transform.data.items.len);
        return true;
    }

    fn removeRender(self: *EntityManager, entity: Entity) !bool {
        const remIndex = self.render.entityToIndex.get(entity.id) orelse {
            return false;
        };

        const lastTransform = self.render.data.pop() orelse return false;
        const lastEntity = self.render.indexToEntity.pop() orelse return false;

        _ = self.render.entityToIndex.remove(entity.id);

        if (remIndex < self.render.data.items.len) {
            self.render.data.items[remIndex] = lastTransform;
            self.render.indexToEntity.items[remIndex] = lastEntity;

            try self.render.entityToIndex.put(lastEntity, remIndex);
        }

        std.debug.assert(self.render.indexToEntity.items.len == self.render.data.items.len);
        return true;
    }

    // MARK: Entity interface
    pub fn createEntity(self: *EntityManager) !Entity {
        if (self.freeIds.readItem()) |id| {
            // recycled ID path
            std.debug.assert(id < self.generations.items.len);

            return Entity.init(id, self.generations.items[id]);
        } else {
            // new ID path
            const id = self.counter;
            try self.generations.append(0);
            self.counter += 1;
            std.debug.assert(id < self.generations.items.len);
            return Entity.init(id, 0);
        }
    }

    pub fn destroyEntity(self: *EntityManager, entity: Entity) !void {
        std.debug.assert(self.isEntityValid(entity));

        inline for (@typeInfo(ComponentTag).@"enum".fields) |field| {
            const tag: ComponentTag = @enumFromInt(field.value);
            _ = try self.removeComponent(entity, tag); //catch {
        }

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
        var nextList = std.fifo.LinearFifo(usize, .Dynamic).init(alloc.*);
        try nextList.ensureTotalCapacity(1024);
        const gens = std.ArrayList(u16).init(alloc.*);

        const tstorage = try TransformCompStorage.init(alloc);
        const rstorage = try RenderCompStorage.init(alloc);
        return .{
            .counter = 0,
            .freeIds = nextList,
            .generations = gens,
            .transform = tstorage,
            .render = rstorage,
        };
    }

    pub fn deinit(self: *EntityManager) void {
        self.freeIds.deinit();
        self.generations.deinit();
        self.transform.deinit();
        self.render.deinit();
    }
};
