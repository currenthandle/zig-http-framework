const std = @import("std");
const net = std.Io.net;

const RequestCtx = @import("http_types.zig").RequestCtx;

const r = @import("router.zig");
const router = r.router;

const b = @import("body.zig");
const read_request_body = b.read_request_body;
const ReceiveHeadError = std.http.Server.ReceiveHeadError;
const ExpectContinueError = std.http.Server.Request.ExpectContinueError;

pub fn handle_connection(io: std.Io, stream: net.Stream) !void {
    defer stream.close(io);

    var read_buffer: [4096]u8 = undefined;
    var write_buffer: [4096]u8 = undefined;

    var connection_reader = stream.reader(io, &read_buffer);
    var connection_writer = stream.writer(io, &write_buffer);

    var http_server = std.http.Server.init(
        &connection_reader.interface,
        &connection_writer.interface,
    );

    const max_body_bytes: usize = 1024 * 1024;
    var body_reader_buf: [4096]u8 = undefined;

    var keep_alive = true;
    while (keep_alive) {
        keep_alive = process_request(&http_server, max_body_bytes, body_reader_buf[0..]) catch |err| switch (err) {
            ReceiveHeadError.HttpConnectionClosing,
            ReceiveHeadError.HttpRequestTruncated,
            ReceiveHeadError.ReadFailed,
            // Req.respond
            // consider adding: Expect: 100-continue support
            ExpectContinueError.WriteFailed,
            ExpectContinueError.HttpExpectationFailed,
            => break,

            else => {
                std.log.err("{}", .{err});
                return err;
            },
        };
    }
}

fn process_request(http_server: *std.http.Server, max_body_bytes: usize, body_reader_buf: []u8) !bool {
    var req = try http_server.receiveHead();

    var req_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer req_arena.deinit();
    const req_allocator = req_arena.allocator();

    // save target and method before read_req_body (req.readerExpectNone)
    // poisons request /  request headers
    const req_target = req.head.target;
    const req_method = req.head.method;

    const req_body = try read_request_body(
        req_allocator,
        &req,
        max_body_bytes,
        body_reader_buf[0..],
    );

    const req_ctx: RequestCtx = .{
        .target = req_target,
        .method = req_method,
        .body = req_body,
        .allocator = req_allocator,
    };

    const response = try router(req_ctx);
    const keep_alive = req.head.keep_alive;

    try req.respond(response.body, .{
        .keep_alive = keep_alive,
        .extra_headers = response.headers,
        .status = response.status,
    });

    return keep_alive;
}
