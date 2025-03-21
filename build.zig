const std = @import("std");

pub fn build(b: *std.Build) void {

    // --------------------------- config ---------------------------

    const zox_version: std.SemanticVersion = .{ .major = 0, .minor = 1, .patch = 0 };
    const stringified_version: []const u8 = b.fmt("{d}.{d}.{d}", .{ zox_version.major, zox_version.minor, zox_version.patch });
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // --------------------------- modules ---------------------------

    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe_options = b.addOptions();
    exe_options.addOption([]const u8, "version", stringified_version);
    exe_mod.addOptions("build_options", exe_options);

    exe_mod.addImport("zox", lib_mod);

    // --------------------------- artifacts ---------------------------

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "zox",
        .root_module = lib_mod,
    });
    b.installArtifact(lib);

    const exe = b.addExecutable(.{
        .name = "zox",
        .root_module = exe_mod,
    });
    b.installArtifact(exe);

    // --------------------------- commands ---------------------------

    // run command

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // test command

    const lib_unit_tests = b.addTest(.{ .root_module = lib_mod });
    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const exe_unit_tests = b.addTest(.{ .root_module = exe_mod });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");

    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);
}
