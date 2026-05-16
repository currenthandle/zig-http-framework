const std = @import("std");

pub const Method = std.http.Method;
pub const Status = std.http.Status;
pub const Headers = []const std.http.Header;
pub const Request = std.http.Server.Request;
pub const Response = struct {
    status: Status,
    headers: Headers,
    body: []const u8,
};
pub const RouteParam = struct {
    name: []const u8,
    value: []const u8,
};
pub const RouteParams = []const RouteParam;
pub const Route = struct {
    target: []const u8,
    method: std.http.Method,
    handler: *const fn (RouteParams) anyerror!Response,
};
