const std = @import("std");
const page_manager = @import("page_manager.zig");

var i: u64 = 0;

pub const page_allocator = std.mem.Allocator{ .ptr = @constCast(&@This()), .vtable = &.{
    .alloc = page_alloc,
    .resize = page_resize,
    .remap = page_remap,
    .free = page_free,
} };

fn page_alloc(_: *anyopaque, n: usize, _: std.mem.Alignment, _: usize) ?[*]u8 {
    const n_page = std.mem.alignForward(usize, n, 4096) / 4096;

    const first = @import("util.zig").create_virtual_addr(510, 0, 0, i);

    i += n_page;
    return page_manager.map(first, n_page);
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
    page_manager.unmap(@alignCast(memory)) catch {};
}

fn realloc(uncasted_memory: []u8, new_len: usize, _: bool) ?[*]u8 {
    const memory: []align(page_manager.page_size) u8 = @alignCast(uncasted_memory);
    const new_size_aligned = std.mem.alignForward(usize, new_len, page_manager.page_size);
    const page_aligned_len = std.mem.alignForward(usize, memory.len, page_manager.page_size);

    if (page_aligned_len == new_size_aligned)
        return memory.ptr;
    if (new_size_aligned < page_aligned_len) {
        const ptr = memory.ptr + new_size_aligned;
        page_manager.unmap(@alignCast(ptr[0 .. page_manager.page_size - new_size_aligned])) catch {};
        return memory.ptr;
    }
    _ = page_alloc(@ptrFromInt(1), new_size_aligned - page_aligned_len, .@"1", 0).?;

    return memory.ptr;
}

var arena = std.heap.ArenaAllocator.init(page_allocator);
pub const allocator = arena.allocator();
