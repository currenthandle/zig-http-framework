const http_types = @import("http_types.zig");
const Response = http_types.Response;
const Status = http_types.Status;

pub fn not_found() Response {
    return .{
        .status = Status.not_found,
        .headers = &.{.{
            .name = "content_type",
            .value = "text/plain",
        }},
        .body = "Not found",
    };
}

pub fn bad_request(msg: []const u8) Response {
    return .{
        .status = Status.bad_request,
        .headers = &.{.{
            .name = "content_type",
            .value = "text/plain",
        }},
        .body = msg,
    };
}
