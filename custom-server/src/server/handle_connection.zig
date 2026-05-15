const std = @import("std");
const net = std.Io.net;

const router = @import("router.zig").router;

pub fn handle_connection(io: std.Io, stream: net.Stream) !void {
    defer stream.close(io);

    var read_buffer: [4096]u8 = undefined;
    var write_buffer: [4096]u8 = undefined;

    var connection_reader = stream.reader(io, &read_buffer);
    var connection_writer = stream.writer(io, &write_buffer);

    var http_server = std.http.Server.init(&connection_reader.interface, &connection_writer.interface);

    while (true) {
        var request = http_server.receiveHead() catch |err| switch (err) {
            error.HttpConnectionClosing, error.HttpRequestTruncated, error.ReadFailed => break,

            else => {
                std.log.err("Connection error: {s}", .{@errorName(err)});
                return err;
            },
        };

        const response = router(request) catch |err| {
            std.log.err("Routing error: {s}", .{@errorName(err)});
            return err;
        };

        const keep_alive = request.head.keep_alive;

        request.respond(response.body, .{
            .keep_alive = keep_alive,
            .extra_headers = response.headers,
        }) catch |err| {
            std.log.err("Response error: {s}", .{@errorName(err)});
            return err;
        };

        if (!keep_alive) break;
    }
}
