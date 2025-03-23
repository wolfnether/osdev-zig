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

pub inline fn create_virtual_addr(a: u64, b: u64, c: u64, d: u64) u64 {
    return ((((a * 512 + b) * 512) + c) * 512 + d) << 12;
}
