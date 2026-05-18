const std = @import("std");
const http_types = @import("http_types.zig");

const Request = http_types.Request;

pub fn read_request_body(allocator: std.mem.Allocator, req: *Request, max_bytes: usize, reader_buf: []u8) ![]u8 {
    if (!req.head.method.requestHasBody()) {
        return try allocator.alloc(u8, 0);
    }
    const body_reader = req.readerExpectNone(reader_buf);
    if (req.head.content_length) |len| {
        if (len > max_bytes) {
            return error.ContentTooLarge;
        }
        const body_len: usize = @intCast(len);

        const body = try allocator.alloc(u8, body_len);
        try body_reader.readSliceAll(body);
        return body;
    }
    return try allocator.alloc(u8, 0);
}
