const http_types = @import("http_types.zig");
const Response = http_types.Response;
const Status = http_types.Status;
const RouteParams = http_types.RouteParams;

pub fn get_root(_: RouteParams) !Response {
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

pub fn get_name(_: RouteParams) !Response {
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

pub fn get_user_age(params: RouteParams) !Response {
    return .{
        .status = Status.ok,
        .headers = &.{
            .{
                .name = "content_type",
                .value = "text/plain",
            },
        },
        .body = "Casey" + params[0].value,
    };
}
