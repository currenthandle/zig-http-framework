const http_types = @import("http_types.zig");
const Route = http_types.Route;
const Method = http_types.Method;

const route_handlers = @import("route_handlers.zig");
const get_root = route_handlers.get_root;
const get_name = route_handlers.get_name;
const get_user_age = route_handlers.get_user_age;
const add_user = route_handlers.add_user;

pub const routes: []const Route = &.{
    .{
        .path = "/",
        .method = Method.GET,
        .handler = get_root,
    },
    .{
        .path = "/name",
        .method = Method.GET,
        .handler = get_name,
    },
    .{
        .path = "/person/:age",
        .method = Method.GET,
        .handler = get_user_age,
    },
    .{
        .path = "/user",
        .method = Method.POST,
        .handler = add_user,
    },
};
