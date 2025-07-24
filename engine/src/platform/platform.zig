const std = @import("std");
pub const c = @cImport({
    @cInclude("/Users/randy/Developer/zig/arcadeEngine/engine/src/platform/MacOS/Sources/CBridge/kb/include/kbBridge.h");
    @cInclude("/Users/randy/Developer/zig/arcadeEngine/engine/src/platform/MacOS/Sources/CBridge/w/include/wBridge.h");
    @cInclude("/Users/randy/Developer/zig/arcadeEngine/engine/src/platform/MacOS/Sources/CBridge/mouse/include/mouseBridge.h");
});

const key = @import("keyboard.zig");
pub const Keyboard = key.Keyboard;
pub const KeyCode = key.KeyCode;

const win = @import("window.zig");
pub const Window = win.Window;
pub const WindowConfig = win.WindowConfig;

const mouse = @import("mouse.zig");
pub const Mouse = mouse.Mouse;
pub const MouseButton = mouse.MouseButton;
pub const MouseAxis = mouse.MouseAxis;

pub const ModifierFlags = packed struct {
    shift: u1 = 0,
    control: u1 = 0,
    option: u1 = 0,
    command: u1 = 0,
    padding: u4 = 0,
};

pub const ModifierKey = enum { Shift, Control, Option, Command };
