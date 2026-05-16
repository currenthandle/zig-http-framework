const std = @import("std");

const http_types = @import("http_types.zig");
const route_handlers = @import("route_handlers.zig");
const routes = @import("routes.zig").routes;

const get_root = route_handlers.get_root;
const get_name = route_handlers.get_name;

const Request = http_types.Request;
const Response = http_types.Response;
const Status = http_types.Status;
const RouteParam = http_types.RouteParam;

pub fn router(request: Request) !Response {
    for (routes) |route| {
        if (route.method == request.head.method) {
            const req_path_segs = std.mem.splitScalar(u8, request.head.target, '/');
            const route_path_segs = std.mem.splitScalar(u8, route.target, '/');

            // why page allocator
            var route_params = std.ArrayList(http_types.RouteParam).init(std.heap.page_allocator);
            defer route_params.deinit();

            while (route_path_segs.next()) |route_seg| {
                const req_seg = req_path_segs.next() orelse break;

                if (route_seg[0] == ':' and route_seg.len > 0) {
                    try route_params.append(.{ .name = route_seg[1..], .value = req_seg });
                    // try route_params.append(req_seg);
                    continue;
                }

                if (std.mem.eql(u8, route_seg, req_seg)) break;
            }
            return route.handler(route_params.items);
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
