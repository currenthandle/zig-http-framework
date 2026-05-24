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

    const framing = try body_framing(
        req.head.content_length,
        req.head.transfer_encoding,
        max_bytes,
    );
    const body_reader = try req.readerExpectContinue(reader_buf);

    switch (framing) {
        .content_length => |cl| return read_content_length_body(allocator, max_bytes, cl, body_reader),
        .chunked => return read_chunked_body(allocator, max_bytes, body_reader),
        .none => return try allocator.alloc(u8, 0),
    }
}

const BodyFraming = union(enum) {
    none,
    content_length: u64,
    chunked,
};

fn body_framing(
    content_length: ?u64,
    transfer_encoding: std.http.TransferEncoding,
    max_bytes: usize,
) !BodyFraming {
    if (content_length != null and transfer_encoding != .none) {
        return error.InvalidBodyFraming;
    }

    if (content_length) |cl| {
        if (cl > max_bytes) return error.ContentTooLarge;

        return .{ .content_length = cl };
    }

    if (transfer_encoding == .chunked) {
        return .chunked;
    }

    return .none;
    // if (content_length) |cl| {
    //     return read_content_length_body(allocator, max_bytes, cl, body_reader);
    // }
    // if (transfer_encoding == .chunked) {
    //     return read_chunked_body(allocator, max_bytes, body_reader);
    // }
}

fn read_content_length_body(
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
    errdefer allocator.free(body);

    body_reader.readSliceAll(body) catch |err| switch (err) {
        // Content-Length said N bytes, but we could not read N bytes
        error.EndOfStream => return error.BodyTruncated,
        error.ReadFailed => return error.BodyReadFailed,
    };
    return body;
}

fn read_chunked_body(
    allocator: std.mem.Allocator,
    max_bytes: usize,
    body_reader: *std.Io.Reader,
) ![]u8 {
    var tmp_buf: [4096]u8 = undefined;
    var body_storage: std.ArrayList(u8) = .empty;
    defer body_storage.deinit(allocator);
    while (true) {
        const n = body_reader.readSliceShort(tmp_buf[0..]) catch |err| switch (err) {
            error.ReadFailed => return error.InvalidChunkedBody,
        };
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
