const std = @import("std");
const http_types = @import("http_types.zig");
const Response = http_types.Response;
const Status = http_types.Status;
const HandlerCtx = http_types.HandlerCtx;
const param = http_types.param;
const resp = @import("responses.zig");

pub fn get_root(_: HandlerCtx) !Response {
    return resp.text(Status.ok, "Welcome to the root");
}

pub fn get_name(_: HandlerCtx) !Response {
    return resp.text(Status.ok, "Casey");
}

pub fn get_user_age(ctx: HandlerCtx) !Response {
    return resp.text(
        Status.ok,
        param(ctx.route_params, "age") orelse "missing",
    );
}

pub fn add_user(ctx: HandlerCtx) !Response {
    return resp.text(
        Status.created,
        try std.fmt.allocPrint(
            ctx.allocator,
            "Created new user {s}",
            .{ctx.body},
        ),
    );
}
