const std = @import("std");
const net = std.Io.net;

const handle_connection = @import("handle_connection.zig").handle_connection;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const port = 8082;
    const address: net.IpAddress = .{ .ip4 = net.Ip4Address.unspecified(port) };

    var server = try address.listen(io, .{ .reuse_address = true });
    std.log.info("Multi-thread server listenting on port {}", .{port});


    // accept sockets
    while (true) {
        const stream = try server.accept(io);
        const thread = try std.Thread.spawn(.{}, handle_connection, .{ io, stream });
        thread.detach();
    }
}
