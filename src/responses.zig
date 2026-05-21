const http_types = @import("http_types.zig");
const Response = http_types.Response;
const Status = http_types.Status;

pub fn not_found() Response {
    return text(Status.not_found, "Not found");
}

pub fn bad_request(msg: []const u8) Response {
    return text(Status.bad_request, msg);
}

pub fn text(status: Status, body: []const u8) Response {
    return .{
        .status = status,
        .headers = &.{.{
            .name = "content-type",
            .value = "text/plain",
        }},
        .body = body,
    };
}
