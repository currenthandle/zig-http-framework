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

const Method = std.http.Method;
const Request = std.http.Server.Request;
const Status = std.http.Status;
const Headers = []const std.http.Header;

const Response = struct {
    status: Status,
    headers: Headers,
    body: []const u8,
};

const Route = struct {
    target: []const u8,
    method: std.http.Method,
    handler: *const fn () anyerror!Response,
};

fn router(request: std.http.Server.Request) !Response {
    const target = request.head.target;
    const method = request.head.method;

    const routes: []const Route = &.{
        .{
            .target = "/",
            .method = Method.GET,
            .handler = getRoot,
        },
        .{
            .target = "/name",
            .method = Method.GET,
            .handler = getName,
        },
    };

    for (routes) |route| {
        if (route.method == method and std.mem.eql(u8, route.target, target)) {
            return route.handler();
        }
    }

    return .{
        .status = Status.not_found,
        .headers = &.{.{
            .name = "content_type",
            .value = "text/plain",
        }},
        .body = "Not found\n",
    };
}

fn getRoot() !Response {
    return .{
        .status = Status.ok,
        .headers = &.{
            .{
                .name = "content_type",
                .value = "text/plain",
            },
        },
        .body = "Welcome to the root\n",
    };
}

fn getName() !Response {
    return .{
        .status = Status.ok,
        .headers = &.{
            .{
                .name = "content_type",
                .value = "text/plain",
            },
        },
        .body = "Casey\n",
    };
}
