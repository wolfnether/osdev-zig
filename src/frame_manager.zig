const allocator = @import("allocator.zig").allocator;

pub const FramesNode = struct { ptr: usize, size: usize, prev: ?*FramesNode = null, next: ?*FramesNode = null, alloc: bool = true };

var frame_list: FramesNode = .{ .ptr = 0, .size = 0, .prev = null, .next = null, .alloc = false };

pub fn free() usize {
    var node: ?*FramesNode = &frame_list;
    var res: usize = 0;

    while (node) |_node| {
        res += _node.size;
        node = _node.next;
    }

    return res;
}

pub fn alloc_frame() ?usize {
    var next: ?*FramesNode = &frame_list;
    while (next) |actual| {
        if (actual.size > 0) {
            const addr = actual.ptr;
            actual.ptr += 4096;
            actual.size -= 1;
            if (actual.size == 0 and actual.alloc) {
                if (actual.prev) |node| {
                    node.next = actual.next;
                }
                if (actual.next) |node| {
                    node.prev = actual.prev;
                }
                allocator.destroy(actual);
            }
            const ptr: [*]u8 = @ptrFromInt(addr + @import("hhmd.zig").get_offset());
            @memset(ptr[0..4096], 0);

            return addr;
        }
        next = actual.next;
    }

    unreachable;
}

pub fn add_node(frame_region: *FramesNode) void {
    var node = &frame_list;
    while (node.next != null) {
        if (frame_list.ptr + 4096 == node.ptr) {
            node.ptr -= 4096;
            node.size += 1;
            if (frame_region.alloc) {
                allocator.destroy(frame_region);
            }
            return;
        }

        node = node.next.?;
    }
    frame_region.prev = node;
    node.next = frame_region;
}

pub inline fn init(first_node: FramesNode) void {
    frame_list = first_node;
    frame_list.alloc = false;
}

pub inline fn inited() bool {
    return frame_list.ptr != 0;
}

pub fn print() void {
    var node: ?*FramesNode = &frame_list;
    while (node) |actual| {
        @import("std").log.info("{X} {X} {}", .{ actual.ptr, actual.ptr + actual.size * 4096, actual.size });
        node = actual.next;
    }
}
