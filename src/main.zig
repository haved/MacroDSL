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
    const layout = try Layout.initSplitLayout(
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
        Layout.SplitDirection.vertical,
        3, 1, alloc
    );
    const layout2 = try Layout.initSplitLayout(
        layout,
        Layout{
            .content = .empty,
            .height = 32
        },
        Layout.SplitDirection.horizontal,
        1, 0, alloc
    );

    frame.setLayout(layout2);
    frame.loop();
}
