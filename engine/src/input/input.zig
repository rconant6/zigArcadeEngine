const input = @import("inputManager.zig");
pub const InputManager = input.InputManager;

const action = @import("action.zig");
pub const ActionManager = action.ActionManager;

const plat = @import("platform");
pub const Keyboard = plat.Keyboard;
pub const KeyCode = plat.KeyCode;
pub const Mouse = plat.Mouse;
pub const MouseAxis = plat.MouseAxis;
pub const MouseButton = plat.MouseButton;
