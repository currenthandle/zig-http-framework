const std = @import("std");

const http_types = @import("http_types.zig");
const route_handlers = @import("route_handlers.zig");
const routes = @import("routes.zig").routes;

const get_root = route_handlers.get_root;
const get_name = route_handlers.get_name;

const Request = http_types.Request;
const Response = http_types.Response;
const Status = http_types.Status;

pub fn router(request: Request) !Response {
    const target = request.head.target;
    const method = request.head.method;


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
        .body = "Not found",
    };
}
