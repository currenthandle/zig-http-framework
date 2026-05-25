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
        keep_alive = process_request(
            &http_server,
            max_body_bytes,
            body_reader_buf[0..],
        ) catch |err| switch (err) {
            else => {
                std.log.err("{}", .{err});
                return err;
            },
        };
    }
}

fn process_request(
    http_server: *std.http.Server,
    max_body_bytes: usize,
    body_reader_buf: []u8,
) !bool {
    var req = http_server.receiveHead() catch |err| switch (err) {
        ReceiveHeadError.HttpConnectionClosing,
        ReceiveHeadError.HttpRequestTruncated,
        ReceiveHeadError.ReadFailed,
        // Could be 431 later, but no Request exists yet.
        ReceiveHeadError.HttpHeadersOversize,
        // Could be 400 later, but no Request exists yet.
        ReceiveHeadError.HttpHeadersInvalid,
        => return false,
    };

    var req_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer req_arena.deinit();
    const req_allocator = req_arena.allocator();

    const req_target = try req_allocator.dupe(u8, req.head.target);
    const req_method = req.head.method;
    const keep_alive = req.head.keep_alive;

    const req_body = read_request_body(
        req_allocator,
        &req,
        max_body_bytes,
        body_reader_buf[0..],
    ) catch |err| return try handle_request_body_errors(
        err,
        &req,
        keep_alive,
    );

    const req_ctx: RequestCtx = .{
        .target = req_target,
        .method = req_method,
        .body = req_body,
        .allocator = req_allocator,
    };

    const response = try router(req_ctx);

    try req.respond(response.body, .{
        .keep_alive = keep_alive,
        .extra_headers = response.headers,
        .status = response.status,
    });

    return keep_alive;
}

fn handle_request_body_errors(
    err: anyerror,
    req: *std.http.Server.Request,
    keep_alive: bool,
) !bool {
    switch (err) {
        error.ContentTooLarge => return try respond_error(
            req,
            keep_alive,
            std.http.Status.payload_too_large,
        ),
        error.InvalidBodyFraming,
        error.BodyTruncated,
        error.InvalidChunkedBody,
        error.BodyNotAllowed,
        => return try respond_error(
            req,
            keep_alive,
            std.http.Status.bad_request,
        ),

        ExpectContinueError.HttpExpectationFailed => {
            req.head.expect = null;
            return try respond_error(
                req,
                false,
                std.http.Status.expectation_failed,
            );
        },
        ExpectContinueError.WriteFailed,
        error.OutOfMemory,
        error.BodyReadFailed,
        => return err,
        else => return err,
    }
}

fn respond_error(
    req: *std.http.Server.Request,
    keep_alive: bool,
    status: std.http.Status,
) !bool {
    try req.respond("", .{
        .keep_alive = keep_alive,
        .extra_headers = &.{},
        .status = status,
    });
    return keep_alive;
}
