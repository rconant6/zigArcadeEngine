const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Platform detection and bridge setup
    const target_info = target.result;
    const engine = b.addStaticLibrary(.{
        .name = "engine",
        .root_source_file = b.path("engine/src/engine.zig"),
        .target = target,
        .optimize = optimize,
    });

    switch (target_info.os.tag) {
        .macos => {
            const arch_string = switch (target_info.cpu.arch) {
                .aarch64 => "arm64",
                .x86_64 => "x86_64",
                else => @panic("Unsupported architecture for macOS Swift bridge"),
            };

            const swiftBuildStep = b.addSystemCommand(&[_][]const u8{
                "swift", "build",
                "-c",    "release",
            });
            swiftBuildStep.setCwd(b.path("engine/src/platform/MacOS"));

            const sourceLibPath = std.fmt.allocPrint(
                b.allocator,
                "engine/src/platform/MacOS/.build/{s}-apple-macosx/release/libmacOSBridge.dylib",
                .{arch_string},
            ) catch @panic("Failed to allocate source library path");

            const copyLibStep = b.addInstallFile(b.path(sourceLibPath), "lib/libmacOSBridge.dylib");
            copyLibStep.step.dependOn(&swiftBuildStep.step);

            engine.step.dependOn(&copyLibStep.step);

            engine.addLibraryPath(b.path("zig-out/lib"));
            engine.linkSystemLibrary("macOSBridge");
            engine.linkFramework("Cocoa");
        },
        .windows => {
            @panic("Windows platform bridge not implemented yet");
        },
        .linux => {
            @panic("Linux platform bridge not implemented yet");
        },
        else => {
            @panic("Unsupported platform for engine bridge");
        },
    }

    // MARK: Module Loading
    const mathModule = b.addModule("math", .{
        .root_source_file = b.path("engine/src/math/math.zig"),
    });
    const platformModule = b.addModule("platform", .{
        .root_source_file = b.path("engine/src/platform/platform.zig"),
    });
    const inputModule = b.addModule("input", .{
        .root_source_file = b.path("engine/src/input/input.zig"),
    });
    const rendererModule = b.addModule("renderer", .{
        .root_source_file = b.path("engine/src/renderer/renderer.zig"),
    });
    const ecsModule = b.addModule("ecs", .{
        .root_source_file = b.path("engine/src/ecs/ecs.zig"),
    });
    const assetModule = b.addModule("asset", .{
        .root_source_file = b.path("engine/src/assets/assets.zig"),
    });

    engine.root_module.addImport("math", mathModule);

    platformModule.addImport("math", mathModule);
    engine.root_module.addImport("platform", platformModule);

    inputModule.addImport("platform", platformModule);
    engine.root_module.addImport("input", inputModule);

    rendererModule.addImport("math", mathModule);
    engine.root_module.addImport("renderer", rendererModule);

    assetModule.addImport("math", mathModule);
    engine.root_module.addImport("asset", assetModule);

    ecsModule.addImport("math", mathModule);
    ecsModule.addImport("renderer", rendererModule);
    engine.root_module.addImport("ecs", ecsModule);

    // Zasteroids game executable
    const zasteroids = b.addExecutable(.{
        .name = "zasteroids",
        .root_source_file = b.path("zasteroids/src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // After creating zasteroids executable, add platform linking
    switch (target_info.os.tag) {
        .macos => {
            zasteroids.addLibraryPath(b.path("zig-out/lib"));
            zasteroids.linkSystemLibrary("macOSBridge");
            zasteroids.linkFramework("Cocoa");
        },
        .windows => {
            @panic("Windows platform bridge not implemented yet");
        },
        .linux => {
            @panic("Linux platform bridge not implemented yet");
        },
        else => {
            @panic("Unsupported platform for engine bridge");
        },
    }

    // Link engine library and add module imports
    zasteroids.linkLibrary(engine);
    zasteroids.root_module.addImport("math", mathModule);
    zasteroids.root_module.addImport("platform", platformModule);
    zasteroids.root_module.addImport("input", inputModule);
    zasteroids.root_module.addImport("asset", assetModule);
    zasteroids.root_module.addImport("ecs", ecsModule);
    zasteroids.root_module.addImport("renderer", rendererModule);

    // Install targets
    const install_zasteroids = b.addInstallArtifact(zasteroids, .{});

    // Default build includes zasteroids
    b.getInstallStep().dependOn(&install_zasteroids.step);

    // Zasteroids-specific build step
    const zasteroids_step = b.step("zasteroids", "Build zasteroids game");
    zasteroids_step.dependOn(&install_zasteroids.step);

    // Run step
    const run_zasteroids = b.addRunArtifact(zasteroids);
    const zasteroids_run_step = b.step("zasteroids-run", "Run zasteroids game");
    zasteroids_run_step.dependOn(&run_zasteroids.step);

    b.installArtifact(engine);
}
