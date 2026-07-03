const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const tdb_dep = b.dependency("tidesdb", .{});

    const cflags: []const []const u8 = &.{
        "-std=c11",
        "-D_FILE_OFFSET_BITS=64",
        "-Wno-unused-parameter",
        "-Wno-sign-compare",
        "-Wno-unused-function",
    };

    const clib_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    clib_mod.addIncludePath(tdb_dep.path("src"));
    clib_mod.addIncludePath(tdb_dep.path("external"));
    clib_mod.addCSourceFiles(.{
        .root = tdb_dep.path("src"),
        .files = &.{
            "tidesdb.c",
            "alloc.c",
            "block_manager.c",
            "bloom_filter.c",
            "btree.c",
            "clock_cache.c",
            "compress.c",
            "local_cache.c",
            "manifest.c",
            "objstore_fs.c",
            "queue.c",
            "sha256.c",
            "hmac_sha256.c",
            "skip_list.c",
        },
        .flags = cflags,
    });
    clib_mod.addCSourceFiles(.{
        .root = tdb_dep.path("external"),
        .files = &.{ "ini.c", "xxhash.c" },
        .flags = cflags,
    });
    const clib = b.addLibrary(.{
        .name = "tidesdb",
        .root_module = clib_mod,
    });

    const mod = b.addModule("tidesdb", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    mod.linkLibrary(clib);

    const exe = b.addExecutable(.{
        .name = "tidesdb-example",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{.{ .name = "tidesdb", .module = mod }},
        }),
    });
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);
    b.step("run", "Run the example").dependOn(&run_cmd.step);

    const tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/tidesdb.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    tests.root_module.linkLibrary(clib);
    b.step("test", "Run tests").dependOn(&b.addRunArtifact(tests).step);
}
