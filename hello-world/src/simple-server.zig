const std = @import("std");
const net = std.Io.net;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const address: net.IpAddress = .{ .ip4 = net.Ip4Address.unspecified(8080) };

    var server = try address.listen(io, .{ .reuse_address = true });
    defer server.deinit(io);

    while (true) {
        const stream = try server.accept(io);

        try handleConnection(io, stream);
    }
}

fn handleConnection(io: std.Io, stream: net.Stream) !void {
    defer stream.close(io);

    var read_buffer: [4096]u8 = undefined;
    var write_buffer: [4096]u8 = undefined;

    var connection_reader = stream.reader(io, &read_buffer);
    var connection_writer = stream.writer(io, &write_buffer);

    var http_server = std.http.Server.init(&connection_reader.interface, &connection_writer.interface);

    var request = try http_server.receiveHead();

    try request.respond("Hello from Zig\n", .{
        .keep_alive = false,
        .extra_headers = &.{
            .{ .name = "content-type", .value = "text/plain" },
        },
    });
}
