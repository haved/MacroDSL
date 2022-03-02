const std = @import("std");
const Runtime = @import("runtime.zig");
const Frame = @import("ui/frame.zig").Frame;
const Layout = @import("ui/layout.zig").Layout;
const Window = @import("ui/window.zig").Window;

pub fn main() !void {
    var gpalloc = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!gpalloc.deinit());
    const alloc = gpalloc.allocator();

    var runtime = try Runtime.init(alloc);
    defer runtime.deinit();
    var frame = try Frame.init(alloc, &runtime, 1600, 900);
    defer frame.deinit();

    runtime.frame = &frame;
    defer runtime.frame = null;

    frame.setLayout(try makeDefaultLayout(&frame, alloc));
    frame.loop();
}

fn makeDefaultLayout(frame: *Frame, alloc: std.mem.Allocator) !Layout {
    const main_window = Window.init(alloc, try frame.runtime.getDefaultBuffer(), .{});
    const macro_window = Window.init(alloc, try frame.runtime.getMacroBuffer(), .{});
    const message_window = Window.init(alloc, try frame.runtime.getMessageBuffer(), .{
        .show_modeline = false,
        .permanent = true,
    });
    var modeline_split = modeline_split: {
        var main_split = try Layout.initSplitLayout(
            Layout{ .content = .{ .window = main_window } },
            Layout{ .content = .{ .window = macro_window } },
            Layout.SplitDirection.vertical,
            8,
            true,
            100,
            100,
            200,
            100,
            alloc,
        );
        errdefer main_split.deinit();
        break :modeline_split try Layout.initSplitLayout(
            main_split,
            Layout{ .content = .{ .window = message_window }, .height = 32 },
            Layout.SplitDirection.horizontal,
            0,
            false,
            0,
            32,
            1,
            0,
            alloc,
        );
    };
    errdefer modeline_split.deinit();
    return try Layout.initBorderLayout(modeline_split, 4, alloc);
}
