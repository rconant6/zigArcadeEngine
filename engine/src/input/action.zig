const std = @import("std");

const input = @import("input.zig");
const InputManager = input.InputManager;
const InputSource = input.InputSource;
const V2 = input.V2;

pub fn ActionBinding(comptime ActionType: type) type {
    return struct {
        action: ActionType,
        source: InputSource,
        sensitivity: f32 = 1.0,
        deadzone: f32 = 0.0,
    };
}

pub fn ActionManager(comptime ActionType: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        inputManager: *InputManager,
        bindings: std.ArrayList(ActionBinding(ActionType)),
        enable: bool,

        // Lifecycle
        pub fn init(allocator: std.mem.Allocator, inputManger: *InputManager) Self {
            return Self{
                .allocator = allocator,
                .inputManager = inputManger,
                .bindings = std.ArrayList(ActionBinding(ActionType)).init(allocator),
                .enable = true,
            };
        }
        pub fn deinit(self: *Self) void {
            self.bindings.deinit();
        }

        // Frame processing
        pub fn update(self: *Self, dt: f32) void {
            _ = self;
            _ = dt;
        }

        // Binding management
        pub fn addBinding(self: *Self, binding: ActionBinding(ActionType)) !void {
            try self.bindings.append(binding);
        }
        pub fn removeBinding(self: *Self, action: ActionType) void {
            _ = self;
            _ = action;
        }
        pub fn clearBindings(self: *Self) void {
            _ = self;
        }
        pub fn getBindings(self: *const Self) []const ActionBinding {
            _ = self;
        }

        // Action queries
        pub fn isActionPressed(self: *const Self, action: ActionType) bool {
            for (self.bindings.items) |binding| {
                if (std.meta.eql(binding.action, action)) {
                    return self.inputManager.isInputPressed(binding.source);
                }
            }
            return false;
        }
        pub fn wasActionJustPressed(self: *const Self, action: ActionType) bool {
            for (self.bindings.items) |binding| {
                if (std.meta.eql(binding.action, action)) {
                    return self.inputManager.wasInputJustPressed(binding.source);
                }
            }
            return false;
        }
        pub fn wasActionJustReleased(self: *const Self, action: ActionType) bool {
            for (self.bindings.items) |binding| {
                if (std.meta.eql(binding.action, action)) {
                    return self.inputManager.wasInputJustPressed(binding.source);
                }
            }
            return false;
        }
        pub fn getActionValue(self: *const Self, action: ActionType) f32 {
            _ = self;
            _ = action;
        }
        pub fn getActionVector(self: *const Self, action: ActionType) V2 {
            _ = self;
            _ = action;
        }
    };
}
