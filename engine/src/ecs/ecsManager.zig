const std = @import("std");

const ecs = @import("ecs.zig");
const Command = ecs.Command;
const Entity = ecs.Entity;
const EntityHandle = ecs.EntityHandle;
const ComponentTag = ecs.ComponentTag;
const ComponentType = ecs.ComponentType;
const ControlComp = ecs.ControlComp;
const ControlCompStorage = ecs.ControlCompStorage;
const ControllableConfig = ecs.ControllableConfig;
const PlayerComp = ecs.PlayerComp;
const PlayerCompStorage = ecs.PlayerCompStorage;
const Polygon = ecs.Polygon;
const TransformComp = ecs.TransformComp;
const TransformCompStorage = ecs.TransformCompStorage;
const RenderComp = ecs.RenderComp;
const RenderCompStorage = ecs.RenderCompStorage;
const Renderer = ecs.Renderer;
const ShapeConfig = ecs.ShapeConfig;
const ShapeData = ecs.ShapeData;
const VelocityComp = ecs.VelocityComp;
const VelocityCompStorage = ecs.VelocityCompStorage;
const V2 = ecs.V2;

// const KeyEvent = @import("../bridge.zig").KeyEvent; // still tood from platform....

pub const EntityManager = struct {
    counter: usize,
    freeIds: std.fifo.LinearFifo(usize, .Dynamic),
    generations: std.ArrayList(u16),
    arena: std.heap.ArenaAllocator,

    // component storage
    transform: TransformCompStorage, // transform - pos, rot, scale
    render: RenderCompStorage,
    control: ControlCompStorage,
    player: PlayerCompStorage,
    velocity: VelocityCompStorage,
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

    // MARK: Public API for entity creation and component addition
    pub fn addEntity(self: *EntityManager) !EntityHandle {
        return .{
            .entity = try self.createEntity(),
            .manager = self,
        };
    }
    pub fn addEntityWithConfigs(
        self: *EntityManager,
        renderConfig: ?ShapeConfig,
        controlConfig: ?ControllableConfig,
    ) !EntityHandle {
        const entity = try self.createEntity();
        var tComp = false;
        var cComp = false;
        var pComp = false;
        var rComp = false;

        if (renderConfig) |rc| {
            const transform = try extractTransform(rc);
            const shape = try self.extractShape(rc);
            tComp = try self.addTransform(entity, transform);
            rComp = try self.addRender(entity, .{ .shapeData = shape, .visible = true });
        }

        if (controlConfig) |cc| {
            const control = try self.extractControl(cc);
            const player = try self.extractPlayer(cc);
            cComp = try self.addComponent(entity, .{ .Control = control });
            pComp = try self.addComponent(entity, .{ .Player = player });
        }

        if (tComp or rComp or cComp or pComp)
            return .{ .entity = entity, .manager = self };

        try self.destroyEntity(entity);
        return error.ComponentAddtionFailed;
    }

    pub fn addControllableEntity(self: *EntityManager, config: ControllableConfig) !EntityHandle {
        const player = self.extractPlayer(config);
        const control = self.extractControl(config);

        const entity = self.createEntity();

        const pAdd = self.addPlayer(entity, player);
        const cAdd = self.addControl(entity, control);

        if (pAdd and cAdd) return .{ .entity = entity, .manager = self };

        try self.destroyEntity(entity);
        return error.ComponentAdditionFailed;
    }

    pub fn addRenderableEntity(self: *EntityManager, config: ShapeConfig) !EntityHandle {
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

    pub fn addComponent(self: *EntityManager, entity: Entity, cType: ComponentType) !bool {
        if (!self.isEntityValid(entity)) {
            return false;
        }
        switch (cType) {
            .Control => return self.addControl(entity, cType.Control),
            .Player => return self.addPlayer(entity, cType.Player),
            .Render => return self.addRender(entity, cType.Render),
            .Transform => return self.addTransform(entity, cType.Transform),
            .Velocity => return self.addVelocity(entity, cType.Velocity),
        }
    }

    fn processCommands(self: *EntityManager) void {
        for (self.commandQueue.items) |command| {
            if (self.isEntityValid(command.entity)) {
                switch (command.command) {
                    .Input => |ic| {
                        switch (ic) {
                            .Rotate => |r| {
                                if (self.transform.entityToIndex.get(command.entity.id)) |index| {
                                    const transform = &self.transform.data.items[index];

                                    if (transform.transform.rotation) |*rot| {
                                        const angle = @mod(rot.* + r, 2 * std.math.pi);
                                        rot.* = angle;
                                    } else {
                                        transform.transform.rotation = r;
                                    }
                                }
                            },
                            .Thrust => |t| {
                                if (self.transform.entityToIndex.get(command.entity.id)) |transformIndex| {
                                    if (self.velocity.entityToIndex.get(command.entity.id)) |velocityIndex| {
                                        const transform = &self.transform.data.items[transformIndex];
                                        const velocity = &self.velocity.data.items[velocityIndex];
                                        const rotation = transform.transform.rotation orelse 0;
                                        const adjustedRotation = rotation + std.math.pi * 0.5;
                                        const thrustDirection = V2{
                                            .x = std.math.cos(adjustedRotation),
                                            .y = std.math.sin(adjustedRotation),
                                        };
                                        const thrustVector = thrustDirection.mul(t);
                                        velocity.velocity = velocity.velocity.add(thrustVector);
                                    }
                                }
                            },
                            .Shoot => |s| {
                                _ = s;
                                std.log.default.err("Unimplemented Shoot Command\n", .{});
                            },
                        }
                    },
                }
            }
        }
        self.commandQueue.clearRetainingCapacity();
    }

    pub fn removeComponent(self: *EntityManager, entity: Entity, cTag: ComponentTag) !bool {
        if (!self.isEntityValid(entity)) {
            return false;
        }
        switch (cTag) {
            .Control => return try self.removeControl(entity),
            .Player => return try self.removePlayer(entity),
            .Render => return try self.removeRender(entity),
            .Transform => return try self.removeTransform(entity),
            .Velocity => return try self.removeVelocity(entity),
        }
    }

    // MARK: Private helpers

    fn createEntity(self: *EntityManager) !Entity {
        if (self.freeIds.readItem()) |id| {
            std.debug.assert(id < self.generations.items.len);

            return Entity.init(id, self.generations.items[id]);
        } else {
            const id = self.counter;
            try self.generations.append(0);
            self.counter += 1;
            std.debug.assert(id < self.generations.items.len);
            return Entity.init(id, 0);
        }
    }

    fn destroyEntity(self: *EntityManager, entity: Entity) !void {
        std.debug.assert(self.isEntityValid(entity));

        inline for (@typeInfo(ComponentTag).@"enum".fields) |field| {
            const tag: ComponentTag = @enumFromInt(field.value);
            _ = try self.removeComponent(entity, tag); //catch {
        }

        self.generations.items[entity.id] += 1;
        self.freeIds.writeItemAssumeCapacity(entity.id);
    }

    fn extractShape(self: *EntityManager, config: ShapeConfig) !ShapeData {
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
                var polygon = try Polygon.init(self.arena.allocator(), p.vertices.?);
                polygon.outlineColor = p.outlineColor;
                polygon.fillColor = p.fillColor;
                return ShapeData{ .Polygon = polygon };
            },
        };
    }

    fn extractPlayer(self: *EntityManager, config: anytype) !PlayerComp {
        _ = self;
        const id = @field(config, "playerID") orelse return error.InvalidConfig;
        return PlayerComp{
            .playerID = id,
        };
    }

    fn extractControl(self: *EntityManager, config: anytype) !ControlComp {
        _ = self;
        return ControlComp{
            .rotationRate = @field(config, "rotationRate"),
            .thrustForce = @field(config, "thrustForce"),
            .shotRate = @field(config, "shotRate"),
        };
    }

    fn extractTransform(config: anytype) !TransformComp {
        switch (config) {
            inline else => |c| {
                if (@hasField(@TypeOf(c), "scale")) {
                    if (c.scale) |scale| if (scale < 0) return error.InvalidScaleParameter;
                }
                if (@hasField(@TypeOf(c), "radius")) {
                    if (@field(c, "radius") <= 0) return error.InvalidRadiusParameter;
                }

                return TransformComp{
                    .transform = .{
                        .offset = @field(c, "offset"),
                        .rotation = @field(c, "rotation"),
                        .scale = @field(c, "scale"),
                    },
                };
            },
        }
    }

    fn addPlayer(self: *EntityManager, entity: Entity, comp: PlayerComp) !bool {
        if (self.player.entityToIndex.get(entity.id)) |_| return false;

        const index = self.player.data.items.len;
        try self.player.data.append(comp);
        try self.player.entityToIndex.put(entity.id, index); // store the index for the entity
        try self.player.indexToEntity.append(entity.id); // keep the same index store the entity for revLookup
        std.debug.assert(self.player.indexToEntity.items.len == self.player.data.items.len);
        return true;
    }

    fn addControl(self: *EntityManager, entity: Entity, comp: ControlComp) !bool {
        if (self.control.entityToIndex.get(entity.id)) |_| return false;

        const index = self.control.data.items.len;
        try self.control.data.append(comp);
        try self.control.entityToIndex.put(entity.id, index); // store the index for the entity
        try self.control.indexToEntity.append(entity.id); // keep the same index store the entity for revLookup
        std.debug.assert(self.control.indexToEntity.items.len == self.control.data.items.len);
        return true;
    }

    fn addVelocity(self: *EntityManager, entity: Entity, comp: VelocityComp) !bool {
        if (self.velocity.entityToIndex.get(entity.id)) |_| return false;

        // insert into the storage
        const index = self.velocity.data.items.len; // old len (next insert)
        try self.velocity.data.append(comp); // put it in the dense array
        try self.velocity.entityToIndex.put(entity.id, index); // store the index for the entity
        try self.velocity.indexToEntity.append(entity.id); // keep the same index store the entity for revLookup
        std.debug.assert(self.velocity.indexToEntity.items.len == self.velocity.data.items.len);
        return true;
    }

    pub fn addTransform(self: *EntityManager, entity: Entity, comp: TransformComp) !bool {
        if (self.transform.entityToIndex.get(entity.id)) |_| return false;

        // insert into the storage
        const index = self.transform.data.items.len; // old len (next insert)
        try self.transform.data.append(comp); // put it in the dense array
        try self.transform.entityToIndex.put(entity.id, index); // store the index for the entity
        try self.transform.indexToEntity.append(entity.id); // keep the same index store the entity for revLookup
        std.debug.assert(self.transform.indexToEntity.items.len == self.transform.data.items.len);
        return true;
    }

    pub fn addRender(self: *EntityManager, entity: Entity, comp: RenderComp) !bool {
        if (self.render.entityToIndex.get(entity.id)) |_| return false;

        // insert into the storage
        const index = self.render.data.items.len; // old len (next insert)
        try self.render.data.append(comp); // put it in the dense array
        try self.render.entityToIndex.put(entity.id, index); // store the index for the entity
        try self.render.indexToEntity.append(entity.id); // keep the same index store the entity for revLookup
        std.debug.assert(self.render.indexToEntity.items.len == self.render.data.items.len);
        return true;
    }

    // MARK: Removal
    fn removePlayer(self: *EntityManager, entity: Entity) !bool {
        const remIndex = self.player.entityToIndex.get(entity.id) orelse return false;

        const lastControl = self.player.data.pop() orelse return false;
        const lastEntity = self.player.indexToEntity.pop() orelse return false;

        _ = self.player.entityToIndex.remove(entity.id);

        if (remIndex < self.player.data.items.len) {
            self.player.data.items[remIndex] = lastControl;
            self.player.indexToEntity.items[remIndex] = lastEntity;

            try self.player.entityToIndex.put(lastEntity, remIndex);
        }

        std.debug.assert(self.player.indexToEntity.items.len == self.player.data.items.len);
        return true;
    }

    fn removeControl(self: *EntityManager, entity: Entity) !bool {
        const remIndex = self.control.entityToIndex.get(entity.id) orelse return false;

        const lastControl = self.control.data.pop() orelse return false;
        const lastEntity = self.control.indexToEntity.pop() orelse return false;

        _ = self.control.entityToIndex.remove(entity.id);

        if (remIndex < self.control.data.items.len) {
            self.control.data.items[remIndex] = lastControl;
            self.control.indexToEntity.items[remIndex] = lastEntity;

            try self.control.entityToIndex.put(lastEntity, remIndex);
        }

        std.debug.assert(self.control.indexToEntity.items.len == self.control.data.items.len);
        return true;
    }

    fn removeVelocity(self: *EntityManager, entity: Entity) !bool {
        const remIndex = self.velocity.entityToIndex.get(entity.id) orelse return false;

        const lastVelocity = self.velocity.data.pop() orelse return false;
        const lastEntity = self.velocity.indexToEntity.pop() orelse return false;

        _ = self.velocity.entityToIndex.remove(entity.id);

        if (remIndex < self.velocity.data.items.len) {
            self.velocity.data.items[remIndex] = lastVelocity;
            self.velocity.indexToEntity.items[remIndex] = lastEntity;

            try self.velocity.entityToIndex.put(lastEntity, remIndex);
        }

        std.debug.assert(self.velocity.indexToEntity.items.len == self.velocity.data.items.len);
        return true;
    }

    fn removeTransform(self: *EntityManager, entity: Entity) !bool {
        const remIndex = self.transform.entityToIndex.get(entity.id) orelse return false;

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
        const remIndex = self.render.entityToIndex.get(entity.id) orelse return false;

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

    pub fn isEntityValid(self: *const EntityManager, entity: Entity) bool {
        return entity.id < self.counter and
            entity.generation == self.generations.items[entity.id];
    }
    // MARK: Systems interface
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

    pub fn physicsSystem(self: *EntityManager, dt: f32) void {
        for (self.velocity.indexToEntity.items, 0..) |entityID, velocityIndex| {
            if (self.transform.entityToIndex.get(entityID)) |transformIndex| {
                const transform = &self.transform.data.items[transformIndex];
                const velocity = self.velocity.data.items[velocityIndex].velocity.mul(dt);
                if (transform.*.transform.offset) |*off| {
                    off.x += velocity.x;
                    off.y += velocity.y;

                    if (off.x > 10.0) off.x = -10;
                    if (off.x < -10.0) off.x = 10;
                    if (off.y > 10.0) off.y = -10;
                    if (off.y < -10.0) off.y = 10;
                }
            }
        }
    }

    // MARK: Memory management
    pub fn init(alloc: std.mem.Allocator) !EntityManager {
        var nextList = std.fifo.LinearFifo(usize, .Dynamic).init(alloc);
        try nextList.ensureTotalCapacity(1024);
        const gens = std.ArrayList(u16).init(alloc);

        const tstorage = try TransformCompStorage.init(alloc);
        const rstorage = try RenderCompStorage.init(alloc);
        const cstorage = try ControlCompStorage.init(alloc);
        const pstorage = try PlayerCompStorage.init(alloc);
        const vstorage = try VelocityCompStorage.init(alloc);

        return .{
            .counter = 0,
            .arena = std.heap.ArenaAllocator.init(alloc),
            .freeIds = nextList,
            .generations = gens,
            .transform = tstorage,
            .render = rstorage,
            .control = cstorage,
            .player = pstorage,
            .velocity = vstorage,
        };
    }

    pub fn deinit(self: *EntityManager) void {
        self.freeIds.deinit();
        self.generations.deinit();
        self.player.deinit();
        self.control.deinit();
        self.transform.deinit();
        self.velocity.deinit();
        self.render.deinit();
        self.arena.deinit();
    }
};
