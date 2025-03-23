const c = @cImport({
    @cInclude("uacpi/uacpi.h");
});

const std = @import("std");

const LogLevel = enum(c_uint) {
    ERROR = 1,
    WARN = 2,
    INFO = 3,
    TRACE = 4,
    DEBUG = 5,
};

inline fn uacpi_wraper(function: anytype, args: anytype) error{usize}!void {
    std.log.info("uacpi_wraper", .{});
    const ret: c.uacpi_status = @call(.auto, function, args);
    if (ret != 0) {
        return @errorCast(@errorFromInt(@as(u16, @truncate(ret))));
    }
}

pub fn init() error{usize}!void {
    std.log.info("init", .{});
    try uacpi_wraper(&c.uacpi_initialize, .{0});
}

export fn uacpi_kernel_log(_: LogLevel, _: [*c]u8) void {
    std.log.info("uacpi_kernel_log", .{});
    //@import("console.zig").format("[{s}] {s}", .{ @tagName(level), str });
}

export fn uacpi_kernel_get_rsdp(out_rsdp_address: *u64) c.uacpi_status {
    std.log.info("uacpi_kernel_get_rsdp", .{});
    if (@import("limine.zig").rspd_request.response) |res| {
        out_rsdp_address.* = res.address;
        return 0;
    }
    return c.UACPI_STATUS_NOT_FOUND;
}

fn alloc_slice(size: usize) ?*usize {
    std.log.info("alloc_slice", .{});
    const slice: [*]usize = @alignCast(@ptrCast(@import("allocator.zig").allocator.rawAlloc(size + @sizeOf(usize), .@"8", @returnAddress()).?));

    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("{*} \n", .{slice});

    slice[0] = size + @sizeOf(usize);
    return &slice[1];
}

export fn uacpi_kernel_alloc(size: usize) usize {
    std.log.info("uacpi_kernel_alloc", .{});
    if (alloc_slice(size)) |ptr| {
        @import("console.zig").format("uacpi_kernel_alloc {*} \n", .{ptr});
        return @intFromPtr(ptr);
    } else {
        @import("console.zig").format("uacpi_kernel_alloc error \n", .{});
        return 0;
    }
}

export fn uacpi_kernel_free(slice_0: ?[*]usize) void {
    std.log.info("uacpi_kernel_free", .{});
    std.log.info("{?*}", .{slice_0});
    //if (slice_0) |slice_1| {
    //    const len = (slice_1 - 1)[0];
    //    const slice = @as([*]u8, @constCast(@ptrCast(slice_1 - 1)));
    //
    //    @import("console.zig").format("{*} \n", .{slice});
    //
    //    @import("allocator.zig").allocator.rawFree(slice[0..len], .@"8", @returnAddress());
    //}
}

export fn uacpi_kernel_handle_firmware_request(firmware_request: *c.uacpi_firmware_request) c.uacpi_status {
    std.log.info("uacpi_kernel_handle_firmware_request", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("{}\n", .{firmware_request});
    @import("util.zig").hlt();
}

export fn uacpi_kernel_reset_event(handle: c.uacpi_handle) void {
    std.log.info("uacpi_kernel_reset_event", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("{*}\n", .{handle});
    @import("util.zig").hlt();
}

export fn uacpi_kernel_signal_event(handle: c.uacpi_handle) void {
    std.log.info("uacpi_kernel_signal_event", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("{*}\n", .{handle});
    @import("util.zig").hlt();
}

export fn uacpi_kernel_sleep(msec: c.uacpi_u64) void {
    std.log.info("uacpi_kernel_sleep", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("{}\n", .{msec});
    @import("util.zig").hlt();
}

export fn uacpi_kernel_pci_device_open(address: c.uacpi_pci_address, out_handle: *c.uacpi_handle) c.uacpi_status {
    std.log.info("uacpi_kernel_pci_device_open", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("{} - {*}\n", .{ address, out_handle });
    @import("util.zig").hlt();
}

export fn uacpi_kernel_pci_device_close(handle: c.uacpi_handle) void {
    std.log.info("uacpi_kernel_pci_device_close", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("{?*}\n", .{handle});
    @import("util.zig").hlt();
}

export fn uacpi_kernel_pci_read8(handle: c.uacpi_handle, offset: c.uacpi_size, value: *c.uacpi_u8) c.uacpi_status {
    std.log.info("uacpi_kernel_pci_read8", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("{*} {} {*}\n", .{ handle, offset, value });
    @import("util.zig").hlt();
}

export fn uacpi_kernel_pci_read16(handle: c.uacpi_handle, offset: c.uacpi_size, value: *c.uacpi_u16) c.uacpi_status {
    std.log.info("uacpi_kernel_pci_read16", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("{*} {} {*}\n", .{ handle, offset, value });
    @import("util.zig").hlt();
}

export fn uacpi_kernel_pci_read32(handle: c.uacpi_handle, offset: c.uacpi_size, value: *c.uacpi_u32) c.uacpi_status {
    std.log.info("uacpi_kernel_pci_read32", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("{*} {} {*}\n", .{ handle, offset, value });
    @import("util.zig").hlt();
}

export fn uacpi_kernel_pci_write8(handle: c.uacpi_handle, offset: c.uacpi_size, value: c.uacpi_u8) c.uacpi_status {
    std.log.info("uacpi_kernel_pci_write8", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("{*} {} {}\n", .{ handle, offset, value });
    @import("util.zig").hlt();
}

export fn uacpi_kernel_pci_write16(handle: c.uacpi_handle, offset: c.uacpi_size, value: c.uacpi_u16) c.uacpi_status {
    std.log.info("uacpi_kernel_pci_write16", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("{*} {} {}\n", .{ handle, offset, value });
    @import("util.zig").hlt();
}

export fn uacpi_kernel_pci_write32(handle: c.uacpi_handle, offset: c.uacpi_size, value: c.uacpi_u32) c.uacpi_status {
    std.log.info("uacpi_kernel_pci_write32", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("{*} {} {}\n", .{ handle, offset, value });
    @import("util.zig").hlt();
}

export fn uacpi_kernel_io_read8(handle: c.uacpi_handle, offset: c.uacpi_size, value: *c.uacpi_u8) c.uacpi_status {
    std.log.info("uacpi_kernel_io_read8", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("{*} {} {}\n", .{ handle, offset, value });
    @import("util.zig").hlt();
}

export fn uacpi_kernel_io_read16(handle: c.uacpi_handle, offset: c.uacpi_size, value: *c.uacpi_u16) c.uacpi_status {
    std.log.info("uacpi_kernel_io_read16", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("{*} {} {}\n", .{ handle, offset, value });
    @import("util.zig").hlt();
}

export fn uacpi_kernel_io_read32(handle: c.uacpi_handle, offset: c.uacpi_size, value: *c.uacpi_u32) c.uacpi_status {
    std.log.info("uacpi_kernel_io_read32", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("{*} {} {}\n", .{ handle, offset, value });
    @import("util.zig").hlt();
}

export fn uacpi_kernel_io_write8(handle: c.uacpi_handle, offset: c.uacpi_size, value: c.uacpi_u8) c.uacpi_status {
    std.log.info("uacpi_kernel_io_write8", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("{*} {} {}\n", .{ handle, offset, value });
    @import("util.zig").hlt();
}

export fn uacpi_kernel_io_write16(handle: c.uacpi_handle, offset: c.uacpi_size, value: c.uacpi_u16) c.uacpi_status {
    std.log.info("uacpi_kernel_io_write16", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("{*} {} {}\n", .{ handle, offset, value });
    @import("util.zig").hlt();
}

export fn uacpi_kernel_io_write32(handle: c.uacpi_handle, offset: c.uacpi_size, value: c.uacpi_u32) c.uacpi_status {
    std.log.info("uacpi_kernel_io_write32", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("{*} {} {}\n", .{ handle, offset, value });
    @import("util.zig").hlt();
}

export fn uacpi_kernel_install_interrupt_handler(irq: c.uacpi_u32, handler: c.uacpi_interrupt_handler, ctx: c.uacpi_handle, out_irq_handle: *c.uacpi_handle) c.uacpi_status {
    std.log.info("uacpi_kernel_install_interrupt_handler", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("{} {*} {*} {*}\n", .{ irq, handler, ctx, out_irq_handle });
    @import("util.zig").hlt();
}

export fn uacpi_kernel_uninstall_interrupt_handler(handler: c.uacpi_interrupt_handler, irq_handle: c.uacpi_handle) c.uacpi_status {
    std.log.info("uacpi_kernel_uninstall_interrupt_handler", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("{*} {*}\n", .{ handler, irq_handle });
    @import("util.zig").hlt();
}

export fn uacpi_kernel_get_nanoseconds_since_boot() c.uacpi_u64 {
    std.log.info("uacpi_kernel_get_nanoseconds_since_boot", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("\n", .{});
    @import("util.zig").hlt();
}

export fn uacpi_kernel_create_event() c.uacpi_handle {
    std.log.info("uacpi_kernel_create_event", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("\n", .{});
    @import("util.zig").hlt();
}

export fn uacpi_kernel_free_event(handle: c.uacpi_handle) void {
    std.log.info("uacpi_kernel_free_event", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("{*}\n", .{handle});
    @import("util.zig").hlt();
}

export fn uacpi_kernel_get_thread_id() c.uacpi_thread_id {
    std.log.info("uacpi_kernel_get_thread_id", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("\n", .{});
    @import("util.zig").hlt();
}

export fn uacpi_kernel_stall(usec: c.uacpi_u8) void {
    std.log.info("uacpi_kernel_stall", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("{} \n", .{usec});
    @import("util.zig").hlt();
}

export fn uacpi_kernel_schedule_work(work_type: c.uacpi_work_type, handle: c.uacpi_work_handler, ctx: c.uacpi_handle) c.uacpi_status {
    std.log.info("uacpi_kernel_schedule_work", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("{} {*} {*} \n", .{ work_type, handle, ctx });
    @import("util.zig").hlt();
}

export fn uacpi_kernel_wait_for_event(handle: c.uacpi_handle, ms: c.uacpi_u16) c.uacpi_bool {
    std.log.info("uacpi_kernel_wait_for_event", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("{*} {} \n", .{ handle, ms });
    @import("util.zig").hlt();
}

export fn uacpi_kernel_wait_for_work_completion() c.uacpi_status {
    std.log.info("uacpi_kernel_wait_for_work_completion", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("\n", .{});
    @import("util.zig").hlt();
}

export fn uacpi_kernel_io_map(base: c.uacpi_io_addr, len: c.uacpi_size, out_handle: *c.uacpi_handle) c.uacpi_status {
    std.log.info("uacpi_kernel_io_map", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("{} {} {*}\n", .{ base, len, out_handle });
    @import("util.zig").hlt();
}

export fn uacpi_kernel_io_unmap(handle: c.uacpi_handle) void {
    std.log.info("uacpi_kernel_io_unmap", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("{*}\n", .{handle});
    @import("util.zig").hlt();
}

export fn uacpi_kernel_create_spinlock() c.uacpi_handle {
    std.log.info("uacpi_kernel_create_spinlock", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("\n", .{});
    @import("util.zig").hlt();
}

export fn uacpi_kernel_free_spinlock(handle: c.uacpi_handle) void {
    std.log.info("uacpi_kernel_free_spinlock", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("{*}\n", .{handle});
    @import("util.zig").hlt();
}

export fn uacpi_kernel_lock_spinlock(handle: c.uacpi_handle) c.uacpi_cpu_flags {
    std.log.info("uacpi_kernel_lock_spinlock", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("{*}\n", .{handle});
    @import("util.zig").hlt();
}
export fn uacpi_kernel_unlock_spinlock(handle: c.uacpi_handle, flag: c.uacpi_cpu_flags) void {
    std.log.info("uacpi_kernel_unlock_spinlock", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("{*} {}\n", .{ handle, flag });
    @import("util.zig").hlt();
}

export fn uacpi_kernel_map(addr: c.uacpi_phys_addr, _: usize) usize {
    return addr + @import("hhmd.zig").get_offset();
}

export fn uacpi_kernel_unmap(_: usize, _: usize) void {}

export fn uacpi_kernel_create_mutex() c.uacpi_handle {
    std.log.info("uacpi_kernel_create_mutex", .{});
    return null;
}

export fn uacpi_kernel_free_mutex(handle: c.uacpi_handle) void {
    std.log.info("uacpi_kernel_free_mutex", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("{*}\n", .{handle});
    @import("util.zig").hlt();
}

export fn uacpi_kernel_acquire_mutex(handle: c.uacpi_handle, ms: c.uacpi_u16) c.uacpi_status {
    std.log.info("uacpi_kernel_acquire_mutex", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("{*} {}\n", .{ handle, ms });
    @import("util.zig").hlt();
}
export fn uacpi_kernel_release_mutex(handle: c.uacpi_handle) void {
    std.log.info("uacpi_kernel_release_mutex", .{});
    @import("console.zig").format("{s}:{}:{}\n", .{ @src().file, @src().line, @src().column });
    @import("console.zig").format("{*}\n", .{handle});
    @import("util.zig").hlt();
}
