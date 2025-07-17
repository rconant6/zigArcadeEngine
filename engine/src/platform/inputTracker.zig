const std = @import("std");

const plat = @import("platform.zig");
const EventType = plat.EventType;
const KeyCode = plat.KeyCode;
const KeyEvent = plat.KeyEvent;
const MouseButton = plat.MouseButton;
const MouseEvent = plat.MouseEvent;

pub const InputEvent = union(enum) {
    key: KeyEvent,
    mouse: MouseEvent,
    // pad: GamePadEvent,
};

pub const MouseState = struct {
    isPressed: bool = false,
    wasPressed: bool = false,
    pressDuration: f32 = 0,

    pub fn justPressed(self: MouseState) bool {
        _ = self;
        return false;
    }
    pub fn justReleased(self: MouseState) bool {
        _ = self;
        return false;
    }
    pub fn isHeld(self: MouseState) bool {
        _ = self;
        return false;
    }
    pub fn holdDuration(self: MouseState) f32 {
        _ = self;
        return false;
    }
};

pub const KeyState = struct {
    isPressed: bool = false,
    wasPressed: bool = false,
    pressDuration: f32 = 0,

    pub fn justPressed(self: KeyState) bool {
        return !self.wasPressed and self.isPressed;
    }
    pub fn justReleased(self: KeyState) bool {
        return self.wasPressed and !self.isPressed;
    }
    pub fn isHeld(self: KeyState) bool {
        return self.isPressed;
    }
    pub fn holdDuration(self: KeyState) f32 {
        return self.pressDuration;
    }
};

pub const InputHandler = struct {
    keyStates: [124]KeyState,
    mouseStates: [8]MouseState,
    frameTime: f32,

    // Keyboard
    pub fn getKeyState(self: *const InputHandler, key: KeyCode) KeyState {
        return self.keyStates[@intFromEnum(key)];
    }

    pub fn isKeyPressed(self: *const InputHandler, key: KeyCode) bool {
        return self.getKeyState(key).isPressed;
    }

    pub fn keyJustPressed(self: *const InputHandler, key: KeyCode) bool {
        return self.getKeyState(key).justPressed();
    }

    pub fn keyJustReleased(self: *const InputHandler, key: KeyCode) bool {
        return self.getKeyState(key).justReleased();
    }

    // Mouse
    pub fn getMouseState(self: *const InputHandler, button: MouseButton) MouseState {
        return self.mouseStates[@intFromEnum(button)];
    }

    pub fn isMousePressed(self: *const InputHandler, button: MouseButton) bool {
        return self.getMouseState(button).isPressed;
    }

    pub fn mouseJustPressed(self: *const InputHandler, button: MouseButton) bool {
        return self.getMouseState(button).justPressed();
    }

    pub fn mouseJustReleased(self: *const InputHandler, button: MouseButton) bool {
        return self.getMouseState(button).justReleased();
    }
    // TODO: GamePad

    pub fn processInputEvent(self: *InputHandler, event: InputEvent) void {
        switch (event) {
            .key => |k| {
                var state = &self.keyStates[@intFromEnum(k.keyCode)];
                state.isPressed = k.isPressed;
                if (self.keyJustPressed(k.keyCode)) {
                    state.pressDuration = 0;
                }

                std.debug.print("IMMEDIATE: isPressed={}, wasPressed={}\n", .{ state.isPressed, state.wasPressed });
            },
            .mouse => |m| {
                var state = &self.mouseStates[@intFromEnum(m.button)];
                state.isPressed = m.isPressed;
                if (self.mouseJustPressed(m.button)) {
                    state.pressDuration = 0;
                }
            },
        }
        return;
    }

    pub fn update(self: *InputHandler, dt: f32) void {
        for (&self.keyStates) |*state| {
            state.wasPressed = state.isPressed;
            if (state.isPressed) state.pressDuration += dt;
        }
        for (&self.mouseStates) |*state| {
            state.wasPressed = state.isPressed;
            if (state.isPressed) state.pressDuration += dt;
        }
    }

    pub fn init() InputHandler {
        return .{
            .keyStates = [_]KeyState{KeyState{}} ** 124,
            .mouseStates = [_]MouseState{MouseState{}} ** 8,
            .frameTime = 0,
        };
    }

    // TODO: private helpers
};
