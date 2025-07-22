const std = @import("std");
const builtin = @import("builtin");
const math = @import("math");
const V2 = math.V2;

pub const plat = @import("platform.zig");
const c = plat.c;

const MousePosition = V2;
const MouseDelta = V2;

const MAX_MOUSE_EVENTS_PER_FRAME: usize = 16;

pub const MouseButton = enum { Left, Right, Middle, Other1, Other2 };

const ButtonState = packed struct {
    left: u1 = 0,
    right: u1 = 0,
    middle: u1 = 0,
    other1: u1 = 0,
    other2: u1 = 0,
    padding: u3 = 0,
};

pub const MouseState = struct {
    currentPosition: MousePosition,
    lastPosition: MousePosition,

    deltaThisFrame: MouseDelta,
    scrollDeltaThisFrame: MouseDelta,

    buttonsPressed: ButtonState,
    buttonsJustPressed: ButtonState,
    buttonsJustReleased: ButtonState,

    inWindow: bool,

    lastUpdateTime: u64,
};

pub const Mouse = struct {
    state: MouseState,
    batchData: c.mMouseEventBatch,

    pub fn startMonitoring(self: *const Mouse) bool {
        _ = self;
        return c.m_startMouseMonitoring() == 1;
    }
    pub fn stopMonitoring(self: *const Mouse) void {
        _ = self;
        c.m_stopMouseMonitoring();
    }

    pub fn setWindowDimensions(self: *const Mouse, width: i32, height: i32) void {
        _ = self;
        c.m_setWindowDimensions(width, height);
    }

    pub fn pollEvents(self: *Mouse) u8 {
        return c.m_pollMouseEventBatch(&self.batchData);
    }

    fn handleButtonPress(self: *Mouse, cEvent: c.mMouseEvent) void {
        self.state.currentPosition = .{ .x = cEvent.gameX, .y = cEvent.gameY };
        switch (cEvent.button) {
            c.M_BUTTON_LEFT => updateButtonPress(&self.state.buttonsPressed.left, &self.state.buttonsJustPressed.left, &self.state.buttonsJustReleased.left),
            c.M_BUTTON_RIGHT => updateButtonPress(&self.state.buttonsPressed.right, &self.state.buttonsJustPressed.right, &self.state.buttonsJustReleased.right),
            c.M_BUTTON_MIDDLE => updateButtonPress(&self.state.buttonsPressed.middle, &self.state.buttonsJustPressed.middle, &self.state.buttonsJustReleased.middle),
            c.M_BUTTON_EXTRA1 => updateButtonPress(&self.state.buttonsPressed.other1, &self.state.buttonsJustPressed.other1, &self.state.buttonsJustReleased.other1),
            c.M_BUTTON_EXTRA2 => updateButtonPress(&self.state.buttonsPressed.other2, &self.state.buttonsJustPressed.other2, &self.state.buttonsJustReleased.other2),
            else => {},
        }
        self.state.lastUpdateTime = cEvent.timestamp;
    }

    fn updateButtonPress(pressed: anytype, justPressed: anytype, justReleased: anytype) void {
        justPressed.* = if (pressed.* == 0) 1 else 0;
        pressed.* = 1;
        justReleased.* = 0;
    }

    fn handleButtonRelease(self: *Mouse, cEvent: c.mMouseEvent) void {
        self.state.currentPosition = .{ .x = cEvent.gameX, .y = cEvent.gameY };
        switch (cEvent.button) {
            c.M_BUTTON_LEFT => updateButtonRelease(&self.state.buttonsPressed.left, &self.state.buttonsJustPressed.left, &self.state.buttonsJustReleased.left),
            c.M_BUTTON_RIGHT => updateButtonRelease(&self.state.buttonsPressed.right, &self.state.buttonsJustPressed.right, &self.state.buttonsJustReleased.right),
            c.M_BUTTON_MIDDLE => updateButtonRelease(&self.state.buttonsPressed.middle, &self.state.buttonsJustPressed.middle, &self.state.buttonsJustReleased.middle),
            c.M_BUTTON_EXTRA1 => updateButtonRelease(&self.state.buttonsPressed.other1, &self.state.buttonsJustPressed.other1, &self.state.buttonsJustReleased.other1),
            c.M_BUTTON_EXTRA2 => updateButtonRelease(&self.state.buttonsPressed.other2, &self.state.buttonsJustPressed.other2, &self.state.buttonsJustReleased.other2),
            else => {},
        }
        self.state.lastUpdateTime = cEvent.timestamp;
    }

    fn updateButtonRelease(pressed: anytype, justPressed: anytype, justReleased: anytype) void {
        justReleased.* = if (pressed.* == 1) 1 else 0;
        pressed.* = 0;
        justPressed.* = 0;
    }

    fn handleScroll(self: *Mouse, cEvent: c.mMouseEvent) void {
        self.state.currentPosition = .{ .x = cEvent.gameX, .y = cEvent.gameY };
        self.state.scrollDeltaThisFrame = .{ .x = cEvent.scrollDeltaX, .y = cEvent.scrollDeltaY };
        self.state.lastUpdateTime = cEvent.timestamp;
    }

    fn handleMove(self: *Mouse, cEvent: c.mMouseEvent) void {
        self.state.currentPosition = .{ .x = cEvent.gameX, .y = cEvent.gameY };
        self.state.deltaThisFrame = self.state.deltaThisFrame.add(.{ .x = cEvent.deltaX, .y = cEvent.deltaY });
        self.state.lastUpdateTime = cEvent.timestamp;
    }

    pub fn processEvents(self: *Mouse) void {
        const eventCount: usize = @intCast(self.batchData.eventCount);

        for (self.batchData.events[0..eventCount]) |cEvent| {
            switch (cEvent.eventType) {
                c.M_BUTTON_PRESS => self.handleButtonPress(cEvent),
                c.M_BUTTON_RELEASE => self.handleButtonRelease(cEvent),
                c.M_MOVE => self.handleMove(cEvent),
                c.M_SCROLL => self.handleScroll(cEvent),
                c.M_ENTER_WINDOW => self.state.inWindow = true,
                c.M_EXIT_WINDOW => self.state.inWindow = false,
                else => {},
            }
        }
    }

    pub fn update(self: *Mouse, dt: f32) void {
        _ = dt; // unused for now

        self.state.buttonsJustPressed = ButtonState{};
        self.state.buttonsJustReleased = ButtonState{};

        self.state.deltaThisFrame = .{ .x = 0, .y = 0 };
        self.state.scrollDeltaThisFrame = .{ .x = 0, .y = 0 };

        self.state.lastPosition = self.state.currentPosition;
    }

    pub fn isButtonPressed(self: *const Mouse, button: MouseButton) bool {
        return switch (button) {
            .Left => self.state.buttonsPressed.left == 1,
            .Right => self.state.buttonsPressed.right == 1,
            .Middle => self.state.buttonsPressed.middle == 1,
            .Other1 => self.state.buttonsPressed.other1 == 1,
            .Other2 => self.state.buttonsPressed.other2 == 1,
        };
    }

    pub fn wasButtonJustReleased(self: *const Mouse, button: MouseButton) bool {
        return switch (button) {
            .Left => self.state.buttonsJustReleased.left == 1,
            .Right => self.state.buttonsJustReleased.right == 1,
            .Middle => self.state.buttonsJustReleased.middle == 1,
            .Other1 => self.state.buttonsJustReleased.other1 == 1,
            .Other2 => self.state.buttonsJustReleased.other2 == 1,
        };
    }

    pub fn wasButtonJustPressed(self: *const Mouse, button: MouseButton) bool {
        return switch (button) {
            .Left => self.state.buttonsJustPressed.left == 1,
            .Right => self.state.buttonsJustPressed.right == 1,
            .Middle => self.state.buttonsJustPressed.middle == 1,
            .Other1 => self.state.buttonsJustPressed.other1 == 1,
            .Other2 => self.state.buttonsJustPressed.other2 == 1,
        };
    }

    pub fn getPosition(self: *const Mouse) MousePosition {
        return self.state.currentPosition;
    }

    pub fn getDelta(self: *const Mouse) MouseDelta {
        return self.state.deltaThisFrame;
    }

    pub fn getScrollData(self: *const Mouse) MouseDelta {
        return self.state.scrollDeltaThisFrame;
    }

    pub fn isInWindow(self: *const Mouse) bool {
        return self.state.inWindow;
    }

    pub fn init() !Mouse {
        const mouse = Mouse{
            .state = MouseState{
                .currentPosition = .{ .x = 0, .y = 0 },
                .lastPosition = .{ .x = 0, .y = 0 },
                .deltaThisFrame = .{ .x = 0, .y = 0 },
                .scrollDeltaThisFrame = .{ .x = 0, .y = 0 },
                .buttonsPressed = ButtonState{},
                .buttonsJustPressed = ButtonState{},
                .buttonsJustReleased = ButtonState{},
                .inWindow = true,
                .lastUpdateTime = 0,
            },
            .batchData = c.mMouseEventBatch{},
        };
        if (!mouse.startMonitoring()) return error.FailedToStartMouseMonitor;
        return mouse;
    }

    pub fn deinit(self: *Mouse) void {
        self.stopMonitoring();
    }
};
