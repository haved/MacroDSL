const std = @import("std");
const Frame = @import("frame.zig").Frame;
const Layout = @import("layout.zig").Layout;
const Window = @import("window.zig").Window;

pub fn main() !void {
    var gpalloc = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!gpalloc.deinit());

    const alloc = &gpalloc.allocator;

    var frame = try Frame.init(1600, 900, alloc);
    defer frame.deinit();

    frame.setLayout(try makeDefaultLayout(&frame, alloc));
    frame.loop();
}

fn makeDefaultLayout(frame: *Frame, alloc: *std.mem.Allocator) !Layout {
    const buffer = try frame.createBuffer("Main Buffer");
    const macro_buffer = try frame.createBuffer("Macro buffer");

    const main_window = Window {
        .buffer = buffer,
        .alloc = alloc
    };
    const macro_window = Window {
        .buffer = macro_buffer,
        .alloc = alloc
    };
    var modeline_split = modeline_split: {
        var main_split = try Layout.initSplitLayout(
            Layout{
                .content = .{
                    .window = main_window
                }
            },
            Layout{
                .content = .{
                    .window = macro_window
                }
            },
            Layout.SplitDirection.vertical, 6, true,
            100, 100, 200, 100, alloc
        );
        errdefer main_split.deinit();
        break :modeline_split try Layout.initSplitLayout(
            main_split,
            Layout{
                .content = .empty,
                .height = 32
            },
            Layout.SplitDirection.horizontal, 0, false,
            0, 32, 1, 0, alloc
        );
    };
    errdefer modeline_split.deinit();
    return try Layout.initBorderLayout(modeline_split, 4, alloc);
}
