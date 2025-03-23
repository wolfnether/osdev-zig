const std = @import("std");
const allocator = @import("allocator.zig").allocator;
const CpuStatus = @import("interrupt.zig").CpuStatus;

const Dwarf = @import("custom_std/debug/Dwarf.zig");

fn eql(a: [*c]const u8, b: []const u8) bool {
    for (b, 0..) |c, i| {
        if (a[i] == 0) return false;
        if (a[i] != c) return false;
    }
    return true;
}

fn getSelfDebugInfo() !Dwarf {
    var sections = Dwarf.null_section_array;
    const sections_id = Dwarf.Section.Id;

    const file = @import("limine.zig").kernel.response.?.executable_file;
    const file_ptr: [*]const u8 = @ptrCast(file.address);
    const file_size = file.size;
    var stream_source = std.io.StreamSource{ .const_buffer = std.io.FixedBufferStream([]const u8){ .buffer = file_ptr[0..file_size], .pos = 0 } };
    const header = try std.elf.Header.read(&stream_source);
    var sh_it = header.section_header_iterator(&stream_source);

    sh_it.index = header.shstrndx;
    const shstrtab_header = (try sh_it.next()).?;
    const shstrtab: [*c]const u8 = @ptrCast(file_ptr[shstrtab_header.sh_offset..]);
    sh_it.index = 0;

    while (try sh_it.next()) |entry| {
        const name = shstrtab[entry.sh_name..];
        const start = if (entry.sh_addr != 0) entry.sh_addr else entry.sh_offset + @intFromPtr(file_ptr);

        const slice = @as([*]u8, @ptrFromInt(start))[0..entry.sh_size];

        if (eql(name, ".eh_frame_hdr")) {
            sections[@intFromEnum(sections_id.eh_frame_hdr)] = .{ .data = slice, .owned = false };
        } else if (eql(name, ".eh_frame")) {
            sections[@intFromEnum(sections_id.eh_frame)] = .{ .data = slice, .owned = false };
        } else if (eql(name, ".debug_info")) {
            sections[@intFromEnum(sections_id.debug_info)] = .{ .data = slice, .owned = false };
        } else if (eql(name, ".debug_abbrev")) {
            sections[@intFromEnum(sections_id.debug_abbrev)] = .{ .data = slice, .owned = false };
        } else if (eql(name, ".debug_addr")) {
            sections[@intFromEnum(sections_id.debug_addr)] = .{ .data = slice, .owned = false };
        } else if (eql(name, ".debug_frame")) {
            sections[@intFromEnum(sections_id.debug_frame)] = .{ .data = slice, .owned = false };
        } else if (eql(name, ".debug_loc")) {
            sections[@intFromEnum(sections_id.debug_loclists)] = .{ .data = slice, .owned = false };
        } else if (eql(name, ".debug_ranges")) {
            sections[@intFromEnum(sections_id.debug_ranges)] = .{ .data = slice, .owned = false };
        } else if (eql(name, ".debug_line")) {
            sections[@intFromEnum(sections_id.debug_line)] = .{ .data = slice, .owned = false };
            //} else if (eql(name, ".debug_pubnames")) {
            //    sections[@intFromEnum(sections_id.debug_names)] = .{ .data = slice, .owned = false };
        } else if (eql(name, ".debug_str")) {
            sections[@intFromEnum(sections_id.debug_str)] = .{ .data = slice, .owned = false };
        }
    }

    var dwarf_info = Dwarf{
        .endian = .little,
        .is_macho = false,
        .sections = sections,
    };

    try dwarf_info.open(allocator);
    try dwarf_info.scanAllUnwindInfo(allocator, 0xffffffff80000000);
    return dwarf_info;
}

var is_unwinding = false;

fn dump_pc(pc: usize, sym: std.debug.Symbol) void {
    if (sym.source_location) |source_location| {
        std.log.info("@ 0x{X:0>16} {s} {s}:{}:{}", .{
            pc,
            sym.name,
            source_location.file_name,
            source_location.line,
            source_location.column,
        });
    } else {
        std.log.info("@ 0x{X:0>16} {s} {s}", .{
            pc,
            sym.name,
            sym.compile_unit_name,
        });
    }
}

pub fn unwinding(cpu_state: *CpuStatus) noreturn {
    defer {
        @import("util.zig").hlt();
    }

    if (is_unwinding) {
        return;
    }
    is_unwinding = true;

    var dwarf_info = getSelfDebugInfo() catch |err| {
        std.log.err("unable to get debug info: {}\n", .{err});
        return;
    };

    const SelfInfo = @import("custom_std/debug/SelfInfo.zig");

    var ma = std.debug.MemoryAccessor{ .mem = {} };
    var context = SelfInfo.UnwindContext{
        .allocator = allocator,
        .cfa = null,
        .pc = cpu_state.rip,
        .thread_context = @ptrCast(cpu_state),
        .reg_context = undefined,
        .vm = .{},
        .stack_machine = .{},
    };

    var sym = try dwarf_info.getSymbol(allocator, cpu_state.rip);

    dump_pc(cpu_state.rip, sym);

    while (true) {
        const pc = SelfInfo.unwindFrameDwarf(allocator, &dwarf_info, 0, &context, &ma, null) catch |e| {
            return std.log.err("error @ unwindFrameDwarf {}", .{e});
        };
        if (pc == 0) break;

        sym = try dwarf_info.getSymbol(allocator, pc);

        dump_pc(pc, sym);
    }
}
