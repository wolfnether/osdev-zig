const std = @import("std");

const util = @import("util.zig");

const fontEmbedded = @embedFile("font.psf");

const limine = @import("limine.zig");

var framebuffer: *limine.limine.Framebuffer = undefined;

// Display text on screen
const PsfFont = packed struct {
    magic: u32, // magic bytes to identify PSF
    version: u32, // zero
    headersize: u32, // offset of bitmaps in file, 32
    flags: u32, // 0 if there's no unicode table
    numglyph: u32, // number of glyphs
    bytesperglyph: u32, // size of each glyph
    height: u32, // height in pixels
    width: u32, // width in pixels
};

const console_context = struct { x: usize, y: usize };
var ctx = console_context{ .x = 0, .y = 0 };
pub const writer = std.io.GenericWriter(void, error{}, cb){ .context = {} };

fn pan(line_per_screen: usize, font_height: usize) void {
    if (ctx.y > line_per_screen) {
        var slice: [*]u8 = @ptrCast(framebuffer.address);
        const screen_size = framebuffer.height * framebuffer.pitch;
        const char_line = font_height * framebuffer.pitch;
        std.mem.copyForwards(u8, slice[0 .. screen_size - char_line], slice[char_line..screen_size]);
        ctx.y -= 1;
        for (screen_size - char_line..screen_size) |i| {
            slice[i] = 0;
        }
    }
}

fn cb(_: void, string: []const u8) error{}!usize {
    const font: PsfFont = @bitCast(fontEmbedded[0..@sizeOf(PsfFont)].*);

    const bytesperline = (font.width + 7) / 8;
    const char_per_line = (framebuffer.width) / (font.width + 1);
    const line_per_screen = framebuffer.height / font.height - 1;
    var fb: [*]u32 = @ptrCast(@alignCast(framebuffer.address));

    for (string) |char| {
        util.outb(0x3f8, char);
        if (char == '\n') {
            ctx.x = 0;
            ctx.y += 1;
            pan(line_per_screen, font.height);
            continue;
        }
        if (ctx.x == char_per_line) {
            ctx.x = 0;
            ctx.y += 1;
            pan(line_per_screen, font.height);
        }

        var offs = ctx.x * (font.width + 1) * 4 + ctx.y * framebuffer.pitch * font.height;
        var idx = if (char > 0 and char < font.numglyph) blk: {
            break :blk font.headersize + (char * font.bytesperglyph);
        } else blk: {
            break :blk font.headersize + (0 * font.bytesperglyph);
        };

        for (0..font.height) |_| {
            var line = offs;
            var mask = @as(u32, 1) << @as(u5, @intCast(font.width - 1));

            for (0..font.width) |_| {
                if ((fontEmbedded[idx] & mask) == 0) {
                    fb[line / @sizeOf(u32)] = 0x000000;
                } else {
                    fb[line / @sizeOf(u32)] = 0xFFFFFF;
                }
                mask >>= 1;
                line += 4;
            }

            fb[line / @sizeOf(u32)] = 0;
            idx += bytesperline;
            offs += framebuffer.pitch;
        }
        ctx.x += 1;
    }
    return string.len;
}

pub inline fn format(comptime fmt: []const u8, args: anytype) void {
    try std.fmt.format(writer, fmt, args);
}

pub inline fn init() void {
    util.outb(0x3f8 + 1, 0x00);
    util.outb(0x3f8 + 3, 0x80);
    util.outb(0x3f8 + 0, 0x03);
    util.outb(0x3f8 + 1, 0x00);
    util.outb(0x3f8 + 3, 0x03);
    util.outb(0x3f8 + 2, 0xC7);
    util.outb(0x3f8 + 4, 0x0B);
    util.outb(0x3f8 + 4, 0x0F);

    if (limine.framebuffer_request.response) |res| {
        framebuffer = &res.getFramebuffers()[0].*;
    }

    //format("\n", .{});
}
