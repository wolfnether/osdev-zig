const GlobalDescriptorTable = extern struct {
    segments: [5]SegmentDescriptor = .{
        SegmentDescriptor.new(0, 0, SegmentAccess.null_segment(), 0),
        SegmentDescriptor.new(0, 0xFFFFF, SegmentAccess.new_code_segment(true, false, 0), 0xA),
        SegmentDescriptor.new(0, 0xFFFFF, SegmentAccess.new_data_segment(true, false, 0), 0xC),
        SegmentDescriptor.new(0, 0xFFFFF, SegmentAccess.new_code_segment(true, false, 3), 0xA),
        SegmentDescriptor.new(0, 0xFFFFF, SegmentAccess.new_data_segment(true, false, 3), 0xC),
    },
    task_state_segments: [0]TaskStateDescriptor = .{},
};

const SegmentDescriptor = packed struct {
    limit_1: u16,
    base_1: u24,
    access: SegmentAccess,
    limit_2: u4,
    flags: u4,
    base_2: u8,

    inline fn new(base: u32, limit: u20, access: SegmentAccess, flags: u4) @This() {
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

const TaskStateDescriptor = packed struct {};

const SegmentAccess = packed struct {
    accessed: bool = false,
    read_write_access: bool,
    direction_conforming: bool,
    executable: bool,
    t: u1 = 1,
    privilage_level: u2,
    present: bool = true,

    pub inline fn new_code_segment(
        readable: bool,
        comforming: bool,
        privilage_level: u2,
    ) @This() {
        return .{
            .read_write_access = readable,
            .direction_conforming = comforming,
            .privilage_level = privilage_level,
            .executable = true,
        };
    }

    pub inline fn new_data_segment(
        writable: bool,
        grown_down: bool,
        privilage_level: u2,
    ) @This() {
        return .{
            .read_write_access = writable,
            .direction_conforming = grown_down,
            .privilage_level = privilage_level,
            .executable = false,
        };
    }

    pub inline fn null_segment() @This() {
        return .{
            .accessed = false,
            .read_write_access = false,
            .direction_conforming = false,
            .executable = false,
            .t = 0,
            .privilage_level = 0,
            .present = false,
        };
    }
};

var global_descriptor_table align(4096) = GlobalDescriptorTable{};

pub fn init() void {
    const gdtd = @import("util.zig").Descriptor.new(&global_descriptor_table, @sizeOf(GlobalDescriptorTable));

    asm volatile (
        \\lgdt %[gdtd]
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
        : "rax"
    );
}
