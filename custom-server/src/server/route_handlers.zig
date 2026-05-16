const http_types = @import("http_types.zig");
const Response = http_types.Response;
const Status = http_types.Status;
const HandlerContext = http_types.HandlerContext;
const param = http_types.param;

pub fn get_root(_: HandlerContext) !Response {
    return .{
        .status = Status.ok,
        .headers = &.{
            .{
                .name = "content_type",
                .value = "text/plain",
            },
        },
        .body = "Welcome to the root",
    };
}

pub fn get_name(_: HandlerContext) !Response {
    return .{
        .status = Status.ok,
        .headers = &.{
            .{
                .name = "content_type",
                .value = "text/plain",
            },
        },
        .body = "Casey",
    };
}

pub fn get_user_age(ctx: HandlerContext) !Response {
    const route_params = ctx.route_params;
    return .{
        .status = Status.ok,
        .headers = &.{
            .{
                .name = "content_type",
                .value = "text/plain",
            },
        },
        // .body = route_params[0].value,
        .body = param(route_params, "age") orelse "missing",
    };
}
