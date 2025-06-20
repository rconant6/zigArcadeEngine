const std = @import("std");

const types = @import("types.zig");
const Command = types.Command;
const Entity = types.Entity;
const EntityCommand = types.EntityCommand;
const EntityConfig = types.EntityConfig;
const EntityHandle = types.EntityHandle;
const ComponentTag = types.ComponentTag;
const ComponentType = types.ComponentType;
const ControlComp = types.ControlComp;
const ControlCompStorage = types.ControlCompStorage;
const PlayerComp = types.PlayerComp;
const PlayerCompStorage = types.PlayerCompStorage;
const TransformComp = types.TransformComp;
const TransformCompStorage = types.TransformCompStorage;
const RenderComp = types.RenderComp;
const RenderCompStorage = types.RenderCompStorage;
const ShapeData = types.rend.ShapeData;
const InputManager = types.InputManager;
const InputWrapper = types.InputWrapper;

const Renderer = types.rend.Renderer;

const KeyEvent = @import("../bridge.zig").KeyEvent;

pub const EntityManager = struct {
    counter: usize,
    freeIds: std.fifo.LinearFifo(usize, .Dynamic),
    generations: std.ArrayList(u16),
    arena: std.heap.ArenaAllocator,

    commandQueue: std.ArrayList(EntityCommand),

    // component storage
    transform: TransformCompStorage, // transform - pos, rot, scale
    render: RenderCompStorage,
    control: ControlCompStorage,
    player: PlayerCompStorage,
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
        renderConfig: ?EntityConfig.ShapeConfigs,
        controlConfig: ?EntityConfig.ControllableConfig,
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

        if (tComp and rComp and cComp and pComp)
            return .{ .entity = entity, .manager = self };

        try self.destroyEntity(entity);
        return error.ComponentAddtionFailed;
    }

    pub fn addControllableEntity(self: *EntityManager, config: EntityConfig.ControllableConfig) !EntityHandle {
        const player = self.extractPlayer(config);
        const control = self.extractControl(config);

        const entity = self.createEntity();

        const pAdd = self.addPlayer(entity, player);
        const cAdd = self.addControl(entity, control);

        if (pAdd and cAdd) return .{ .entity = entity, .manager = self };

        try self.destroyEntity(entity);
        return error.ComponentAdditionFailed;
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

    pub fn addComponent(self: *EntityManager, entity: Entity, cType: ComponentType) !bool {
        if (!self.isEntityValid(entity)) {
            return false;
        }
        switch (cType) {
            .Control => return self.addControl(entity, cType.Control),
            .Player => return self.addPlayer(entity, cType.Player),
            .Render => return self.addRender(entity, cType.Render),
            .Transform => return self.addTransform(entity, cType.Transform),
        }
    }

    fn generateCommands(self: *EntityManager, inputManager: *InputManager, dt: f32) void {
        var count: usize = 0;
        var controllables: [5]InputWrapper = undefined;

        for (self.player.indexToEntity.items) |entityID| {
            if (self.control.entityToIndex.get(entityID)) |entity| {
                const control = self.control.data.items[entity];
                const rotRate = control.rotationRate orelse 0;
                const thrustForce = control.thrustForce orelse 0;
                if (rotRate != 0 or thrustForce != 0) {
                    controllables[count] = InputWrapper{
                        .entity = Entity.init(entityID, self.generations.items[entityID]),
                        .rotationRate = rotRate,
                        .thrustForce = thrustForce,
                    };
                    count += 1;
                }
            }
        }

        inputManager.generateCommands(
            controllables[0..count],
            dt,
            &self.commandQueue,
        );
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
                                        // const angle = rot.* + r;
                                        rot.* = angle;
                                    } else {
                                        transform.transform.rotation = r;
                                    }
                                }
                            },
                            .Thrust => |t| {
                                _ = t;
                                std.log.default.err("Unimplemented Thrust Command\n", .{});
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

    fn addTransform(self: *EntityManager, entity: Entity, comp: TransformComp) !bool {
        if (self.transform.entityToIndex.get(entity.id)) |_| return false;

        // insert into the storage
        const index = self.transform.data.items.len; // old len (next insert)
        try self.transform.data.append(comp); // put it in the dense array
        try self.transform.entityToIndex.put(entity.id, index); // store the index for the entity
        try self.transform.indexToEntity.append(entity.id); // keep the same index store the entity for revLookup
        std.debug.assert(self.transform.indexToEntity.items.len == self.transform.data.items.len);
        return true;
    }

    fn addRender(self: *EntityManager, entity: Entity, comp: RenderComp) !bool {
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

    pub fn inputSystem(self: *EntityManager, inputManager: *InputManager, dt: f32) void {
        self.generateCommands(inputManager, dt);
        self.processCommands();
    }

    // MARK: Memory management
    pub fn init(alloc: *std.mem.Allocator) !EntityManager {
        var nextList = std.fifo.LinearFifo(usize, .Dynamic).init(alloc.*);
        try nextList.ensureTotalCapacity(1024);
        const gens = std.ArrayList(u16).init(alloc.*);
        const commandStorage = try std.ArrayList(EntityCommand).initCapacity(alloc.*, 20);

        const tstorage = try TransformCompStorage.init(alloc);
        const rstorage = try RenderCompStorage.init(alloc);
        const cstorage = try ControlCompStorage.init(alloc);
        const pstorage = try PlayerCompStorage.init(alloc);

        return .{
            .counter = 0,
            .arena = std.heap.ArenaAllocator.init(alloc.*),
            .freeIds = nextList,
            .generations = gens,
            .transform = tstorage,
            .render = rstorage,
            .control = cstorage,
            .player = pstorage,
            .commandQueue = commandStorage,
        };
    }

    pub fn deinit(self: *EntityManager) void {
        self.freeIds.deinit();
        self.generations.deinit();
        self.player.deinit();
        self.control.deinit();
        self.transform.deinit();
        self.render.deinit();
        self.arena.deinit();
        self.commandQueue.deinit();
    }
};
