const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target_info = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const name = switch (target_info.result.cpu.arch) {
        inline else => |arch| "mykernel." ++ @tagName(arch) ++ ".elf",
    };

    const option = std.Build.ExecutableOptions{
        .name = name,
        .root_module = b.createModule(std.Build.Module.CreateOptions{ .strip = true, .optimize = optimize, .target = target_info, .root_source_file = b.path("src/main.zig"), .code_model = switch (target_info.result.cpu.arch) {
            .x86_64 => std.builtin.CodeModel.kernel,
            .riscv64 => std.builtin.CodeModel.medium,
            .aarch64 => std.builtin.CodeModel.large,
            else => |arch| {
                std.debug.print("unsupported arch: {}", .{arch});
                std.process.exit(1);
            },
        } }),
    };

    const kernel = b.addExecutable(option);
    kernel.setLinkerScript(b.path("src/linker.ld"));

    b.installArtifact(kernel);
}
