const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;

const ray = @import("raylib.zig");
const Buffer = @import("buffer.zig").Buffer;
const colors = &@import("colors.zig").current;

pub const Window = struct {
    const This = @This();

    alloc: *Allocator,
    buffer: *Buffer,
    x: i32 = 0,
    y: i32 = 0,
    width: i32 = 0,
    height: i32 = 0,

    /// Creates a Window containing the given buffer
    /// The buffer is not owned by the window
    pub fn init(alloc: *Allocator, buffer: *Buffer) !Window {
        return This{
            .alloc = alloc,
            .buffer = buffer
        };
    }

    pub fn setBounds(this: *This, x: i32, y: i32, width: i32, height: i32) void {
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
    }

    pub fn update(this: *This) void {

    }

    pub fn render(this: *This) void {
        ray.DrawRectangle(this.x, this.y, this.width, this.height, colors.window_background);
        ray.DrawText("This is a window!", this.x, this.y, 20, colors.text_color);
    }
    
    pub fn deinit(this: *This) void {

    }
};
