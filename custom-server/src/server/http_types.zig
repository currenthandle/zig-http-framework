const std = @import("std");

pub const Method = std.http.Method;
pub const Status = std.http.Status;
pub const Headers = []const std.http.Header;
pub const Request = std.http.Server.Request;
pub const Response = struct {
    status: Status,
    headers: Headers,
    body: []const u8,
    allocator: ?std.mem.Allocator = null,
};

// General for route params and query params
pub const Param = struct {
    name: []const u8,
    value: []const u8,
};
pub const Params = []const Param;
// pub const RequestParams = []const Param;
// pub const QueryParams = []const Param;
pub const HandlerCtx = struct {
    route_params: Params,
    query_params: Params,
    body: []const u8,
    allocator: std.mem.Allocator,
};

pub const RouteHandler = *const fn (HandlerCtx) anyerror!Response;

pub const Route = struct {
    path: []const u8,
    method: Method,
    handler: RouteHandler,
};

pub fn param(params: []const Param, name: []const u8) ?[]const u8 {
    for (params) |p| {
        if (std.mem.eql(u8, p.name, name)) return p.value;
    }
    return null;
}
