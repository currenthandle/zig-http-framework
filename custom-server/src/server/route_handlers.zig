const http_types = @import("http_types.zig");
const Response = http_types.Response;
const Status = http_types.Status;

pub fn get_root() !Response {
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

pub fn get_name() !Response {
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
