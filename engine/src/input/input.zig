const std = @import("std");

const math = @import("math");
pub const V2 = math.V2;

const input = @import("inputManager.zig");
pub const InputManager = input.InputManager;

const plat = @import("platform");
pub const Keyboard = plat.Keyboard;
pub const KeyCode = plat.KeyCode;
pub const ModifierKey = plat.ModifierKey;

pub const Mouse = plat.Mouse;
pub const MouseAxis = plat.MouseAxis;
pub const MouseButton = plat.MouseButton;

const action = @import("action.zig");
pub const ActionManager = action.ActionManager;
pub const ActionBinding = action.ActionBinding;

pub const InputSource = union(enum) {
    Key: KeyCode,
    MouseButton: MouseButton,
    MouseAxis: MouseAxis,
    KeyCombo: struct {
        modifier: ModifierKey,
        key: KeyCode,
    },
    MouseCombo: struct {
        modifier: ModifierKey,
        button: MouseButton,
    },
};
