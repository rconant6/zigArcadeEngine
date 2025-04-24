const std = @import("std");
const rlz = @import("raylib_zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    //
    // const raylib_dep = b.dependency("raylib_zig", .{
    //     .target = target,
    //     .optimize = optimize,
    // });
    //
    // const raylib = raylib_dep.module("raylib");
    // const raylib_artifact = raylib_dep.artifact("raylib");
    //

    const exe = b.addExecutable(.{
        .name = "zasteroids",
        .root_source_file = b.path("game/main.zig"),
        .optimize = optimize,
        .target = target,
    });

    // MACOS keyboard stuff
    exe.addLibraryPath(b.path("MacOS/.build/arm64-apple-macosx/release"));
    exe.addIncludePath(b.path("MacOS/Sources/CkbBridge/include"));
    exe.linkSystemLibrary("KeyboardBridge");
    exe.linkFramework("Cocoa");
    // END MACOS keyboard stuff
    //
    // exe.linkLibrary(raylib_artifact);
    // exe.root_module.addImport("raylib", raylib);
    //
    const keyboard_module = b.createModule(.{
        .root_source_file = b.path("game/core/bridge.zig"),
    });
    exe.root_module.addImport("keyboard", keyboard_module);

    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run zasteroids");
    run_step.dependOn(&run_cmd.step);

    // Add a keyboard test executable
    const keyboard_test = b.addExecutable(.{
        .name = "keyboard_test",
        .root_source_file = b.path("game/keyboardTest.zig"),
        .optimize = optimize,
        .target = target,
    });

    // Add the same paths and libraries
    keyboard_test.addLibraryPath(b.path("MacOS/.build/arm64-apple-macosx/release"));
    keyboard_test.addIncludePath(b.path("MacOS/Sources/CkbBridge/include"));
    keyboard_test.linkSystemLibrary("KeyboardBridge");
    keyboard_test.linkFramework("Cocoa");
    // keyboard_test.linkLibrary(raylib_artifact);
    // keyboard_test.root_module.addImport("raylib", raylib);
    keyboard_test.root_module.addImport("keyboard", keyboard_module);

    // Add a run step for the test
    const test_cmd = b.addRunArtifact(keyboard_test);
    const test_step = b.step("test-keyboard", "Run keyboard test");
    test_step.dependOn(&test_cmd.step);

    b.installArtifact(keyboard_test);

    b.installArtifact(exe);
}
