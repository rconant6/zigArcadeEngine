const std = @import("std");

const plat = @import("platform");
const Keyboard = plat.Keyboard;
const KeyCode = plat.KeyCode;
const Mouse = plat.Mouse;
const MouseAxis = plat.MouseAxis;
const MouseButton = plat.MouseButton;

pub const InputSource = union(enum) {
    Key: KeyCode,
    MouseButton: MouseButton,
    MouseAxis: MouseAxis,
    KeyCombo: struct {
        modifier: KeyCode,
        key: KeyCode,
    },
    MouseCombo: struct {
        modifier: KeyCode,
        button: MouseButton,
    },
};

pub const InputManager = struct {
    mouse: Mouse,
    keyboard: Keyboard,

    pub fn pollEvents(self: *InputManager) void {
        _ = self.mouse.pollEvents();
        _ = self.keyboard.pollEvents();
    }

    pub fn processEvents(self: *InputManager) void {
        self.mouse.processEvents();
        self.keyboard.processEvents();
    }

    pub fn update(self: *InputManager, dt: f32) void {
        self.mouse.update(dt);
        self.keyboard.update(dt);
    }

    pub fn init(width: i32, height: i32) !InputManager {
        const mouse = try Mouse.init();
        mouse.setWindowDimensions(width, height);

        const keyboard = try Keyboard.init();

        return InputManager{
            .mouse = mouse,
            .keyboard = keyboard,
        };
    }

    pub fn deinit(self: *InputManager) void {
        self.mouse.deinit();
        self.keyboard.deinit();
    }
};
