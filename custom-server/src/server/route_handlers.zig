const std = @import("std");
const http_types = @import("http_types.zig");
const Response = http_types.Response;
const Status = http_types.Status;
const HandlerCtx = http_types.HandlerCtx;
const param = http_types.param;

pub fn get_root(_: HandlerCtx) !Response {
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

pub fn get_name(_: HandlerCtx) !Response {
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

pub fn get_user_age(ctx: HandlerCtx) !Response {
    const route_params = ctx.route_params;

    return .{
        .status = Status.ok,
        .headers = &.{
            .{
                .name = "content_type",
                .value = "text/plain",
            },
        },
        .body = param(route_params, "age") orelse "missing",
    };
}

pub fn add_user(ctx: HandlerCtx) !Response {
    return .{
        .status = Status.created,
        .headers = &.{
            .{
                .name = "content_type",
                .value = "text/plain",
            },
        },
        .body = try std.fmt.allocPrint(
            ctx.allocator,
            "Created new user {s}",
            .{ctx.body},
        ),
    };
}
