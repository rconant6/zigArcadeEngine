const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // TODO: add the copy of resources in

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

    // Copy assets that are required by the game
    const install_resources = b.addInstallDirectory(.{
        .source_dir = b.path("game/resources"),
        .install_dir = .bin,
        .install_subdir = "resources",
    });
    exe.step.dependOn(&install_resources.step);

    // Add individual modules for each file your tests need
    const renderer_mod = b.createModule(.{
        .root_source_file = b.path("game/renderer.zig"),
    });
    const ecs_mod = b.createModule(.{
        .root_source_file = b.path("game/ecs.zig"),
    });
    const asset_mod = b.createModule(.{
        .root_source_file = b.path("game/assets.zig"),
    });
    exe.root_module.addImport("renderer", renderer_mod);
    exe.root_module.addImport("ecs", ecs_mod);
    exe.root_module.addImport("asset", asset_mod);

    const run_cmd = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run zasteroids");
    run_step.dependOn(&run_cmd.step);

    // addTestStep(b, "test", "Run all tests", "tests/main.zig", target, optimize);
    // addTestStep(b, "test-entity", "Run entity tests", "tests/entity.zig", target, optimize);
    // addTestStep(b, "test-component", "Run component tests", "tests/component.zig", target, optimize);
    // addTestStep(b, "test-render", "Run render tests", "tests/render.zig", target, optimize);

    b.installArtifact(exe);
}

fn addTestStep(
    b: *std.Build,
    name: []const u8,
    description: []const u8,
    rootFile: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) void {
    const testStep = b.step(name, description);

    const unitTests = b.addTest(.{
        .root_source_file = b.path(rootFile),
        .target = target,
        .optimize = optimize,
    });

    // Add individual modules for each file your tests need
    const renderer_mod = b.createModule(.{
        .root_source_file = b.path("game/renderer.zig"),
    });
    const ecs_mod = b.createModule(.{
        .root_source_file = b.path("game/ecs.zig"),
    });
    ecs_mod.addImport("renderer", renderer_mod);

    unitTests.root_module.addImport("renderer", renderer_mod);
    unitTests.root_module.addImport("ecs", ecs_mod);
    const run_tests = b.addRunArtifact(unitTests);

    // run_tests.addArgs(&.{ "--verbose", "--summary all" });

    testStep.dependOn(&run_tests.step);
}
