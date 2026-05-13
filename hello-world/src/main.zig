const std = @import("std");
const Writer = std.Io.File.Writer;

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = Writer.init(
        std.Io.File.stdout(), 
        init.io, 
        &stdout_buffer
    );
    const stdout = &stdout_writer.interface;
    try stdout.print("Hello {s}!\n", .{"world"});
    try stdout.flush();
}
