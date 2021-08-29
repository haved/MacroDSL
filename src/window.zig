const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;

const ray = @import("raylib.zig");
const Buffer = @import("buffer.zig").Buffer;

pub const Window = struct {
    const This = @This();

    alloc: *Allocator,
    buffer: *Buffer,

    /// Creates a Window containing the given buffer
    /// The buffer is not owned by the window
    pub fn init(alloc: *Allocator, buffer: *Buffer) !Window {
        return This{
            .alloc = alloc,
            .buffer = buffer
        };
    }

    pub fn setSize(this: *This, width: i32, height: i32) void {

    }

    pub fn render(this: *This, x:i32, y:i32, width: i32, height: i32) void {
        ray.DrawRectangle(x, y, width, height, ray.RAYWHITE);
    }
    
    pub fn deinit(this: *This) void {

    }
};
