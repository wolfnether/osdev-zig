const std = @import("std");
const page_manager = @import("page_manager.zig");

const page_allocator = std.mem.Allocator{ .ptr = @constCast(&@This()), .vtable = &.{
    .alloc = page_alloc,
    .resize = page_resize,
    .remap = page_remap,
    .free = page_free,
} };

fn page_alloc(_: *anyopaque, n: usize, _: std.mem.Alignment, _: usize) ?[*]u8 {
    @import("console.zig").format("new page request {} B\n", .{n});
    return page_manager.map(n / 4096 + 1);
}
fn page_resize(_: *anyopaque, memory: []u8, _: std.mem.Alignment, new_len: usize, _: usize) bool {
    return realloc(memory, new_len, false) != null;
}
fn page_remap(
    _: *anyopaque,
    memory: []u8,
    _: std.mem.Alignment,
    new_len: usize,
    _: usize,
) ?[*]u8 {
    return realloc(memory, new_len, true);
}

fn page_free(_: *anyopaque, memory: []u8, _: std.mem.Alignment, _: usize) void {
    page_manager.unmap(@alignCast(memory));
}

fn realloc(uncasted_memory: []u8, new_len: usize, may_move: bool) ?[*]u8 {
    _ = may_move;
    const memory: []align(page_manager.page_size) u8 = @alignCast(uncasted_memory);
    const new_size_aligned = std.mem.alignForward(usize, new_len, page_manager.page_size);

    if (new_size_aligned == new_size_aligned)
        return memory.ptr;
    if (new_size_aligned < new_size_aligned) {
        const ptr = memory.ptr + new_size_aligned;
        page_manager.unmap(@alignCast(ptr[0 .. page_manager.page_size - new_size_aligned]));
        return memory.ptr;
    }
    @panic("todo2");
    //const mem = try page_manager.remap(memory.ptr, memory.len, new_len, may_move) orelse null;
    //    return mem.ptr;
}

var arena = std.heap.ArenaAllocator.init(page_allocator);
pub const allocator = arena.allocator();
