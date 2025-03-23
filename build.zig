const std = @import("std");
const features = std.Target.x86.Feature;

pub fn build(b: *std.Build) !void {
    //var target_query = std.Target.Query{};
    ////target_query.cpu_features_add.addFeature(@intFromEnum(features.soft_float));
    ////target_query.cpu_features_sub.addFeature(@intFromEnum(features.mmx));
    ////target_query.cpu_features_sub.addFeature(@intFromEnum(features.sse));
    ////target_query.cpu_features_sub.addFeature(@intFromEnum(features.sse2));
    ////target_query.cpu_features_sub.addFeature(@intFromEnum(features.avx));
    ////target_query.cpu_features_sub.addFeature(@intFromEnum(features.avx2));
    //target_query.cpu_arch = .x86_64;
    //target_query.os_tag = .freestanding;
    //target_query.abi = .muslabi64;
    //target_query.cpu_model = .baseline;

    const target_info = b.standardTargetOptions(.{});

    const name = switch (target_info.result.cpu.arch) {
        inline else => |arch| "mykernel." ++ @tagName(arch) ++ ".elf",
    };

    const limine_zig = b.dependency("limine_zig", .{
        // The API revision of the Limine Boot Protocol to use, if not provided
        // it defaults to 0. Newer revisions may change the behavior of the bootloader.
        .api_revision = 3,
        // Whether to allow using deprecated features of the Limine Boot Protocol.
        // If set to false, the build will fail if deprecated features are used.
        .allow_deprecated = false,
        // Whether to expose pointers in the API. When set to true, any field
        // that is a pointer will be exposed as a raw address instead.
        .no_pointers = false,
    });

    const limine_module = limine_zig.module("limine");

    var target_query = target_info.query;
    target_query.cpu_features_sub = .empty;
    target_query.cpu_features_add.addFeature(@intFromEnum(features.soft_float));
    target_query.cpu_features_sub.addFeature(@intFromEnum(features.mmx));
    target_query.cpu_features_sub.addFeature(@intFromEnum(features.sse));
    target_query.cpu_features_sub.addFeature(@intFromEnum(features.sse2));

    const kernel_module = b.createModule(std.Build.Module.CreateOptions{
        .strip = true,
        .optimize = b.standardOptimizeOption(.{}),
        .target = b.resolveTargetQuery(target_query),
        .root_source_file = b.path("src/main.zig"),
        .code_model = std.builtin.CodeModel.kernel,
    });

    kernel_module.addImport("limine", limine_module);

    const option = std.Build.ExecutableOptions{
        .name = name,
        .root_module = kernel_module,
    };

    const kernel = b.addExecutable(option);
    kernel.setLinkerScript(b.path("src/linker.ld"));

    kernel.addIncludePath(b.path("lib/uACPI/include"));
    kernel.addIncludePath(b.path("limine"));

    kernel.addCSourceFiles(.{
        .root = b.path("lib/uACPI/source/"),
        .files = &.{
            "default_handlers.c",
            "event.c",
            "interpreter.c",
            "io.c",
            "mutex.c",
            "namespace.c",
            "notify.c",
            "opcodes.c",
            "opregion.c",
            "osi.c",
            "registers.c",
            "resources.c",
            "shareable.c",
            "stdlib.c",
            "tables.c",
            "types.c",
            "uacpi.c",
            "utilities.c",
        },
    });

    b.installArtifact(kernel);
}
