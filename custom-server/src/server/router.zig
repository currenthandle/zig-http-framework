const std = @import("std");

const http_types = @import("http_types.zig");
const route_handlers = @import("route_handlers.zig");
const routes = @import("routes.zig").routes;

const get_root = route_handlers.get_root;
const get_name = route_handlers.get_name;

const Request = http_types.Request;
const Response = http_types.Response;
const Status = http_types.Status;
const Param = http_types.Param;
// const Params = http_types.Params;

fn parse_query_params(query_str: []const u8, buf: []Param) []const Param {
    var query_segs = std.mem.splitScalar(u8, query_str, '&');

    var param_pos: usize = 0;

    while (query_segs.next()) |query_seg| {
        if (param_pos >= buf.len) {
            std.log.err("Max query params {} exceeded", .{buf.len});
            break;
        }
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

pub fn router(request: Request) !Response {
    var query_buf: [24]Param = undefined;
    const has_query = std.mem.indexOfScalar(u8, request.head.target, '?');

    var req_path: []const u8 = request.head.target;
    var query_params: []const Param = &.{};

    if (has_query) |query_pos| {
        req_path = request.head.target[0..query_pos];
        const query_str = request.head.target[query_pos + 1 ..];
        query_params = parse_query_params(query_str, query_buf[0..]);
    }

    for (query_params) |param| {
        std.log.debug("Name: {s}", .{param.name});
        std.log.debug("Value: {s}", .{param.value});
    }

    route_loop: for (routes) |route| {
        if (route.method == request.head.method) {
            var req_path_segs = std.mem.splitScalar(u8, req_path, '/');
            var route_path_segs = std.mem.splitScalar(u8, route.target, '/');

            // var debug_req_path_segs = std.mem.splitScalar(u8, request.head.target, '/');
            // while (debug_req_path_segs.next()) |seg| {
            //     std.log.debug("req seg: {s}", .{seg});
            // }
            //
            // var debug_route_path_segs = std.mem.splitScalar(u8, route.target, '/');
            // while (debug_route_path_segs.next()) |seg| {
            //     std.log.debug("route seg: {s}", .{seg});
            // }

            var param_buf: [8]Param = undefined;
            var param_count: usize = 0;

            while (route_path_segs.next()) |route_seg| {
                const req_seg = req_path_segs.next() orelse continue :route_loop;

                if (route_seg.len > 0 and route_seg[0] == ':') {
                    if (param_count >= param_buf.len) {
                        std.log.err("Max route params {} exceeded", .{param_buf.len});
                        continue :route_loop;
                    }

                    param_buf[param_count] = .{
                        .name = route_seg[1..],
                        .value = req_seg,
                    };
                    param_count += 1;
                    // try route_params.append(req_seg);
                    continue;
                }

                if (!std.mem.eql(u8, route_seg, req_seg)) continue :route_loop;
            }
            if (req_path_segs.next() != null) continue :route_loop;
            return route.handler(param_buf[0..param_count]);
        }
    }

    return .{
        .status = Status.not_found,
        .headers = &.{.{
            .name = "content_type",
            .value = "text/plain",
        }},
        .body = "Not found",
    };
}
