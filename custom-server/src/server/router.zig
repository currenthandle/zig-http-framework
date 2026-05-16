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
    route_loop: for (routes) |route| {
        if (route.method == request.head.method) {
            var req_path_segs = std.mem.splitScalar(u8, request.head.target, '/');
            var route_path_segs = std.mem.splitScalar(u8, route.target, '/');

            // why page allocator
            var route_params: std.ArrayList(RouteParam) = .empty;
            defer route_params.deinit(std.heap.page_allocator);

            while (route_path_segs.next()) |route_seg| {
                const req_seg = req_path_segs.next() orelse continue :route_loop;

                if (route_seg.len > 0 and route_seg[0] == ':') {
                    try route_params.append(std.heap.page_allocator, .{
                        .name = route_seg[1..],
                        .value = req_seg,
                    });
                    // try route_params.append(req_seg);
                    continue;
                }

                if (!std.mem.eql(u8, route_seg, req_seg)) continue :route_loop;
            }
            if (req_path_segs.next() != null) continue :route_loop;
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
