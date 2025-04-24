const std = @import("std");

const InputType = enum {
    Key,
    MouseButton,
    MousePosition,
    ScrollWheel,
    GamepadButton,
    GamepadAxis,
};

pub const InputComponent = struct {
    keyStates: std.AutoHashMap(u8, InputState),
    currentTime: u64,

    pub fn init(allocator: *std.mem.Allocator) !InputComponent {
        return InputComponent{
            .keyStates = std.AutoHashMap(u8, InputState).init(allocator),
            .currentTime = 0,
        };
    }

    pub fn deinit(self: *InputComponent) void {
        self.keyStates.deinit();
    }
};

pub const InputState = struct {
    isPressed: bool,
    wasPressed: bool,
    pressTime: u64,

    pub fn justPressed(self: *const InputState) bool {
        return self.isPressed and !self.wasPressed;
    }

    pub fn justReleased(self: *const InputState) bool {
        return !self.isPressed and self.wasPressed;
    }
};

const InputEvent = struct {
    time: u64,

    data: union(enum) {
        key: struct {
            code: u8,
            isPressed: bool,
        },
        // there would be more for mouse or gamepad controls
    },
};

pub const InputSystem = struct {
    eventQueue: std.fifo.LinearFifo(InputEvent, .{ .Static = 16 }),
    lastUpdateTime: u64,
    allocator: std.mem.Allocator,

    pub fn init(allocator: *std.mem.Allocator) !InputSystem {
        return InputSystem{
            .eventQueue = std.fifo.LinearFifo(InputEvent, .{ .Static = 16 }).init(allocator),
            .lastUpdateTime = 0,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *InputSystem) void {
        self.eventQueue.deinit();
    }

    pub fn addEvent(self: *InputSystem, event: InputEvent) !void {
        try self.eventQueue.append(event);
    }

    pub fn update(self: *InputSystem, components: *std.ArrayList(InputComponent), curTime: u64) !void {
        for (components.items) |*component| {
            // saving old state
            var iter = component.keyStates.valueIterator();
            while (iter.next()) |entry| {
                entry.wasPressed = entry.isPressed;
            }
        }

        const eventCount = self.eventQueue.count;
        var i: usize = 0;
        while (i < eventCount) : (i += 1) {
            const event = self.eventQueue.readItem() catch break;

            for (components.items) |*component| {
                switch (event.data) {
                    .key => |keyData| {
                        var state = component.keyStates.getPtr(keyData.code);
                        if (state == null) {
                            try component.keyStates.put(keyData.code, .{
                                .isPressed = keyData.isPressed,
                                .wasPressed = false,
                                .pressTime = if (keyData.isPressed) curTime else 0,
                            });
                        } else {
                            state.?.isPressed = keyData.isPressed;
                            if (keyData.isPressed and !state.?.wasPressed) {
                                state.?.pressTime = curTime;
                            }
                        }
                    },
                }
            }
        }

        self.lastUpdateTime = curTime;
    }
};

const KeyCodes = enum(u8) {
    P = 0x19, // Play/Pause
    A = 0x1E, // Rotate Counter-clockwise
    S = 0x1F, // Reverse (maybe mini nose thrusters)
    D = 0x20, // Rotate Clockwise
    W = 0x11, // Thrust Forward
    Enter = 0x1C, // Start Game
    Space = 0x39, // Shoot
};
