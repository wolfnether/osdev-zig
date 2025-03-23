const std = @import("std");
const frame_manager = @import("frame_manager.zig");
pub const page_size = 4096;

pub fn unmap(memory: []align(page_size) const u8) void {
    _ = memory;
    @panic("todo9");
}

pub fn map(n: usize) ?[*]u8 {
    const dl4 = get_page_table_level4();
    @import("console.zig").format("{*}\n", .{dl4});
    var r = find_unused_range(n).?;

    for (0..n, r..) |_, range| {
        const i = range >> 27;
        const j = range >> 18 & 0b111111111;
        const k = range >> 9 & 0b111111111;
        const l = range & 0b111111111;

        var e4 = &dl4[i];
        @import("console.zig").format("{*}\n", .{e4});
        if (!e4.present) {
            e4.set_addr(frame_manager.alloc_frame().?);
            e4.present = true;
            e4.writable = true;
        }
        var e3 = &e4.get_page_directory()[j];
        if (!e3.present) {
            e3.set_addr(frame_manager.alloc_frame().?);
            e3.present = true;
            e3.writable = true;
        }
        var e2 = &e3.get_page_directory()[k];
        if (!e2.present) {
            e2.set_addr(frame_manager.alloc_frame().?);
            e2.present = true;
            e2.writable = true;
        }
        var e1 = &e2.get_page_directory()[l];
        if (!e1.present) {
            e1.set_addr(frame_manager.alloc_frame().?);
            e1.present = true;
            e1.writable = true;
        }
    }

    if (r >> 35 == 1) {
        r |= 0b1111111111111111 << 36;
    }

    return @ptrFromInt(r << 12);
}

fn find_unused_range(n: usize) ?usize {
    var find: usize = 0;
    const p4 = get_page_table_level4();
    for (256..512) |i| {
        const e4 = p4[i];
        if (e4.present) {
            const p3 = e4.get_page_directory();
            for (0..512) |j| {
                const e3 = p3[j];
                if (e3.present) {
                    const p2 = e3.get_page_directory();
                    for (0..512) |k| {
                        const e2 = p2[k];
                        if (e2.present) {
                            const p1 = e2.get_page_directory();
                            for (0..512) |l| {
                                const e1 = p1[l];
                                if (e1.present) {
                                    find = 0;
                                } else {
                                    find += 1;
                                    if (find == n) {
                                        return (i << 27 | j << 18 | k << 9 | l) - n;
                                    }
                                }
                            }
                        } else {
                            find += 512;
                            if (find >= n) {
                                if (n > 512) {
                                    return (i << 27 | j << 18 | k << 9) - (n % 512) * 512;
                                }
                                return i << 27 | j << 18 | k << 9;
                            }
                        }
                    }
                } else {
                    find += 512 * 512;
                    if (find >= n) {
                        if (n > 512 * 512) {
                            return (i << 27 | j << 18) - (n % 512 * 512) * 512 * 512;
                        }
                        return i << 27 | j << 18;
                    }
                }
            }
        } else {
            find += 512 * 512;
            if (find >= n) {
                if (n > 512 * 512 * 512) {
                    return (i << 27) - (n % 512 * 512 * 512) * 512 * 512 * 512;
                }
                return i << 27;
            }
        }
    }
    return null;
}

pub fn remap(old_address: ?[*]align(page_size) u8, old_len: usize, new_len: usize, may_move: bool) ![]align(page_size) u8 {
    _ = old_address;
    _ = old_len;
    _ = new_len;
    _ = may_move;
    @panic("todo6");
}

pub const page_entry = packed struct {
    present: bool,
    writable: bool,
    user: bool,
    write_through_caching: bool,
    disable_cache: bool,
    accessed: bool,
    huge: bool = false,
    pat: bool = false,
    dirty: bool = false,
    avail1: u3,
    addr: u40,
    avail2: u11,
    no_exec: bool,

    pub inline fn get_page_directory(self: *const @This()) *[512]page_entry {
        return @ptrFromInt(self.get_addr() + @import("hhmd.zig").get_offset());
    }

    pub inline fn get_addr(self: *const @This()) usize {
        return self.addr << 12;
    }

    pub inline fn set_addr(self: *@This(), addr: usize) void {
        self.addr = @intCast(addr >> 12);
    }
};

pub inline fn get_page_table_level4() *[512]page_entry {
    const ptr = asm volatile ("mov %cr3,%[addr]"
        : [addr] "=r" (-> u64),
    );

    return @ptrFromInt(ptr + @import("hhmd.zig").get_offset());
    //return @ptrFromInt(ptr);
}
