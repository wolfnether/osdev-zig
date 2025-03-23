const std = @import("std");

const console = @import("console.zig");
const frame_manager = @import("frame_manager.zig");
const allocator = @import("allocator.zig").allocator;

const limine = @import("limine.zig");
const acpi = @import("acpi.zig");

comptime {
    _ = acpi;
}

pub const std_options: std.Options =
    .{
        .page_size_min = 4096,
        .page_size_max = 4096,
        .logFn = log,
        .log_level = .debug,
    };

fn log(
    comptime message_level: std.log.Level,
    comptime scope: @TypeOf(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    const level_txt = comptime message_level.asText();
    const prefix2 = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";

    console.writer.print(level_txt ++ prefix2 ++ format ++ "\n", args) catch {};
}

export fn _start() noreturn {
    if (!@import("limine.zig").base_revision.isSupported()) {
        @panic("Base revision not supported");
    }

    if (@call(.never_inline, main, .{})) |_| {
        std.log.info("main returned normally", .{});
    } else |e| {
        std.log.err("main returned error {any}", .{e});
    }

    @import("util.zig").hlt();
}

fn main() !void {
    console.init();
    std.log.info("HELLO WORLD FROM KERNEL", .{});

    @import("hhmd.zig").init();

    @import("gdt.zig").init();
    @import("interrupt.zig").init();

    if (@import("limine.zig").memory_map_request.response) |res| {
        for (res.getEntries()) |entry| {
            if (entry.type == .usable) {
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

    std.log.info("free: {} 4kb frames", .{frame_manager.free()});

    try @import("acpi.zig").init();
}

pub const panic = std.debug.FullPanic(kernel_panic);

var panicing = false;

pub fn kernel_panic(msg: []const u8, addr: ?usize) noreturn {
    defer {
        while (true) {
            asm volatile ("cli;hlt");
        }
    }

    std.log.err("!!!PANIC!!!\n{s}\n0x{?X}\n", .{
        msg,
        addr,
    });

    //const stack_ptr = asm volatile ("mov %rsp, %[r]"
    //    : [r] "=r" (-> u64),
    //) + 0x828 + 6 * 8;
    //var pc = addr orelse asm volatile ("leaq (%rip), %[r]"
    //    : [r] "=r" (-> u64),
    //);

    if (!panicing) {
        panicing = true;
    }
}
