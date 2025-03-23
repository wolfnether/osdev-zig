pub inline fn outb(port: u16, data: u8) void {
    asm volatile ("outb %[c], %[p]"
        :
        : [c] "{ax}" (data),
          [p] "{dh}" (port),
        : "ax", "dh"
    );
}

pub inline fn hlt() noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}

pub const Descriptor = packed struct {
    len: u16,
    ptr: u64,

    pub inline fn new(ptr: u64, len: u16) @This() {
        return .{ .ptr = ptr, .len = len };
    }
};
