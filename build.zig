const std = @import("std");

pub fn build(b: *std.Build) void {
    const zox_version: std.SemanticVersion = .{ .major = 0, .minor = 1, .patch = 0 };
    const stringified_version: []const u8 = b.fmt("{d}.{d}.{d}", .{ zox_version.major, zox_version.minor, zox_version.patch });
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zox",
        .root_source_file = b.path("src/main.zig"),
        .optimize = optimize,
        .target = target,
    });

    // add build options module
    const exe_options = b.addOptions();
    exe.root_module.addOptions("build_options", exe_options);

    // const version = b.allocator.dupeZ(u8, stringified_version);
    exe_options.addOption([]const u8, "version", stringified_version);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .optimize = optimize,
        .target = target,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
