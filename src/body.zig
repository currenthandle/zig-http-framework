const std = @import("std");
const http_types = @import("http_types.zig");

const Request = http_types.Request;

pub fn read_request_body(
    allocator: std.mem.Allocator,
    req: *Request,
    max_bytes: usize,
    reader_buf: []u8,
) ![]u8 {
    if (!req.head.method.requestHasBody()) {
        return try allocator.alloc(u8, 0);
    }
    const content_length = req.head.content_length;
    const tranfer_encoding = req.head.transfer_encoding;

    if (content_length != null and tranfer_encoding != .none) {
        return error.InvalidBodyFrame;
    }
    const body_reader = req.readerExpectNone(reader_buf);
    if (content_length) |cl| {
        return read_content_length_frame(allocator, max_bytes, cl, body_reader);
    }
    if (tranfer_encoding == .chunked) {}
    return try allocator.alloc(u8, 0);
}

fn read_content_length_frame(
    allocator: std.mem.Allocator,
    max_bytes: usize,
    cl: u64,
    body_reader: *std.Io.Reader,
) ![]u8 {
    if (cl > max_bytes) {
        return error.ContentTooLarge;
    }
    const body_len: usize = @intCast(cl);

    const body = try allocator.alloc(u8, body_len);
    try body_reader.readSliceAll(body);
    return body;
}

fn read_transfer_encoding_frame(
    allocator: std.mem.Allocator,
    max_bytes: usize,
    body_reader: *std.Io.Reader,
) ![]u8 {
    var tmp_buf: [4096]u8 = undefined;
    var body_storage: std.ArrayList(u8) = .empty;
    defer body_storage.deinit(allocator);
    while (true) {
        const n = try body_reader.readSliceShort(tmp_buf[0..]);
        if (n == 0) {
            break;
        }
        if (body_storage.items.len + n > max_bytes) {
            return error.ContentTooLarge;
        }
        try body_storage.appendSlice(allocator, tmp_buf[0..n]);
    }
    return try body_storage.toOwnedSlice(allocator);
}
