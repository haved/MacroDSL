const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;

const ray = @import("raylib.zig");
const Buffer = @import("buffer.zig").Buffer;
const Window = @import("window.zig").Window;

/// We use emacs terminology, so a frame is what the operating system would call a window
pub const Frame = struct {
    const This = @This();

    alloc: *Allocator,
    buffers: ArrayList(*Buffer),
    layout: Layout,

    pub fn init(width: c_int, height: c_int, alloc: *Allocator) !This {
        ray.InitWindow(width, height, "MacroDSL");
        ray.SetTargetFPS(60);
        errdefer ray.CloseWindow();

        const buffers = ArrayList(*Buffer).init(alloc);
        errdefer buffers.deinit();

        return This{
            .alloc = alloc,
            .buffers = buffers,
            .layout = .{
                .content = .empty,
                .width = @intCast(u32, ray.GetScreenWidth()),
                .height = @intCast(u32, ray.GetScreenHeight())
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

    /// Loop until the users asks to close the frame
    pub fn loop(this: *This) void {
        while (!ray.WindowShouldClose()) {
            if (ray.IsWindowResized()) {
                this.layout.width = @intCast(u32, ray.GetScreenWidth());
                this.layout.heigth = @intCast(u32, ray.GetScreenHeight());
                this.layout.dirtySize = true;
            }

            ray.BeginDrawing();

            ray.ClearBackground(ray.RAYWHITE);
            layout.render(0, 0);
            ray.DrawFPS(10, 10);

            ray.EndDrawing();
        }
    }

    /// Clean up the frame and all it owns
    pub fn deinit(this: *This) void {
        this.layout.deinit(this.alloc);
        for(this.buffers.items) |buffer| {
            buffer.deinit();
            this.alloc.destroy(buffer);
        }
        this.buffers.deinit();
        ray.CloseWindow();
    }
};

pub const SplitDirection = enum {
    horizontal,
    vertical
};

/// The layout to be used for an area of a frame
pub const Layout = struct {
    const This = @This();
    pub const ContentType = union(enum) {
        window: Window,
        split: struct {
            layout1: *Layout,
            layout2: *Layout,
            splitPos: u32,
            splitDirection: SplitDirection
        },
        empty
    };

    content: ContentType,
    width: u32,
    height: u32,
    dirtySize: bool = true,

    pub fn render(this: *This, x: u32, y: u32) void {
        if (this.dirtySize) {
            switch(this.content) {
                .empty => {},
                .window => |window| window.setSize(this.width, this.height),
                .split => |split| {

                }
            }
            this.dirtySize = false;
        }

        switch(this.content) {
            .empty => {},
            .window => |window| {
                window.render(x, y, this.width, this.height);
            },
            .split => |split| {

            }
        }
    }

    /// Deinit the layout, and every sub-layout and window it owns
    /// alloc: The allocator used to destory the owned allocations
    pub fn deinit(this: *This, alloc: *Allocator) void {
        switch(this.content) {
            .window => |window| {
                window.deinit();
            },
            .split => |split| {
                split.layout1.deinit(alloc);
                split.layout2.deinit(alloc);
                alloc.destroy(split.layout1);
                alloc.destroy(split.layout2);
            },
            .empty => {}
        }
    }
};
