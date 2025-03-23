const std = @import("std");
const frame_manager = @import("frame_manager.zig");
pub const page_size = 4096;
const allocator = @import("allocator.zig").allocator;

pub fn unmap(memory: []align(page_size) const u8) !void {
    const addr = @intFromPtr(memory.ptr) >> 12;
    const n = memory.len >> 12;
    const dl4 = get_page_table_level4();

    for (0..n, addr..) |_, range| {
        const i = range >> 27;
        const j = range >> 18 & 0b111111111;
        const k = range >> 9 & 0b111111111;
        const l = range & 0b111111111;

        var e4 = &dl4[i];
        var e3 = &e4.get_page_directory()[j];
        var e2 = &e3.get_page_directory()[k];
        var e1 = &e2.get_page_directory()[l];

        e2.avail2 -= 1;
        var frame: *frame_manager.FramesNode = undefined;
        if (e1.avail1 == 0) {
            frame = try allocator.create(frame_manager.FramesNode);
            frame.* = .{ .ptr = e1.get_addr(), .size = 1 };
            frame_manager.add_node(frame);
        }

        if (e2.avail2 == 0) {
            e3.avail2 -= 1;
            frame = try allocator.create(frame_manager.FramesNode);
            frame.* = .{ .ptr = e2.get_addr(), .size = 1 };
            frame_manager.add_node(frame);
            if (e3.avail2 == 0) {
                e4.avail2 -= 1;
                frame = try allocator.create(frame_manager.FramesNode);
                frame.* = .{ .ptr = e3.get_addr(), .size = 1 };
                frame_manager.add_node(frame);
                if (e4.avail2 == 0) {
                    frame = try allocator.create(frame_manager.FramesNode);
                    frame.* = .{ .ptr = e4.get_addr(), .size = 1 };
                    frame_manager.add_node(frame);
                }
            }
        }
    }
}

pub fn map_mmio(_addr: u64, _virt: u64, n: usize) ?[*]u8 {
    const addr = _addr >> 12;
    var virt = _virt >> 12;
    const dl4 = get_page_table_level4();

    for (0..n, addr.., virt..) |_, addr_1, range| {
        const i = range >> 27;
        const j = range >> 18 & 0b111111111;
        const k = range >> 9 & 0b111111111;
        const l = range & 0b111111111;

        var e4 = &dl4[i];
        if (!e4.present) {
            e4.set_addr(frame_manager.alloc_frame().?);
            e4.present = true;
            e4.writable = true;
            e4.avail2 = 0;
        }
        var e3 = &e4.get_page_directory()[j];
        if (!e3.present) {
            e3.set_addr(frame_manager.alloc_frame().?);
            e3.present = true;
            e3.writable = true;
            e3.avail2 = 0;
            e4.avail2 += 1;
        }
        var e2 = &e3.get_page_directory()[k];
        if (!e2.present) {
            e2.set_addr(frame_manager.alloc_frame().?);
            e2.present = true;
            e2.writable = true;
            e2.avail2 = 0;
            e3.avail2 += 1;
        }
        var e1 = &e2.get_page_directory()[l];
        if (!e1.present) {
            e1.set_addr(addr_1 << 12);
            e1.present = true;
            e1.writable = true;
            e2.avail2 += 1;
            e1.avail1 = 1;
        } else {
            @panic("Alreary present");
        }
    }

    if (virt >> 35 == 1) {
        virt |= 0b1111111111111111 << 36;
    }

    return @ptrFromInt(virt << 12);
}

pub fn map(_addr: u64, n: usize) ?[*]u8 {
    var addr = _addr >> 12;
    const dl4 = get_page_table_level4();

    for (0..n, addr..) |_, range| {
        const i = range >> 27;
        const j = range >> 18 & 0b111111111;
        const k = range >> 9 & 0b111111111;
        const l = range & 0b111111111;

        var e4 = &dl4[i];
        if (!e4.present) {
            e4.set_addr(frame_manager.alloc_frame().?);
            e4.present = true;
            e4.writable = true;
            e4.avail2 = 0;
        }
        var e3 = &e4.get_page_directory()[j];
        if (!e3.present) {
            e3.set_addr(frame_manager.alloc_frame().?);
            e3.present = true;
            e3.writable = true;
            e3.avail2 = 0;
            e4.avail2 += 1;
        }
        var e2 = &e3.get_page_directory()[k];
        if (!e2.present) {
            e2.set_addr(frame_manager.alloc_frame().?);
            e2.present = true;
            e2.writable = true;
            e2.avail2 = 0;
            e3.avail2 += 1;
        }
        var e1 = &e2.get_page_directory()[l];
        if (!e1.present) {
            e1.set_addr(frame_manager.alloc_frame().?);
            e1.present = true;
            e1.writable = true;
            e2.avail2 += 1;
            e1.avail1 = 0;
        }
    }

    if (addr >> 35 == 1) {
        addr |= 0b1111111111111111 << 36;
    }

    return @ptrFromInt(addr << 12);
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
        //return @ptrFromInt(self.get_addr());
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
