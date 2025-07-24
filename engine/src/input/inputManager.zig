const std = @import("std");

const input = @import("input.zig");
const InputSource = input.InputSource;
const Keyboard = input.Keyboard;
const KeyCode = input.KeyCode;
const ModifierKey = input.ModifierKey;
const Mouse = input.Mouse;
const MouseAxis = input.MouseAxis;
const MouseButton = input.MouseButton;
const V2 = input.V2;

pub const InputManager = struct {
    mouse: Mouse,
    keyboard: Keyboard,

    // MARK: Process events from hardware
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

    // MARK: Raw input queries (pass-through to mouse/keyboard)
    pub fn isInputPressed(self: *const InputManager, source: InputSource) bool {
        return switch (source) {
            .Key => |key| self.keyboard.isKeyPressed(key),
            .MouseButton => |btn| self.mouse.isButtonPressed(btn),
            .KeyCombo => |combo| self.keyboard.isModifierPressed(combo.modifier) and self.keyboard.wasKeyJustPressed(combo.key),
            .MouseCombo => |combo| self.mouse.isModifierPressed(combo.modifier) and self.mouse.wasButtonJustPressed(combo.button),
            else => @panic("not Implemented for this type of input thing!"),
        };
    }
    pub fn isKeyPressed(self: *const InputManager, key: KeyCode) bool {
        return self.keyboard.isKeyPressed(key);
    }
    pub fn wasKeyJustPressed(self: *const InputManager, key: KeyCode) bool {
        return self.keyboard.wasKeyJustPressed(key);
    }
    pub fn wasKeyJustReleased(self: *const InputManager, key: KeyCode) bool {
        return self.keyboard.wasKeyJustReleased(key);
    }
    pub fn isModifierPressed(self: *const InputManager, modifier: ModifierKey) bool {
        return self.keyboard.isModifierPressed(modifier);
    }

    pub fn isMouseButtonPressed(self: *const InputManager, button: MouseButton) bool {
        return self.mouse.isButtonPressed(button);
    }
    pub fn wasMouseButtonJustPressed(self: *const InputManager, button: MouseButton) bool {
        return self.mouse.wasButtonJustPressed(button);
    }
    pub fn wasMouseButtonJustReleased(self: *const InputManager, button: MouseButton) bool {
        return self.mouse.wasButtonJustReleased(button);
    }
    pub fn getMousePosition(self: *const InputManager) V2 {
        return self.mouse.getPosition();
    }
    pub fn getMouseDelta(self: *const InputManager) V2 {
        return self.mouse.getDelta();
    }
    pub fn getMouseScrollDelta(self: *const InputManager) V2 {
        return self.mouse.getScrollData();
    }
    pub fn isMouseInWindow(self: *const InputManager) bool {
        return self.mouse.state.inWindow;
    }

    // MARK: setup / teardown
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
