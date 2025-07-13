const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mathModule = b.addModule("math", .{
        .root_source_file = b.path("src/math/math.zig"),
    });
    const rendererModule = b.addModule("renderer", .{
        .root_source_file = b.path("src/renderer/renderer.zig"),
    });
    const ecsModule = b.addModule("ecs", .{
        .root_source_file = b.path("src/ecs/ecs.zig"),
    });
    const assetModule = b.addModule("asset", .{
        .root_source_file = b.path("src/assets/assets.zig"),
    });

    const engine = b.addStaticLibrary(.{
        .name = "engine",
        .root_source_file = b.path("src/engine.zig"),
        .target = target,
        .optimize = optimize,
    });

    engine.root_module.addImport("math", mathModule);

    rendererModule.addImport("math", mathModule);
    engine.root_module.addImport("renderer", rendererModule);

    assetModule.addImport("math", mathModule);
    engine.root_module.addImport("asset", assetModule);

    ecsModule.addImport("math", mathModule);
    ecsModule.addImport("renderer", rendererModule);
    engine.root_module.addImport("ecs", ecsModule);

    b.installArtifact(engine);
}
