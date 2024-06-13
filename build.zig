const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const toml_dep = b.dependency("zig-toml", .{ .optimize = optimize, .target = target });
    const toml_mod = toml_dep.module("zig-toml");

    const exe = b.addExecutable(.{
        .name = "nitrofetch",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);

    const exe_indev = b.addExecutable(.{
        .name = "nitrofetch-improved",
        .root_source_file = b.path("src/main_new.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe_indev);

    exe.root_module.addImport("toml", toml_mod);
    exe_indev.root_module.addImport("toml", toml_mod);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
