const std = @import("std");
pub const c = @cImport({
    @cInclude("/Users/randy/Developer/zig/arcadeEngine/engine/src/platform/MacOS/Sources/CBridge/kb/include/kbBridge.h");
    @cInclude("/Users/randy/Developer/zig/arcadeEngine/engine/src/platform/MacOS/Sources/CBridge/w/include/wBridge.h");
    @cInclude("/Users/randy/Developer/zig/arcadeEngine/engine/src/platform/MacOS/Sources/CBridge/mouse/include/mouseBridge.h");
});

const key = @import("keyboard.zig");
pub const Keyboard = key.Keyboard;
pub const KeyCode = key.KeyCode;
pub const KeyEvent = key.KeyEvent;

const win = @import("window.zig");
pub const Window = win.Window;
pub const WindowConfig = win.WindowConfig;

const mouse = @import("mouse.zig");
pub const Mouse = mouse.Mouse;
pub const MouseEvent = mouse.MouseEvent;
pub const MouseButton = mouse.MouseButton;

const input = @import("inputTracker.zig");
pub const InputHandler = input.InputHandler;
pub const InputEvent = input.InputEvent;
