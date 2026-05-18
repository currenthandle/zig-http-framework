const std = @import("std");
const http_types = @import("http_types.zig");
const Method = http_types.Method;

const Request = http_types.Request;

pub fn read_request_body(allocator: std.mem.Allocator, req: *Request, max_bytes: usize, io_buf: []u8) ![]u8 {
    if (!req.head.method.requestHasBody()) {
        return try allocator.alloc(u8, 0);
    }
    const body_reader = req.readerExpectNone(io_buf);
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

// pub fn read_request_body(allocator: std.mem.Allocator, req: *Request, max_bytes: usize, io_buf: []u8) ![]u8 {
//     if (!req.head.method.requestHasBody()) {
//         return try allocator.alloc(u8, 0);
//     }
//     const body_reader = req.readerExpectNone(io_buf);
//     if (req.head.content_length) |len| {
//         if (len > max_bytes) {
//             return error.ContentTooLarge;
//         }
//         const body_len: usize = @intCast(len);
//
//         const body = try allocator.alloc(u8, body_len);
//
//         // Manully handle body chunks (body chunks / partial reads) for streaming etc.:
//
//         var read_pos: usize = 0;
//
//         while (read_pos < body_len) {
//             const n = try body_reader.readSliceShort(body[read_pos..]);
//
//             if (n == 0) {
//                 return error.RequestBodyTruncated;
//             }
//
//             read_pos += n;
//         }
//
//         return body;
//     }
//     return try allocator.alloc(u8, 0);
// }
