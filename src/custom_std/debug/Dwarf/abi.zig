const builtin = @import("builtin");

const std = @import("std");
const mem = std.mem;
const posix = std.posix;
const Arch = std.Target.Cpu.Arch;

/// Tells whether unwinding for this target is supported by the Dwarf standard.
///
/// See also `std.debug.SelfInfo.supportsUnwinding` which tells whether the Zig
/// standard library has a working implementation of unwinding for this target.
pub fn supportsUnwinding(target: std.Target) bool {
    return switch (target.cpu.arch) {
        .amdgcn,
        .nvptx,
        .nvptx64,
        .spirv,
        .spirv32,
        .spirv64,
        => false,

        // Enabling this causes relocation errors such as:
        // error: invalid relocation type R_RISCV_SUB32 at offset 0x20
        .riscv64, .riscv32 => false,

        // Conservative guess. Feel free to update this logic with any targets
        // that are known to not support Dwarf unwinding.
        else => true,
    };
}

/// Returns `null` for CPU architectures without an instruction pointer register.
pub fn ipRegNum(arch: Arch) ?u8 {
    return switch (arch) {
        .x86 => 8,
        .x86_64 => 16,
        .arm, .armeb, .thumb, .thumbeb => 15,
        .aarch64, .aarch64_be => 32,
        else => null,
    };
}

pub fn fpRegNum(arch: Arch, reg_context: RegisterContext) u8 {
    return switch (arch) {
        // GCC on OS X historically did the opposite of ELF for these registers
        // (only in .eh_frame), and that is now the convention for MachO
        .x86 => if (reg_context.eh_frame and reg_context.is_macho) 4 else 5,
        .x86_64 => 6,
        .arm, .armeb, .thumb, .thumbeb => 11,
        .aarch64, .aarch64_be => 29,
        else => unreachable,
    };
}

pub fn spRegNum(arch: Arch, reg_context: RegisterContext) u8 {
    return switch (arch) {
        .x86 => if (reg_context.eh_frame and reg_context.is_macho) 5 else 4,
        .x86_64 => 7,
        .arm, .armeb, .thumb, .thumbeb => 13,
        .aarch64, .aarch64_be => 31,
        else => unreachable,
    };
}

pub const RegisterContext = struct {
    eh_frame: bool,
    is_macho: bool,
};

pub const RegBytesError = error{
    InvalidRegister,
    UnimplementedArch,
    UnimplementedOs,
    RegisterContextRequired,
    ThreadContextNotSupported,
};

/// Returns a slice containing the backing storage for `reg_number`.
///
/// This function assumes the Dwarf information corresponds not necessarily to
/// the current executable, but at least with a matching CPU architecture and
/// OS. It is planned to lift this limitation with a future enhancement.
///
/// `reg_context` describes in what context the register number is used, as it can have different
/// meanings depending on the DWARF container. It is only required when getting the stack or
/// frame pointer register on some architectures.
const Context = @import("../../../interrupt.zig").CpuStatus;
pub fn regBytes(
    context: *Context,
    reg_number: u8,
    _: ?RegisterContext,
) RegBytesError![]u8 {
    return switch (reg_number) {
        3 => std.mem.asBytes(&context.rbx),
        6 => std.mem.asBytes(&context.rbp),
        7 => std.mem.asBytes(&context.rsp),
        8 => std.mem.asBytes(&context.r8),
        9 => std.mem.asBytes(&context.r9),
        10 => std.mem.asBytes(&context.r10),
        11 => std.mem.asBytes(&context.r11),
        12 => std.mem.asBytes(&context.r12),
        13 => std.mem.asBytes(&context.r13),
        14 => std.mem.asBytes(&context.r14),
        15 => std.mem.asBytes(&context.r15),
        16 => std.mem.asBytes(&context.rip),
        else => std.debug.panic("regBytes todo {} ", .{reg_number}),
    };
}

/// Returns a pointer to a register stored in a ThreadContext, preserving the
/// pointer attributes of the context.
pub fn regValueNative(
    context: *Context,
    reg_number: u8,
    reg_context: ?RegisterContext,
) !*align(1) usize {
    const reg_bytes = try regBytes(context, reg_number, reg_context);
    if (@sizeOf(usize) != reg_bytes.len) return error.IncompatibleRegisterSize;
    return mem.bytesAsValue(usize, reg_bytes[0..@sizeOf(usize)]);
}
