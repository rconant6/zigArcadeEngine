pub const std = @import("std");
const builtin = @import("builtin");

pub const plat = @import("platform.zig");
const c = plat.c;

const MAX_KEYS = 256;
pub const ModifierFlags = packed struct {
    shift: u1 = 0,
    control: u1 = 0,
    option: u1 = 0,
    command: u1 = 0,
    padding: u4 = 0,
};

pub const KeyboardState = struct {
    keysPressed: [MAX_KEYS]bool,
    keysJustPressed: [MAX_KEYS]bool,
    keysJustReleased: [MAX_KEYS]bool,
    modifiers: ModifierFlags,
    lastUpdateTime: u64,
};

pub const Keyboard = struct {
    state: KeyboardState,
    batchData: c.kbEventBatch,

    pub fn startMonitoring(self: *const Keyboard) bool {
        _ = self;
        return c.kb_startKeyboardMonitoring() == 1;
    }
    pub fn stopMonitoring(self: *const Keyboard) void {
        _ = self;
        c.kb_stopKeyboardMonitoring();
    }

    pub fn pollEvents(self: *Keyboard) u8 {
        return c.kb_pollKeyboardEventBatch(&self.batchData);
    }

    pub fn processEvents(self: *Keyboard) void {
        const eventCount: usize = @intCast(self.batchData.eventCount);

        for (self.batchData.events[0..eventCount]) |cEvent| {
            const index: usize = @intCast(@intFromEnum(mapToGameKeyCode(cEvent.code)));

            self.state.modifiers = @bitCast(cEvent.modifiers);

            std.debug.print("Raw modifier byte: 0b{b:0>8}\n", .{cEvent.modifiers});
            std.debug.print("Parsed modifiers: shift={} ctrl={} opt={} cmd={}\n", .{
                self.state.modifiers.shift,
                self.state.modifiers.control,
                self.state.modifiers.option,
                self.state.modifiers.command,
            });
            switch (cEvent.eventType) {
                c.KB_KEY_PRESS => {
                    updateKeyPress(
                        &self.state.keysPressed[index],
                        &self.state.keysJustPressed[index],
                        &self.state.keysJustReleased[index],
                    );
                    std.debug.print("Key Pressed:{any}  Index: {d}   Pressed: {any} Just Pressed: {any}, JustReleased: {any}\n", .{
                        mapToGameKeyCode(cEvent.code),
                        index,
                        self.state.keysPressed[index],
                        self.state.keysJustPressed[index],
                        self.state.keysJustReleased[index],
                    });
                },
                c.KB_KEY_RELEASE => {
                    updateKeyRelease(
                        &self.state.keysPressed[index],
                        &self.state.keysJustPressed[index],
                        &self.state.keysJustReleased[index],
                    );
                    std.debug.print("Key Released:{any}  Index: {d}   Pressed: {any} Just Pressed: {any}, JustReleased: {any}\n", .{
                        mapToGameKeyCode(cEvent.code),
                        index,
                        self.state.keysPressed[index],
                        self.state.keysJustPressed[index],
                        self.state.keysJustReleased[index],
                    });
                },
                else => {},
            }
        }
    }

    pub fn isKeyPressed(self: *const Keyboard, key: KeyCode) bool {
        return self.state.keysPressed[@intFromEnum(key)];
    }
    pub fn wasKeyJustPressed(self: *const Keyboard, key: KeyCode) bool {
        return self.state.keysJustPressed[@intFromEnum(key)];
    }
    pub fn wasKeyJustReleased(self: *const Keyboard, key: KeyCode) bool {
        return self.state.keysJustReleased[@intFromEnum(key)];
    }

    pub fn isShiftPressed(self: *const Keyboard) bool {
        return self.state.modifiers.shift == 1;
    }
    pub fn isCtrlPressed(self: *const Keyboard) bool {
        return self.state.modifiers.control == 1;
    }
    pub fn isOptionPressed(self: *const Keyboard) bool {
        return self.state.modifiers.option == 1;
    }
    pub fn isCommandPressed(self: *const Keyboard) bool {
        return self.state.modifiers.command == 1;
    }

    fn updateKeyPress(pressed: *bool, justPressed: *bool, justReleased: *bool) void {
        justPressed.* = !pressed.*;
        pressed.* = true;
        justReleased.* = false;
    }

    fn updateKeyRelease(pressed: *bool, justPressed: *bool, justReleased: *bool) void {
        justReleased.* = pressed.*;
        pressed.* = false;
        justPressed.* = false;
    }

    pub fn update(self: *Keyboard, dt: f32) void {
        _ = dt; // unused for now

        for (&self.state.keysJustPressed) |*just| {
            just.* = false;
        }
        for (&self.state.keysJustReleased) |*just| {
            just.* = false;
        }
    }

    pub fn init() !Keyboard {
        const keyboard = Keyboard{
            .state = KeyboardState{
                .keysPressed = .{false} ** MAX_KEYS,
                .keysJustPressed = .{false} ** MAX_KEYS,
                .keysJustReleased = .{false} ** MAX_KEYS,
                .modifiers = ModifierFlags{},
                .lastUpdateTime = 0,
            },
            .batchData = c.kbEventBatch{},
        };
        if (!keyboard.startMonitoring()) return error.KeyboardMonitoringFailed;

        return keyboard;
    }

    pub fn deinit(self: *Keyboard) void {
        self.stopMonitoring();
    }
};

// MARK: Keyboard Bridging
pub const KeyCode = enum(u8) {
    Key0 = 0,
    Key1 = 1,
    Key2 = 2,
    Key3 = 3,
    Key4 = 4,
    Key5 = 5,
    Key6 = 6,
    Key7 = 7,
    Key8 = 8,
    Key9 = 9,
    A = 10,
    B = 11,
    C = 12,
    D = 13,
    E = 14,
    F = 15,
    G = 16,
    H = 17,
    I = 18,
    J = 20,
    K = 21,
    L = 22,
    M = 23,
    N = 24,
    O = 25,
    P = 26,
    Q = 27,
    R = 28,
    S = 29,
    T = 30,
    U = 31,
    V = 32,
    W = 33,
    X = 34,
    Y = 35,
    Z = 36,
    Left = 41,
    Right = 42,
    Up = 43,
    Down = 44,
    F1 = 45,
    F2 = 46,
    F3 = 47,
    F4 = 48,
    F5 = 49,
    F6 = 50,
    F7 = 51,
    F8 = 52,
    F9 = 53,
    F10 = 54,
    F11 = 55,
    F12 = 56,
    Enter = 57,
    Space = 58,
    Esc = 59,
    Tab = 60,
    Backspace = 61,
    Delete = 62,
    LeftShift = 63,
    RightShift = 64,
    LeftCtrl = 65,
    RightCtrl = 66,
    LeftAlt = 67,
    RightAlt = 68,
    LeftCmd = 69,
    RightCmd = 70,
    Semicolon = 71,
    Quote = 72,
    Comma = 73,
    Period = 74,
    Slash = 75,
    Grave = 76,
    Minus = 77,
    Equal = 78,
    LeftBracket = 79,
    RightBracket = 80,
    Backslash = 81,
    Numpad0 = 91,
    Numpad1 = 92,
    Numpad2 = 93,
    Numpad3 = 94,
    Numpad4 = 95,
    Numpad5 = 96,
    Numpad6 = 97,
    Numpad7 = 98,
    Numpad8 = 99,
    Numpad9 = 100,
    NumpadPlus = 101,
    NumpadMinus = 102,
    NumpadMultiply = 103,
    NumpadDivide = 104,
    NumpadEnter = 105,
    NumpadDecimal = 106,
    NumLock = 107,
    NumpadClear = 108,
    NumpadEqual = 109,
    Unused = 120,
};

inline fn mapToGameKeyCode(osKeyCode: u16) KeyCode {
    return switch (comptime builtin.os.tag) {
        .macos => switch (osKeyCode) {
            // Letters A-Z
            0x00 => .A,
            0x0B => .B,
            0x08 => .C,
            0x02 => .D,
            0x0E => .E,
            0x03 => .F,
            0x05 => .G,
            0x04 => .H,
            0x22 => .I,
            0x26 => .J,
            0x28 => .K,
            0x25 => .L,
            0x2E => .M,
            0x2D => .N,
            0x1F => .O,
            0x23 => .P,
            0x0C => .Q,
            0x0F => .R,
            0x01 => .S,
            0x11 => .T,
            0x20 => .U,
            0x09 => .V,
            0x0D => .W,
            0x07 => .X,
            0x10 => .Y,
            0x06 => .Z,

            // Numbers 0-9
            0x1D => .Key0,
            0x12 => .Key1,
            0x13 => .Key2,
            0x14 => .Key3,
            0x15 => .Key4,
            0x17 => .Key5,
            0x16 => .Key6,
            0x1A => .Key7,
            0x1C => .Key8,
            0x19 => .Key9,

            // Arrow keys
            0x7B => .Left,
            0x7C => .Right,
            0x7E => .Up,
            0x7D => .Down,

            // Function keys
            0x7A => .F1,
            0x78 => .F2,
            0x63 => .F3,
            0x76 => .F4,
            0x60 => .F5,
            0x61 => .F6,
            0x62 => .F7,
            0x64 => .F8,
            0x65 => .F9,
            0x6D => .F10,
            0x67 => .F11,
            0x6F => .F12,

            // Special keys
            0x24 => .Enter,
            0x31 => .Space,
            0x35 => .Esc,
            0x30 => .Tab,
            0x33 => .Backspace,
            0x75 => .Delete,
            0x38 => .LeftShift,
            0x3C => .RightShift,
            0x3B => .LeftCtrl,
            0x3E => .RightCtrl,
            0x3A => .LeftAlt,
            0x3D => .RightAlt,
            0x37 => .LeftCmd,
            0x36 => .RightCmd,

            // Punctuation
            0x27 => .Semicolon,
            0x29 => .Quote,
            0x2B => .Comma,
            0x2F => .Period,
            0x2C => .Slash,
            0x32 => .Grave,
            0x1B => .Minus,
            0x18 => .Equal,
            0x21 => .LeftBracket,
            0x1E => .RightBracket,
            0x2A => .Backslash,

            // Number pad
            0x52 => .Numpad0,
            0x53 => .Numpad1,
            0x54 => .Numpad2,
            0x55 => .Numpad3,
            0x56 => .Numpad4,
            0x57 => .Numpad5,
            0x58 => .Numpad6,
            0x59 => .Numpad7,
            0x5B => .Numpad8,
            0x5C => .Numpad9,
            0x45 => .NumpadPlus,
            0x4E => .NumpadMinus,
            0x43 => .NumpadMultiply,
            0x4B => .NumpadDivide,
            0x4C => .NumpadEnter,
            0x41 => .NumpadDecimal,
            0x47 => .NumpadClear,
            0x51 => .NumpadEqual,

            else => .Unused,
        },

        .windows => switch (osKeyCode) {
            // Letters A-Z (Windows Virtual Key Codes)
            0x41 => .A,
            0x42 => .B,
            0x43 => .C,
            0x44 => .D,
            0x45 => .E,
            0x46 => .F,
            0x47 => .G,
            0x48 => .H,
            0x49 => .I,
            0x4A => .J,
            0x4B => .K,
            0x4C => .L,
            0x4D => .M,
            0x4E => .N,
            0x4F => .O,
            0x50 => .P,
            0x51 => .Q,
            0x52 => .R,
            0x53 => .S,
            0x54 => .T,
            0x55 => .U,
            0x56 => .V,
            0x57 => .W,
            0x58 => .X,
            0x59 => .Y,
            0x5A => .Z,

            // Numbers 0-9
            0x30 => .Key0,
            0x31 => .Key1,
            0x32 => .Key2,
            0x33 => .Key3,
            0x34 => .Key4,
            0x35 => .Key5,
            0x36 => .Key6,
            0x37 => .Key7,
            0x38 => .Key8,
            0x39 => .Key9,

            // Arrow keys
            0x25 => .Left,
            0x27 => .Right,
            0x26 => .Up,
            0x28 => .Down,

            // Function keys
            0x70 => .F1,
            0x71 => .F2,
            0x72 => .F3,
            0x73 => .F4,
            0x74 => .F5,
            0x75 => .F6,
            0x76 => .F7,
            0x77 => .F8,
            0x78 => .F9,
            0x79 => .F10,
            0x7A => .F11,
            0x7B => .F12,

            // Special keys
            0x0D => .Enter,
            0x20 => .Space,
            0x1B => .Esc,
            0x09 => .Tab,
            0x08 => .Backspace,
            0x2E => .Delete,
            0x10 => .LeftShift,
            0xA1 => .RightShift,
            0x11 => .LeftCtrl,
            0xA3 => .RightCtrl,
            0x12 => .LeftAlt,
            0xA5 => .RightAlt,
            0x5B => .LeftCmd,
            0x5C => .RightCmd,

            // Punctuation
            0xBA => .Semicolon,
            0xDE => .Quote,
            0xBC => .Comma,
            0xBE => .Period,
            0xBF => .Slash,
            0xC0 => .Grave,
            0xBD => .Minus,
            0xBB => .Equal,
            0xDB => .LeftBracket,
            0xDD => .RightBracket,
            0xDC => .Backslash,

            // Number pad
            0x60 => .Numpad0,
            0x61 => .Numpad1,
            0x62 => .Numpad2,
            0x63 => .Numpad3,
            0x64 => .Numpad4,
            0x65 => .Numpad5,
            0x66 => .Numpad6,
            0x67 => .Numpad7,
            0x68 => .Numpad8,
            0x69 => .Numpad9,
            0x6B => .NumpadPlus,
            0x6D => .NumpadMinus,
            0x6A => .NumpadMultiply,
            0x6F => .NumpadDivide,
            0x0D => .NumpadEnter,
            0x6E => .NumpadDecimal,
            0x90 => .NumLock,

            else => .Unused,
        },

        .linux => switch (osKeyCode) {
            // Letters a-z (X11 keysyms - lowercase)
            0x61 => .A,
            0x62 => .B,
            0x63 => .C,
            0x64 => .D,
            0x65 => .E,
            0x66 => .F,
            0x67 => .G,
            0x68 => .H,
            0x69 => .I,
            0x6A => .J,
            0x6B => .K,
            0x6C => .L,
            0x6D => .M,
            0x6E => .N,
            0x6F => .O,
            0x70 => .P,
            0x71 => .Q,
            0x72 => .R,
            0x73 => .S,
            0x74 => .T,
            0x75 => .U,
            0x76 => .V,
            0x77 => .W,
            0x78 => .X,
            0x79 => .Y,
            0x7A => .Z,

            // Numbers 0-9
            0x30 => .Key0,
            0x31 => .Key1,
            0x32 => .Key2,
            0x33 => .Key3,
            0x34 => .Key4,
            0x35 => .Key5,
            0x36 => .Key6,
            0x37 => .Key7,
            0x38 => .Key8,
            0x39 => .Key9,

            // Arrow keys
            0xFF51 => .Left,
            0xFF53 => .Right,
            0xFF52 => .Up,
            0xFF54 => .Down,

            // Function keys
            0xFFBE => .F1,
            0xFFBF => .F2,
            0xFFC0 => .F3,
            0xFFC1 => .F4,
            0xFFC2 => .F5,
            0xFFC3 => .F6,
            0xFFC4 => .F7,
            0xFFC5 => .F8,
            0xFFC6 => .F9,
            0xFFC7 => .F10,
            0xFFC8 => .F11,
            0xFFC9 => .F12,

            // Special keys
            0xFF0D => .Enter,
            0x20 => .Space,
            0xFF1B => .Esc,
            0xFF09 => .Tab,
            0xFF08 => .Backspace,
            0xFFFF => .Delete,
            0xFFE1 => .LeftShift,
            0xFFE2 => .RightShift,
            0xFFE3 => .LeftCtrl,
            0xFFE4 => .RightCtrl,
            0xFFE9 => .LeftAlt,
            0xFFEA => .RightAlt,
            0xFFEB => .LeftCmd,
            0xFFEC => .RightCmd,

            // Punctuation
            0x3B => .Semicolon,
            0x27 => .Quote,
            0x2C => .Comma,
            0x2E => .Period,
            0x2F => .Slash,
            0x60 => .Grave,
            0x2D => .Minus,
            0x3D => .Equal,
            0x5B => .LeftBracket,
            0x5D => .RightBracket,
            0x5C => .Backslash,

            // Number pad (X11 keysyms)
            0xFFB0 => .Numpad0,
            0xFFB1 => .Numpad1,
            0xFFB2 => .Numpad2,
            0xFFB3 => .Numpad3,
            0xFFB4 => .Numpad4,
            0xFFB5 => .Numpad5,
            0xFFB6 => .Numpad6,
            0xFFB7 => .Numpad7,
            0xFFB8 => .Numpad8,
            0xFFB9 => .Numpad9,
            0xFFAB => .NumpadPlus,
            0xFFAD => .NumpadMinus,
            0xFFAA => .NumpadMultiply,
            0xFFAF => .NumpadDivide,
            0xFF8D => .NumpadEnter,
            0xFFAE => .NumpadDecimal,
            0xFF7F => .NumLock,

            else => .Unused,
        },

        else => .Unused,
    };
}
