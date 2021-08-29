const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;

const ray = @import("raylib.zig");
const Buffer = @import("buffer.zig").Buffer;
const Window = @import("window.zig").Window;
const Layout = @import("layout.zig").Layout;

/// We use emacs terminology, so a frame is what the operating system would call a window
pub const Frame = struct {
    const This = @This();

    alloc: *Allocator,
    buffers: ArrayList(*Buffer),
    layout: Layout,

    pub fn init(width: c_int, height: c_int, alloc: *Allocator) !This {
        ray.InitWindow(width, height, "MacroDSL");
        ray.SetWindowState(ray.FLAG_WINDOW_RESIZABLE);
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

    /// Assigns new layout and deinits the old one
    /// Will resize the new layout to fit the frame
    /// The Frame will own the layout
    /// All allocated sub-layouts must come from the frame's allocator
    pub fn setLayout(this: *This, layout: Layout) void {
        const width = this.layout.width;
        const height = this.layout.height;
        this.layout.deinit();
        this.layout = layout;
        this.layout.resize(width, height);
    }

    /// Loop until the users asks to close the frame
    pub fn loop(this: *This) void {
        while (!ray.WindowShouldClose()) {
            if (ray.IsWindowResized()) {
                const width = ray.GetScreenWidth();
                const height = ray.GetScreenHeight();
                this.layout.resize(width, height);
            }

            ray.BeginDrawing();

            ray.ClearBackground(ray.RAYWHITE);
            this.layout.render(0, 0);
            ray.DrawFPS(10, 10);

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

