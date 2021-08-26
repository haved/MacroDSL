const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const ArrayList = std.ArrayList;

const ray = @import("raylib.zig");

const Buffer = @import("buffer.zig").Buffer;

/// We use emacs terminology, so a frame is what the operating system would call a window
pub const Frame = struct {
    const This = @This();

    alloc: *Allocator,
    buffers: ArrayList(*Buffer),

    pub fn init(width: c_int, height: c_int, alloc: *Allocator) !This {
        ray.InitWindow(width, height, "MacroDSL");
        ray.SetTargetFPS(60);

        const buffers = ArrayList(*Buffer).init(alloc);
        errdefer buffers.deinit();

        return This{
            .alloc = alloc,
            .buffers = buffers
        };
    }

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
        return if(mem.indexOfScalar(this.buffers.items)) true else false;
    }

    pub fn loop(this: *This) void {
        while (!ray.WindowShouldClose()) {
            ray.BeginDrawing();
            defer ray.EndDrawing();

            ray.ClearBackground(ray.RAYWHITE);
            ray.DrawText("Hello, World!", 190, 200, 20, ray.LIGHTGRAY);

            ray.DrawFPS(10, 10);
        }
    }

    pub fn deinit(this: *This) void {
        for(this.buffers.items) |buffer| {
            buffer.deinit();
            this.alloc.destroy(buffer);
        }
        this.buffers.deinit();
        ray.CloseWindow();
    }
};
