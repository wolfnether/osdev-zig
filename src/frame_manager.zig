const allocator = @import("allocator.zig").allocator;

pub const FramesNode = struct { ptr: usize, size: usize, next: ?*FramesNode = null };

var frame_list = FramesNode{ .ptr = 0, .size = 0, .next = null };

pub fn alloc_frame() ?usize {
    var node = &frame_list;
    var prev: ?*FramesNode = null;
    while (node.next != null) {
        if (node.size > 0) {
            const ptr = node.ptr;
            node.ptr += 4096;
            node.size -= 1;
            if (node.size == 0) {
                if (prev) |prev_node| {
                    prev_node.next = node.next;
                } else if (node.next) |next_node| {
                    frame_list = next_node.*;
                }
                allocator.destroy(node);
            }
            return ptr;
        }
        prev = node;
        node = node.next.?;
    }
    unreachable;
}

pub fn add_node(frame_region: *FramesNode) void {
    var node = &frame_list;
    while (node.next != null) {
        if (frame_region.ptr <= node.ptr) {
            if (frame_list.ptr + 4096 == node.ptr) {
                node.ptr -= 4096;
                node.size += 1;
                return;
            }
        }
        node = node.next.?;
    }
    node.next = frame_region;
}

pub inline fn init(first_node: FramesNode) void {
    frame_list = first_node;
}

pub inline fn inited() bool {
    return frame_list.ptr != 0;
}
