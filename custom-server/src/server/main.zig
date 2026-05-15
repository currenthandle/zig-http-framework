const std = @import("std");
const net = std.Io.net;

const handle_connection = @import("handle_connection.zig").handle_connection;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const address: net.IpAddress = .{ .ip4 = net.Ip4Address.unspecified(8082) };

    var server = try address.listen(io, .{ .reuse_address = true });

    // accept sockets
    while (true) {
        const stream = try server.accept(io);
        const thread = try std.Thread.spawn(.{}, handle_connection, .{ io, stream });
        thread.detach();
    }
}
