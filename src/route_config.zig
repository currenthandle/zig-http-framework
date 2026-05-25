const std = @import("std");
const Route = @import("http_types.zig").Route;
const Method = std.http.Method;

pub fn add_body_policy(comptime routes: []const Route) [routes.len]Route {
    var out: [routes.len]Route = undefined;
    for (routes, 0..) |route_spec, i| {
        var route = route_spec;
        if (route.body_policy == .default) {
            switch (route.method) {
                Method.POST,
                Method.PUT,
                Method.PATCH,
                => route.body_policy = .required,
                else => route.body_policy = .none,
            }
        }
        out[i] = route;
    }

    return out;
}

