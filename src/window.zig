const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;

const ray = @import("raylib.zig");
const Buffer = @import("buffer.zig").Buffer;

pub const Window = struct {
    const This = @This();

    alloc: *Allocator,
    buffer: *Buffer,

    pub fn init(alloc: *Allocator, buffer: *Buffer) !Window {
        return This{
            .alloc = alloc,
            .buffer = buffer
        };
    }

    pub fn setSize(this: *This, width: u32, height: u32) void {

    }

    pub fn render(this: *This, x:u32, y:u32, width: u32, height: u32) void {

    }
    
    pub fn deinit(this: *This) void {

    }
};
