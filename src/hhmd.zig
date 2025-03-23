var offset: usize = 0;

pub fn init() void {
    if (@import("limine.zig").hhdm_request.response) |res| {
        offset = res.offset;
    }
}

pub fn get_offset() usize {
    return offset;
}
