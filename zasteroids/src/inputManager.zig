const std = @import("std");
const bge = @import("bridge.zig");
const KeyEvent = bge.KeyEvent;
const GameKeyCode = bge.GameKeyCode;
const ecs = @import("ecs.zig");
const Entity = ecs.Entity;
const EntityCommand = ecs.EntityCommand;
const InputWrapper = ecs.InputWrapper;

// Game controls
// not including the single touch keys for gameState swapping
const InputState = packed struct {
    A: u1 = 0,
    D: u1 = 0,
    W: u1 = 0,

    Space: u1 = 0,

    Left: u1 = 0,
    Right: u1 = 0,
    Up: u1 = 0,
};

pub const InputManager = struct {
    previousState: InputState,
    currentState: InputState,

    pub fn updateState(self: *InputManager, keyEvent: KeyEvent) void {
        comptime {
            const gameFields = @typeInfo(GameKeyCode).@"enum";
            const inputFields = @typeInfo(InputState).@"struct".fields;

            // Validate that each InputState field has a matching GameKeyCode
            for (inputFields) |field| {
                var found = false;
                for (gameFields.fields) |gameField| {
                    if (std.mem.eql(u8, field.name, gameField.name)) {
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    @compileError("InputState field '" ++ field.name ++ "' has no matching GameKeyCode enum value");
                }
            }
        }

        switch (keyEvent.keyCode) {
            inline else => |tag| {
                const fieldName = @tagName(tag);
                if (@hasField(InputState, fieldName)) {
                    @field(self.currentState, fieldName) = if (keyEvent.isPressed) 1 else 0;
                }
            },
        }
    }

    pub fn generateCommands(
        self: *InputManager,
        controllables: []InputWrapper,
        dt: f32,
        ecsCommands: *std.ArrayList(EntityCommand),
    ) void {
        var count: usize = 0;
        var outputCommands: [20]EntityCommand = undefined;
        const scaledDT = dt;

        for (controllables) |wrapper| {
            if (count >= 20) {
                std.log.err("You have to many commands being generated! Need to store more than 20!\n", .{});
                break;
            }

            if (self.isHeld(.A) or self.isHeld(.Left)) {
                outputCommands[count] = .{
                    .entity = wrapper.entity,
                    .command = .{ .Input = .{ .Rotate = -wrapper.rotationRate * scaledDT } },
                };
                count += 1;
            }
            if (self.isHeld(.D) or self.isHeld(.Right)) {
                outputCommands[count] = .{
                    .entity = wrapper.entity,
                    .command = .{ .Input = .{ .Rotate = wrapper.rotationRate * scaledDT } },
                };
                count += 1;
            }
            if (self.isHeld(.W) or self.isHeld(.Up)) {
                outputCommands[count] = .{
                    .entity = wrapper.entity,
                    .command = .{ .Input = .{ .Thrust = wrapper.thrustForce * scaledDT } },
                };
                count += 1;
            }
            if (self.justPressed(.Space)) {
                outputCommands[count] = .{
                    .entity = wrapper.entity,
                    .command = .{ .Input = .{ .Shoot = {} } },
                };
                count += 1;
            }
        }
        ecsCommands.appendSliceAssumeCapacity(outputCommands[0..count]);
    }

    fn justPressed(self: *InputManager, key: GameKeyCode) bool {
        switch (key) {
            inline else => |tag| {
                const fieldName = @tagName(tag);
                if (@hasField(InputState, fieldName)) {
                    return @field(self.currentState, fieldName) == 1 and @field(self.previousState, fieldName) == 0;
                }
            },
        }

        return false;
    }

    fn justReleased(self: *InputManager, key: GameKeyCode) bool {
        switch (key) {
            inline else => |tag| {
                const fieldName = @tagName(tag);
                if (@hasField(InputState, fieldName)) {
                    return @field(self.currentState, fieldName) == 0 and @field(self.previousState, fieldName) == 1;
                }
            },
        }

        return false;
    }

    fn isHeld(self: *InputManager, key: GameKeyCode) bool {
        switch (key) {
            inline else => |tag| {
                const fieldName = @tagName(tag);
                if (@hasField(InputState, fieldName)) {
                    return @field(self.currentState, fieldName) == 1;
                }
            },
        }

        return false;
    }

    pub fn endFrame(self: *InputManager) void {
        self.previousState = self.currentState;
    }

    pub fn init() InputManager {
        return InputManager{
            .previousState = InputState{},
            .currentState = InputState{},
        };
    }
    pub fn deinit(self: *InputManager) void {
        _ = self;
    }
};
