const http_types = @import("http_types.zig");
const Route = http_types.Route;
const Method = http_types.Route;

const route_handlers = @import("route_handlers.zig");
const get_root = route_handlers.get_root;
const get_name = route_handlers.get_name;

pub const routes: []const Route = &.{
    .{
        .target = "/",
        .method = Method.GET,
        .handler = get_root,
    },
    .{
        .target = "/name",
        .method = Method.GET,
        .handler = get_name,
    },
};
