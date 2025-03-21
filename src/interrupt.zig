const std = @import("std");

var interrupt_descriptor_table align(4096) = [1]InterruptDescriptor{.{}} ** 255;

var global_descriptor_table align(4096) = [5]GlobalDescriptor{
    GlobalDescriptor.new(0, 0, 0, 0),
    GlobalDescriptor.new(0, 0xFFFFF, 0x9A, 0xA),
    GlobalDescriptor.new(0, 0xFFFFF, 0x92, 0xC),
    GlobalDescriptor.new(0, 0xFFFFF, 0xFA, 0xA),
    GlobalDescriptor.new(0, 0xFFFFF, 0xF2, 0xC),
};

const Descriptor = packed struct {
    len: u16,
    ptr: u64,

    inline fn new(ptr: *anyopaque, len: u16) @This() {
        return .{ .ptr = @intFromPtr(ptr), .len = len };
    }
};

const CpuStatus = struct {
    r15: u64,
    r14: u64,
    r13: u64,
    r12: u64,
    r11: u64,
    r10: u64,
    r9: u64,
    r8: u64,
    rdi: u64,
    rsi: u64,
    rbp: u64,
    rdx: u64,
    rcx: u64,
    rbx: u64,
    rax: u64,

    vector: u64,
    error_code: u64,

    rip: u64,
    cs: u64,
    flags: u64,
    rsp: u64,
    ss: u64,

    pub fn format(
        self: @This(),
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try std.fmt.format(writer,
            \\interrupt.CpuStatus{{
            \\  .vector     = 0x{X:0>2},
            \\  .error_code = 0x{X:0>16},
            \\
            \\  .rip        = 0x{X:0>16},
            \\  .cs         = 0x{X:0>16},
            \\  .flags      = 0x{X:0>16},
            \\  .rsp        = 0x{X:0>16},
            \\  .ss         = 0x{X:0>16},
            \\
            \\  .rax        = 0x{X:0>16},
            \\  .rbx        = 0x{X:0>16},
            \\  .rcx        = 0x{X:0>16},
            \\  .rdx        = 0x{X:0>16},
            \\  .rbp        = 0x{X:0>16},
            \\  .rdi        = 0x{X:0>16},
            \\  .r8         = 0x{X:0>16},
            \\  .r9         = 0x{X:0>16},
            \\  .r10        = 0x{X:0>16},
            \\  .r11        = 0x{X:0>16},
            \\  .rsi        = 0x{X:0>16},
            \\  .r12        = 0x{X:0>16},
            \\  .r13        = 0x{X:0>16},
            \\  .r14        = 0x{X:0>16},
            \\  .r15        = 0x{X:0>16},
            \\}}
        , .{
            self.vector,
            self.error_code,
            self.rip,
            self.cs,
            self.flags,
            self.rsp,
            self.ss,
            self.rax,
            self.rbx,
            self.rcx,
            self.rdx,
            self.rbp,
            self.rdi,
            self.r8,
            self.r9,
            self.r10,
            self.r11,
            self.rsi,
            self.r12,
            self.r13,
            self.r14,
            self.r15,
        });
    }
};

const GlobalDescriptor = packed struct {
    limit_1: u16,
    base_1: u24,
    access: u8,
    limit_2: u4,
    flags: u4,
    base_2: u8,

    inline fn new(base: u32, limit: u20, access: u8, flags: u4) @This() {
        return .{
            .base_1 = @intCast(base),
            .base_2 = @intCast(base >> 24),
            .limit_1 = @intCast(limit & 0xFFFF),
            .limit_2 = @intCast(limit >> 16),
            .access = access,
            .flags = flags,
        };
    }
};

const InterruptDescriptor = packed struct {
    offset_1: u16 = 0,
    segment: u16 = 0,
    interrupt_stack_table: u3 = 0,
    _0: u5 = 0,
    gate_type: u4 = 0,
    _2: u1 = 0,
    privilage: u2 = 0,
    present: bool = false,
    offset_2: u48 = 0,
    _3: u32 = 0,

    fn set_vector(self: *@This(), vector: usize) void {
        self.offset_1 = @intCast(vector);
        self.offset_2 = @intCast(vector >> 16);
    }
};

pub fn init() void {
    const idtd = Descriptor.new(&interrupt_descriptor_table, interrupt_descriptor_table.len);
    const gdtd = Descriptor.new(&global_descriptor_table, interrupt_descriptor_table.len);

    //@setEvalBranchQuota(1000);
    inline for (0..32) |i| {
        const interrupt_entry = &interrupt_descriptor_table[i];
        interrupt_entry.set_vector(@intFromPtr(&generate_handle(i)));
        interrupt_entry.present = true;
        interrupt_entry.gate_type = 0xe;
        interrupt_entry.segment = 0x8;
    }

    asm volatile (
        \\lgdt %[gdtd]
        \\lidt %[idtd]
        \\
        \\pushw $0x8
        \\leaq .reload_CS(%rip), %rax
        \\pushq %rax
        \\lretq
        \\
        \\.reload_CS:
        \\movw $0x10, %ax
        \\movw %ax, %ds
        \\movw %ax, %es
        \\movw %ax, %fs
        \\movw %ax, %gs
        \\movw %ax, %ss
        \\
        \\sti
        :
        : [gdtd] "*p" (&gdtd),
          [idtd] "*p" (&idtd),
        : "rax"
    );
}

fn generate_handle(comptime num: u8) fn () callconv(.naked) noreturn {
    const error_code_list = [_]u8{ 8, 10, 11, 12, 13, 14, 17, 21, 29, 30 };

    const str = if (!for (error_code_list) |value| {
        if (value == num) {
            break true;
        }
    } else false)
        \\pushq $0
    else
        "        ";

    return struct {
        fn handle() callconv(.naked) noreturn {
            asm volatile (str ::: "memory");
            asm volatile (
                \\pushq %[i]
                \\jmp %[interrupt_stub:P]
                :
                : [i] "i" (num),
                  [interrupt_stub] "X" (&interrupt_stub),
            );
        }
    }.handle;
}

fn interrupt_stub() callconv(.naked) noreturn {
    asm volatile (
        \\push %rax
        \\push %rbx
        \\push %rcx
        \\push %rdx
        \\push %rbp
        \\push %rsi
        \\push %rdi
        \\push %r8
        \\push %r9
        \\push %r10
        \\push %r11
        \\push %r12
        \\push %r13
        \\push %r14
        \\push %r15
        \\
        \\mov %rsp,%rdi
        \\call %[interrupt_disaptch:P]
        \\
        \\pop %r15
        \\pop %r14
        \\pop %r13
        \\pop %r12
        \\pop %r11
        \\pop %r10
        \\pop %r9
        \\pop %r8
        \\pop %rdi
        \\pop %rsi
        \\pop %rbp
        \\pop %rdx
        \\pop %rcx
        \\pop %rbx
        \\pop %rax
        \\add $12,%rsp
        \\iretq
        :
        : [interrupt_disaptch] "X" (&interrupt_disaptch),
    );
}

fn interrupt_disaptch(cpu_status: *CpuStatus) void {
    @import("console.zig").format("{}", .{cpu_status});
    @import("util.zig").hlt();
}
