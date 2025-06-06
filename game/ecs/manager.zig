const std = @import("std");

const types = @import("types.zig");
const Entity = types.Entity;
const EntityConfig = types.EntityConfig;
const EntityHandle = types.EntityHandle;
const ComponentTag = types.ComponentTag;
const ComponentType = types.ComponentType;
const TransformComp = types.TransformComp;
const TransformCompStorage = types.TransformCompStorage;
const RenderComp = types.RenderComp;
const RenderCompStorage = types.RenderCompStorage;
const ShapeData = types.rend.ShapeData;

const Renderer = types.rend.Renderer;

pub const EntityManager = struct {
    counter: usize,
    freeIds: std.fifo.LinearFifo(usize, .Dynamic),
    generations: std.ArrayList(u16),
    arena: std.heap.ArenaAllocator,

    // component storage
    transform: TransformCompStorage, // transform - pos, rot, scale
    render: RenderCompStorage,
    // physics - speed / accel data for movement
    // collision - data needed for collisions
    // ai - stuff needed for enemy control
    // shooting - way to shoot projectiles
    // playable - boolean flag?

    // systems in the engine (examples)
    // physicsSys
    // collisionSys
    // aiSys
    // shootingSys

    // MARK: Wrappers for easier use
    pub fn addEntity(self: *EntityManager) !EntityHandle {
        return .{
            .entity = try self.createEntity(),
            .manager = self,
        };
    }

    pub fn addRenderableEntity(self: *EntityManager, config: EntityConfig.ShapeConfigs) !EntityHandle {
        const entity = try self.createEntity();
        const transformComp = try switch (config) {
            inline else => |c| extractTransform(c),
        };
        const shape = try extractShape(self, config);
        const renderComponent = RenderComp{ .shapeData = shape, .visible = true };

        const tAdd = try self.addTransform(entity, transformComp);
        const rAdd = try self.addRender(entity, renderComponent);

        if (tAdd and rAdd) return .{ .entity = entity, .manager = self };

        try self.destroyEntity(entity);
        return error.ComponentAdditionFailed;
    }

    fn extractShape(self: *EntityManager, config: EntityConfig.ShapeConfigs) !ShapeData {
        return switch (config) {
            .Circle => |c| ShapeData{ .Circle = .{
                .origin = c.origin,
                .radius = c.radius,
                .outlineColor = c.outlineColor,
                .fillColor = c.fillColor,
            } },
            .Line => |l| ShapeData{ .Line = .{
                .start = l.start,
                .end = l.end,
                .color = l.color,
            } },
            .Rectangle => |r| ShapeData{ .Rectangle = .{
                .center = r.center,
                .halfWidth = r.halfWidth,
                .halfHeight = r.halfHeight,
                .outlineColor = r.outlineColor,
                .fillColor = r.fillColor,
            } },

            .Triangle => |t| ShapeData{ .Triangle = .{
                .vertices = t.vertices,
                .outlineColor = t.outlineColor,
                .fillColor = t.fillColor,
            } },
            .Polygon => |p| {
                if (p.vertices == null) return error.PolygonRequiresVertices;
                var polygon = try types.rend.Polygon.init(self.arena.allocator(), p.vertices.?);
                polygon.outlineColor = p.outlineColor;
                polygon.fillColor = p.fillColor;
                return ShapeData{ .Polygon = polygon };
            },
        };
    }

    fn extractTransform(config: anytype) !TransformComp {
        if (config.scale) |scale| if (scale < 0) return error.InvalidScaleParameter;

        if (@hasField(@TypeOf(config), "radius")) {
            if (@field(config, "radius") <= 0) return error.InvalidRadiusParameter;
        }

        return TransformComp{
            .transform = .{
                .offset = @field(config, "offset"),
                .rotation = @field(config, "rotation"),
                .scale = @field(config, "scale"),
            },
        };
    }
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
    // MARK: Systems interface
    pub fn update(self: *EntityManager, dt: f32) void {
        _ = dt;
        _ = self;
        // do all the updates through the systems
    }

    pub fn renderSystem(self: *EntityManager, renderer: *Renderer) void {
        for (self.transform.indexToEntity.items, 0..) |entityID, transformIndex| {
            if (self.render.entityToIndex.get(entityID)) |renderIndex| {
                const transformComp = self.transform.data.items[transformIndex];
                const renderComp = self.render.data.items[renderIndex];
                if (renderComp.visible) {
                    renderer.drawShape(renderComp.shapeData, transformComp.transform);
                }
            }
        }
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
            .arena = std.heap.ArenaAllocator.init(alloc.*),
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
        self.arena.deinit();
    }
};
