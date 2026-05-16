const http_types = @import("http_types.zig");
const Response = http_types.Response;
const Status = http_types.Status;
const Params = http_types.Params;

pub fn get_root(_: Params, _: Params) !Response {
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

pub fn get_name(_: Params, _: Params) !Response {
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

pub fn get_user_age(query_params: Params, _: Params) !Response {
    return .{
        .status = Status.ok,
        .headers = &.{
            .{
                .name = "content_type",
                .value = "text/plain",
            },
        },
        .body = query_params[0].value,
    };
}
