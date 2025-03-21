/// mykernel/zig/src/main.zig
///
/// Copyright (C) 2023 binarycraft
///
/// Permission is hereby granted, free of charge, to any person
/// obtaining a copy of this software and associated documentation
/// files (the "Software"), to deal in the Software without
/// restriction, including without limitation the rights to use, copy,
/// modify, merge, publish, distribute, sublicense, and/or sell copies
/// of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be
/// included in all copies or substantial portions of the Software.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
/// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
/// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
/// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
/// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
/// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
/// DEALINGS IN THE SOFTWARE.
///
/// This file is part of the BOOTBOOT Protocol package.
/// @brief A sample BOOTBOOT compatible kernel
const std = @import("std");

const console = @import("console.zig");
const frame_manager = @import("frame_manager.zig");
const allocator = @import("allocator.zig").allocator;
const interrupion = @import("interrupt.zig");

extern var bootboot: @import("bootboot.zig").BOOTBOOT; // see bootboot.zig

// imported virtual addresses, see linker script
extern var environment: [4096]u8; // configuration, UTF-8 text key=value pairs

var cpu_id_i = std.atomic.Value(usize).init(0);

// Entry point, called by BOOTBOOT Loader
export fn _start() callconv(.Naked) noreturn {
    asm volatile (
        \\call %[main:P]
        :
        : [main] "X" (&kernel_main),
    );
}

fn kernel_main() noreturn {
    const cpu_id = cpu_id_i.fetchAdd(1, .seq_cst);

    if (cpu_id == 0) {
        if (main()) |_| {
            console.format("main returned normally", .{});
        } else |e| {
            console.format("main returned error {any}", .{e});
        }
    } else {
        try support();
    }

    @import("util.zig").hlt();
}

fn support() !void {
    @import("util.zig").hlt();
}

fn main() !void {
    console.init();
    console.format("HELLO WORLD FROM KERNEL\n", .{});

    interrupion.init();

    for (0..bootboot.num_mmap_entrie()) |i| {
        const entry = &bootboot.get_mmap_slice()[i];
        console.format("0x{X} {d} {} {} {}\n", .{ entry.getPtr(), entry.getSizeIn4KiBPages(), entry.isFree(), entry.getType(), entry.getRawType() });
        if (!frame_manager.inited() and entry.isFree()) {
            frame_manager.init(.{ .ptr = entry.getPtr(), .size = entry.getSizeIn4KiBPages() });
        } else if (entry.isFree()) {
            const frame = try allocator.create(frame_manager.FramesNode);
            frame.* = .{ .ptr = entry.getPtr(), .size = entry.getSizeIn4KiBPages() };
            frame_manager.add_node(frame);
        }
    }
}

pub const panic = std.debug.FullPanic(kernel_panic);

pub fn kernel_panic(msg: []const u8, _: ?usize) noreturn {
    console.format("!!!PANIC!!!\n{s}\n", .{msg});
    while (true) {
        asm volatile ("cli;hlt");
    }
}
