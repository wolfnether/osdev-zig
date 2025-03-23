const std = @import("std");

const console = @import("console.zig");
const frame_manager = @import("frame_manager.zig");
const allocator = @import("allocator.zig").allocator;

const _ = @import("limine.zig");

export fn _start() noreturn {
    if (!@import("limine.zig").base_revision.isSupported()) {
        @panic("Base revision not supported");
    }
    if (main()) |_| {
        console.format("main returned normally", .{});
    } else |e| {
        console.format("main returned error {any}", .{e});
    }

    @import("util.zig").hlt();
}

inline fn main() !void {
    console.init();
    console.format("HELLO WORLD FROM KERNEL\n", .{});

    @import("hhmd.zig").init();

    @import("gdt.zig").init();
    @import("interrupt.zig").init();

    if (@import("limine.zig").memory_map_request.response) |res| {
        for (res.getEntries()) |entry| {
            if (@intFromEnum(entry.type) == 0) {
                if (frame_manager.inited()) {
                    const frame = try allocator.create(frame_manager.FramesNode);
                    frame.* = .{ .ptr = entry.base, .size = entry.length / 4096 };
                    frame_manager.add_node(frame);
                } else {
                    frame_manager.init(.{ .ptr = entry.base, .size = entry.length / 4096 });
                }
            }
        }
    }

    console.format("free: {} 4kb frames\n", .{frame_manager.free()});

    try @import("acpi.zig").init();
}

pub const panic = std.debug.FullPanic(kernel_panic);

pub fn kernel_panic(msg: []const u8, _: ?usize) noreturn {
    console.format("!!!PANIC!!!\n{s}\n", .{msg});
    while (true) {
        asm volatile ("cli;hlt");
    }
}
