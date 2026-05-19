const std = @import("std");

const http_types = @import("http_types.zig");
const routes = @import("routes.zig").routes;

const Response = http_types.Response;
const Param = http_types.Param;
const Route = http_types.Route;
const Method = http_types.Method;
const RequestCtx = http_types.RequestCtx;

const RouteHandler = http_types.RouteHandler;

const responses = @import("responses.zig");
const not_found = responses.not_found;
const bad_request = responses.bad_request;

pub fn router(ctx: RequestCtx) !Response {
    var route_buf: [8]Param = undefined;
    var query_buf: [24]Param = undefined;

    const parsed_target = parse_target(ctx.target, query_buf[0..]) catch {
        return bad_request("Max query params exceeded");
    };

    const req_path = parsed_target.path;
    const query_params = parsed_target.query_params;

    for (routes) |route| {
        if (route.method != ctx.method) continue;

        const match_opt = match_route(req_path, route, route_buf[0..]) catch {
            return bad_request("Max route params exceeded");
        };

        const matched_route = match_opt orelse continue;

        return matched_route.handler(.{
            .route_params = matched_route.params,
            .query_params = query_params,
            .body = ctx.body,
            .allocator = ctx.allocator,
        });
    }

    return not_found();
}

const ParsedTarget = struct {
    path: []const u8,
    query_params: []const Param,
};

const ParamError = error{TooMany};

fn parse_target(target: []const u8, query_buf: []Param) ParamError!ParsedTarget {
    var req_path: []const u8 = target;
    var query_params: []const Param = &.{};

    const has_query = std.mem.indexOfScalar(u8, target, '?');
    if (has_query) |query_pos| {
        req_path = target[0..query_pos];
        const query_str = target[query_pos + 1 ..];
        query_params = try parse_query_params(query_str, query_buf[0..]);
    }

    return .{
        .path = req_path,
        .query_params = query_params,
    };
}

fn parse_query_params(query_str: []const u8, buf: []Param) ParamError![]const Param {
    var query_segs = std.mem.splitScalar(u8, query_str, '&');

    var param_count: usize = 0;

    while (query_segs.next()) |query_seg| {
        if (param_count >= buf.len) return ParamError.TooMany;

        const has_eq = std.mem.indexOfScalar(u8, query_seg, '=');
        if (has_eq) |eq_pos| {
            const name = query_seg[0..eq_pos];
            const value = query_seg[eq_pos + 1 ..];

            buf[param_count] = .{
                .name = name,
                .value = value,
            };
            param_count += 1;
        }
    }
    return buf[0..param_count];
}

const Match = struct {
    handler: RouteHandler,
    params: []const Param,
};

fn match_route(req_path: []const u8, route: Route, buf: []Param) ParamError!?Match {
    var req_path_segs = std.mem.splitScalar(u8, req_path, '/');
    var route_path_segs = std.mem.splitScalar(u8, route.path, '/');

    var param_count: usize = 0;

    while (route_path_segs.next()) |route_seg| {
        const req_seg = req_path_segs.next() orelse return null;

        if (route_seg.len > 0 and route_seg[0] == ':') {
            if (param_count >= buf.len) return ParamError.TooMany;

            buf[param_count] = .{
                .name = route_seg[1..],
                .value = req_seg,
            };
            param_count += 1;
            continue;
        }

        if (!std.mem.eql(u8, route_seg, req_seg)) return null;
    }
    if (req_path_segs.next() != null) return null;
    const route_params = buf[0..param_count];

    return .{
        .handler = route.handler,
        .params = route_params,
    };
}
