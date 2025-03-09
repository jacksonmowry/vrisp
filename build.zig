const std = @import("std");
const Target = std.Target;
const Feature = std.Target.Cpu.Feature;

pub fn build(b: *std.Build) void {
    const features = Target.riscv.Feature;
    var enabled_features = Feature.Set.empty;
    enabled_features.addFeature(@intFromEnum(features.v));
    enabled_features.addFeature(@intFromEnum(features.b));
    enabled_features.addFeature(@intFromEnum(features.m));
    enabled_features.addFeature(@intFromEnum(features.a));
    enabled_features.addFeature(@intFromEnum(features.f));
    enabled_features.addFeature(@intFromEnum(features.d));
    enabled_features.addFeature(@intFromEnum(features.zicsr));
    enabled_features.addFeature(@intFromEnum(features.zifencei));

    const rv_target = b.resolveTargetQuery(.{
        .cpu_arch = Target.Cpu.Arch.riscv64,
        .os_tag = Target.Os.Tag.linux,
        .abi = Target.Abi.gnu,
        .cpu_features_add = enabled_features,
    });

    // const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "libframework",
        .target = rv_target,
        .optimize = optimize,
    });
    lib.linkLibCpp();
    lib.addIncludePath(b.path("framework-open/include"));
    lib.addIncludePath(b.path("framework-open/include/utils"));
    lib.addCSourceFiles(.{
        .files = &.{
            "framework-open/src/framework.cpp",
            "framework-open/src/processor_help.cpp",
            "framework-open/src/properties.cpp",
        },
        .flags = &.{
            "-std=c++11",
            "-Wall",
            "-Wextra",
        },
    });

    const vrisp = b.addObject(.{
        .name = "vrisp",
        .target = rv_target,
        .optimize = optimize,
    });
    vrisp.linkLibCpp();
    vrisp.addIncludePath(b.path("framework-open/include"));
    vrisp.addCSourceFile(.{
        .file = b.path("framework-open/src/vrisp.cpp"),
        .flags = &.{"-DNO_SIMD"},
    });
    vrisp.addCSourceFile(.{ .file = b.path("framework-open/src/vrisp_static.cpp") });
    vrisp.linkLibrary(lib);

    const risp = b.addObject(.{
        .name = "risp",
        .target = rv_target,
        .optimize = optimize,
    });
    risp.linkLibCpp();
    risp.addIncludePath(b.path("framework-open/include"));
    risp.addCSourceFile(.{
        .file = b.path("framework-open/src/risp.cpp"),
    });
    risp.addCSourceFile(.{ .file = b.path("framework-open/src/risp_static.cpp") });
    risp.linkLibrary(lib);

    const vrisp_exe = b.addExecutable(.{
        .name = "vrisp_dbscan",
        .target = rv_target,
        .optimize = optimize,
    });
    vrisp_exe.linkLibCpp();
    vrisp_exe.linkLibrary(lib);
    vrisp_exe.addIncludePath(b.path("framework-open/include"));
    vrisp_exe.addIncludePath(b.path("framework-open/include/utils"));
    vrisp_exe.addObject(vrisp);
    vrisp_exe.addCSourceFile(.{ .file = b.path("src/dbscan_app.cpp") });

    b.installArtifact(vrisp_exe);

    const risp_exe = b.addExecutable(.{
        .name = "risp_dbscan",
        .target = rv_target,
        .optimize = optimize,
    });
    risp_exe.linkLibCpp();
    risp_exe.linkLibrary(lib);
    risp_exe.addIncludePath(b.path("framework-open/include"));
    risp_exe.addIncludePath(b.path("framework-open/include/utils"));
    risp_exe.addObject(risp);
    risp_exe.addCSourceFile(.{ .file = b.path("src/dbscan_app.cpp") });

    b.installArtifact(risp_exe);
}
