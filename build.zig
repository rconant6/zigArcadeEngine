const std = @import("std");
const rlz = @import("raylib_zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zasteroids",
        .root_source_file = b.path("game/main.zig"),
        .optimize = optimize,
        .target = target,
    });

    // MACOS bridging dynamic library
    exe.addLibraryPath(b.path("MacOS/.build/arm64-apple-macosx/release"));
    exe.addIncludePath(b.path("MacOS/Sources/CBridge/include"));
    exe.linkSystemLibrary("Bridge");
    exe.linkFramework("Cocoa");

    const keyboard_module = b.createModule(.{
        .root_source_file = b.path("game/bridge.zig"),
    });
    exe.root_module.addImport("keyboard", keyboard_module);

    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run zasteroids");
    run_step.dependOn(&run_cmd.step);

    b.installArtifact(exe);
}
