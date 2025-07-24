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

pub const InputSystem = struct {
    inputManager: InputManager,
    actionManager: ActionManager,

    // Lifecycle
    pub fn init(allocator: std.mem.Allocator, width: i32, height: i32) !InputSystem {
        const inputManager = try InputManager.init(width, height);
        const actionManager = ActionManager.init(allocator);
        return InputSystem{
            .inputManager = inputManager,
            .actionManager = actionManager,
        };
    }
    pub fn deinit(self: *InputSystem) void {
        self.inputManager.deinit();
        self.actionManager.deinit();
    }

    // TODO: make sure all are covered
    pub fn pollEvents(self: *InputSystem) void {
        self.inputManager.pollEvents();
    }
    pub fn processEvents(self: *InputSystem) void {
        self.inputManager.processEvents();
    }
    pub fn update(self: *InputSystem, dt: f32) void {
        self.inputManager.update(dt);
        self.actionManager.update(dt);
    }

    // TODO: the rest of the wrappers
    pub fn isInputPressed(self: *const InputSystem, source: InputSource) bool {
        return self.inputManager.isInputPressed(source);
    }
    pub fn isActionPressed(self: *const InputSystem, systemName: []const u8, actionName: []const u8) bool {
        _ = self;
        _ = systemName;
        _ = actionName;
    }
    pub fn addBinding(self: *InputSystem, binding: ActionBinding) !void {
        _ = self;
        _ = binding;
    }
};
