const std = @import("std");
const net = std.Io.net;

const RequestCtx = @import("http_types.zig").RequestCtx;

const r = @import("router.zig");
const router = r.router;

const b = @import("body.zig");
const read_req_body = b.read_req_body;

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
    var body_io_buf: [4096]u8 = undefined;
    while (true) {
        var req = http_server.receiveHead() catch |err| switch (err) {
            error.HttpConnectionClosing, error.HttpRequestTruncated, error.ReadFailed => break,

            else => {
                std.log.err("Connection error: {s}", .{@errorName(err)});
                return err;
            },
        };

        var req_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer req_arena.deinit();
        const req_allocator = req_arena.allocator();

        // save target and method before read_req_body (req.readerExpectNone) poisions request /  request headers
        const req_target = req.head.target;
        const req_method = req.head.method;

        const req_body = try read_req_body(
            req_allocator,
            &req,
            max_body_bytes,
            body_io_buf[0..],
        );

        const req_ctx: RequestCtx = .{
            .target = req_target,
            .method = req_method,
            .body = req_body,
            .allocator = req_allocator,
        };

        const response = router(req_ctx) catch |err| {
            std.log.err("Routing error: {s}", .{@errorName(err)});
            return err;
        };

        const keep_alive = req.head.keep_alive;

        req.respond(response.body, .{
            .keep_alive = keep_alive,
            .extra_headers = response.headers,
            .status = response.status,
        }) catch |err| {
            std.log.err("Response error: {s}", .{@errorName(err)});
            return err;
        };

        if (!keep_alive) break;
    }
}
