//! We use emacs terminology, so a frame is what the operating system would call a window.
//! The thread that creates the frame must be the same used to drive the main loop
//!

const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;
const ray = @import("raylib");

const Layout = @import("Layout.zig");
const colors = &@import("colors.zig").current_map;
const Runtime = @import("../Runtime.zig");
const Buffer = @import("../text/Buffer.zig");

const This = @This();

/// Our owner, we use its allocator
runtime: *Runtime,
layout: Layout,

/// Init function, should only be called from Runtime.createFrame()
pub fn init(runtime: *Runtime, width: c_int, height: c_int) !This {
    ray.InitWindow(width, height, "MacroDSL");
    ray.SetWindowState(ray.FLAG_WINDOW_RESIZABLE);
    ray.SetWindowMinSize(300, 200);
    ray.SetTargetFPS(60);
    errdefer ray.CloseWindow();

    return This{
        .runtime = runtime,
        .layout = .{
            .content = .empty,
            .width = ray.GetScreenWidth(),
            .height = ray.GetScreenHeight(),
        },
    };
}

/// Clean up the frame and all it owns.
/// Should only be called from Runtime.destroyFrame().
pub fn deinit(this: *This) void {
    this.layout.deinit();
    ray.CloseWindow();
}

/// Replace the current layout with a new one
/// Will set the bounds to fill the frame
pub fn setLayout(this: *This, layout: Layout) void {
    var new_layout = layout;
    new_layout.setBounds(0, 0, this.layout.width, this.layout.height);
    this.layout.deinit();
    this.layout = new_layout;
}

/// Loop until the users asks to close the frame
pub fn loop(this: *This) void {
    while (!ray.WindowShouldClose()) {
        if (ray.IsWindowResized()) {
            const width = ray.GetScreenWidth();
            const height = ray.GetScreenHeight();
            this.layout.setBounds(0, 0, width, height);
        }

        this.layout.update();

        ray.BeginDrawing();

        ray.ClearBackground(colors.background);
        this.layout.render();
        ray.DrawFPS(this.layout.width - 100, 10);

        ray.EndDrawing();
    }
}

pub fn onBufferDeleted(this: *This, buffer: *Buffer) void {
    this.layout.onBufferDeleted(buffer);
}
