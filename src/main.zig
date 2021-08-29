const std = @import("std");
const Frame = @import("frame.zig").Frame;

pub fn main() !void {
    var gpalloc = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!gpalloc.deinit());

    const alloc = &gpalloc.allocator;

    var frame = try Frame.init(1600, 900, alloc);
    defer frame.deinit();

    const buffer = try frame.createBuffer("Main Buffer");
    const window = try frame.createWindow(buffer);

    const macro_buffer = try frame.createBuffer("Macro buffer");
    const macro_window = try frame.createWindow(macro_buffer);

    frame.loop();
}
