const std = @import("std");
const net = std.Io.net;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const address: net.IpAddress = .{ .ip4 = net.Ip4Address.unspecified(8082) };

    var server = try address.listen(io, .{ .reuse_address = true });

    // accept sockets
    while (true) {
        const stream = try server.accept(io);
        const thread = try std.Thread.spawn(.{}, handleConnection, .{ io, stream });
        thread.detach();
    }
}

fn handleConnection(io: std.Io, stream: net.Stream) !void {
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

        const target = request.head.target;
        std.log.debug("Target: {s}", .{target});

        const keep_alive = request.head.keep_alive;
        try request.respond("Hello from multi-threaded router Zig server\n", .{
            .keep_alive = keep_alive,
            .extra_headers = &.{
                .{ .name = "content-type", .value = "text/plain" },
            },
        });

        if (!keep_alive) break;
    }
}
