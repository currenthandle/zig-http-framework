const std = @import("std");

const http_types = @import("http_types.zig");
const routes = @import("routes.zig").routes;

const Response = http_types.Response;
const Param = http_types.Param;
const Route = http_types.Route;
const Method = http_types.Method;
const RequestCtx= http_types.RequestCtx;

const RouteHandler = http_types.RouteHandler;

const responses = @import("responses.zig");
const not_found = responses.not_found;
const bad_request = responses.bad_request;

fn parse_query_params(query_str: []const u8, buf: []Param) ![]const Param {
    var query_segs = std.mem.splitScalar(u8, query_str, '&');

    var param_pos: usize = 0;

    while (query_segs.next()) |query_seg| {
        if (param_pos >= buf.len) return error.TooManyQueryParams;

        const has_eq = std.mem.indexOfScalar(u8, query_seg, '=');
        if (has_eq) |eq_pos| {
            const name = query_seg[0..eq_pos];
            const value = query_seg[eq_pos + 1 ..];

            buf[param_pos] = .{
                .name = name,
                .value = value,
            };
            param_pos += 1;
        }
    }
    return buf[0..param_pos];
}

pub fn router(ctx: RequestCtx) !Response {
    var req_path: []const u8 = ctx.target;
    var query_params: []const Param = &.{};

    var route_buf: [8]Param = undefined;
    var query_buf: [24]Param = undefined;
    const has_query = std.mem.indexOfScalar(u8, ctx.target, '?');

    if (has_query) |query_pos| {
        req_path = ctx.target[0..query_pos];
        const query_str = ctx.target[query_pos + 1 ..];
        query_params = parse_query_params(query_str, query_buf[0..]) catch {
            return bad_request("Max query params exceeded");
        };
    }

    // for (query_params) |param| {
    //     std.log.debug("Name: {s}", .{param.name});
    //     std.log.debug("Value: {s}", .{param.value});
    // }

    // route_loop: for (routes) |route| {
    for (routes) |route| {
        if (route.method == ctx.method) {
            // copied out
            const match = match_route(req_path, route, route_buf[0..]);
            switch (match) {
                .no_match => continue,
                .too_many_params => return bad_request("Max route params exceeded"),
                .match => |route_ctx| {

                    return route_ctx.handler(.{
                        .route_params = route_ctx.params,
                        .query_params = query_params,
                        .body = ctx.body,
                        .allocator = ctx.allocator,
                    });
                },
            }
        }
    }

    return not_found();
}
const MatchResult = union(enum) {
    match: struct { handler: RouteHandler, params: []const Param },
    no_match,
    too_many_params,
};

fn match_route(req_path: []const u8, route: Route, buf: []Param) MatchResult {
    var req_path_segs = std.mem.splitScalar(u8, req_path, '/');
    var route_path_segs = std.mem.splitScalar(u8, route.path, '/');

    // std.log.debug("route.path: {s}\n", .{route.path});
    // var debug_req_path_segs = std.mem.splitScalar(u8, req_path, '/');
    // while (debug_req_path_segs.next()) |seg| {
    //     std.log.debug("req seg: {s}", .{seg});
    // }
    //
    // var debug_route_path_segs = std.mem.splitScalar(u8, route.path, '/');
    // while (debug_route_path_segs.next()) |seg| {
    //     std.log.debug("route seg: {s}", .{seg});
    // }

    var param_count: usize = 0;

    while (route_path_segs.next()) |route_seg| {
        const req_seg = req_path_segs.next() orelse return MatchResult.no_match;

        if (route_seg.len > 0 and route_seg[0] == ':') {
            if (param_count >= buf.len) return MatchResult.too_many_params;

            buf[param_count] = .{
                .name = route_seg[1..],
                .value = req_seg,
            };
            param_count += 1;
            continue;
        }

        if (!std.mem.eql(u8, route_seg, req_seg)) return MatchResult.no_match;
    }
    if (req_path_segs.next() != null) return MatchResult.no_match;
    const route_params = buf[0..param_count];

    return .{
        .match = .{
            .handler = route.handler,
            .params = route_params,
        },
    };

    // return route.handler(.{
    //     .route_params = route_params,
    //     .query_params = query_params,
    // });
}
