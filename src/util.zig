pub inline fn outb(port: u16, data: u8) void {
    asm volatile ("outb %[c], %[p]"
        :
        : [c] "{ax}" (data),
          [p] "{dh}" (port),
    );
}

pub inline fn hlt() noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}
