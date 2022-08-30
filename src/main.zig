const std = @import("std");
const Runtime = @import("Runtime.zig");
const Frame = @import("ui/Frame.zig");
const Layout = @import("ui/Layout.zig");
const Window = @import("ui/Window.zig");
const fonts = @import("ui/fonts.zig");

pub fn main() !void {
    var gpalloc = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!gpalloc.deinit());
    const alloc = gpalloc.allocator();

    // Create a runtime
    var runtime = try Runtime.init(alloc);
    defer runtime.deinit() catch unreachable;

    // Create a frame, attach it to the runtime
    var frame = try runtime.createFrame(1600, 900);
    defer runtime.destroyFrame() catch unreachable;

    try fonts.createInstance(alloc);
    defer fonts.destoryInstance();
    const default_font = try fonts.instance.?.loadFont("Source Code Pro", "res/SourceCodePro-Regular.otf", 24);
    defer default_font.deinit();

    // Give the frame the default layout
    frame.setLayout(try makeDefaultLayout(frame, alloc));

    // Show the interactive frame until it is closed
    frame.loop();
}

fn makeDefaultLayout(frame: *Frame, alloc: std.mem.Allocator) !Layout {
    var modeline_split = try makeModelineSplit(frame, alloc);
    errdefer modeline_split.deinit();
    return try Layout.initBorderLayout(modeline_split, 4, alloc);
}

fn makeMainSplit(frame: *Frame, alloc: std.mem.Allocator) !Layout {
    var main_window = try Window.init(frame, try frame.runtime.getDefaultBuffer(), .{});
    errdefer main_window.deinit();
    var macro_window = try Window.init(frame, try frame.runtime.getMacroBuffer(), .{});
    errdefer macro_window.deinit();
    return try Layout.initSplitLayout(
        Layout{ .content = .{ .window = main_window } },
        Layout{ .content = .{ .window = macro_window } },
        Layout.SplitDirection.vertical,
        8,
        true,
        100, // Each gets a minimum width of 100
        100,
        2, // Desire 2:1 ratio by default
        1,
        alloc,
    );
}

fn makeModelineSplit(frame: *Frame, alloc: std.mem.Allocator) !Layout {
    var main_split = try makeMainSplit(frame, alloc);
    errdefer main_split.deinit();
    var message_window = try Window.init(frame, try frame.runtime.getMessageBuffer(), .{
        .show_modeline = false,
        .permanent = true,
    });
    errdefer message_window.deinit();
    return try Layout.initSplitLayout(
        main_split,
        Layout{ .content = .{ .window = message_window }, .height = 32 },
        Layout.SplitDirection.horizontal,
        0,
        false,
        0,
        32, // Layout 2 min height
        1, // Desire 1:0 ratio, but with min height
        0,
        alloc,
    );
}
