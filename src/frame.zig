const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;

const ray = @import("raylib.zig");
const Buffer = @import("buffer.zig").Buffer;
const Layout = @import("layout.zig").Layout;
const colors = &@import("colors.zig").current;
const Own = @import("mem.zig").Own;

/// We use emacs terminology, so a frame is what the operating system would call a window
pub const Frame = struct {
    const This = @This();

    alloc: *Allocator,
    buffers: ArrayList(Own(Buffer)),
    layout: Layout,

    pub fn init(width: c_int, height: c_int, alloc: *Allocator) !This {
        ray.InitWindow(width, height, "MacroDSL");
        ray.SetWindowState(ray.FLAG_WINDOW_RESIZABLE);
        ray.SetWindowMinSize(300, 200);
        ray.SetTargetFPS(60);
        errdefer ray.CloseWindow();

        const buffers = ArrayList(*Buffer).init(alloc);
        errdefer buffers.deinit();

        return This{
            .alloc = alloc,
            .buffers = buffers,
            .layout = .{
                .content = .empty,
                .width = ray.GetScreenWidth(),
                .height = ray.GetScreenHeight()
            }
        };
    }

    /// Creates a new buffer in the frame. The Frame owns the buffer
    pub fn createBuffer(this: *This, name: []const u8) !*Buffer {
        const buffer = try this.alloc.create(Buffer);
        errdefer this.alloc.destroy(buffer);

        buffer.* = try Buffer.init(name, this.alloc);
        errdefer buffer.deinit();

        try this.buffers.append(buffer);

        return buffer;
    }

    /// Checks that a buffer exists in and is owned by this frame
    /// If a buffer gets removed from its frame, all pointers to that buffer become invalid
    pub fn hasBuffer(this: *This, buffer: *Buffer) bool {
        return mem.indexOfScalar(this.buffers.items) != null;
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
            ray.DrawFPS(this.layout.width-100, 10);

            ray.EndDrawing();
        }
    }

    /// Clean up the frame and all it owns
    pub fn deinit(this: *This) void {
        this.layout.deinit();
        for (this.buffers.items) |buffer| {
            buffer.deinit();
            this.alloc.destroy(buffer);
        }
        this.buffers.deinit();
        ray.CloseWindow();
    }
};

