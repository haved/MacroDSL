const std = @import("std");

const ray = @import("raylib");
const Frame = @import("frame.zig").Frame;
const Buffer = @import("../text/buffer.zig").Buffer;
const colors = &@import("colors.zig").current_map;

const This = @This();

pub const Flags = packed struct {
    show_modeline: bool = true,
    // If true, you can not close the window or change its buffer
    permanent: bool = false,
};

frame: *Frame,
buffer: *Buffer,
flags: Flags,
x: i32 = 0,
y: i32 = 0,
width: i32 = 0,
height: i32 = 0,

/// Creates a Window containing the given buffer
/// The buffer is not owned by the window
pub fn init(frame: *Frame, buffer: *Buffer, flags: Flags) This {
    return This{ .frame = frame, .buffer = buffer, .flags = flags };
}

pub fn setBounds(this: *This, x: i32, y: i32, width: i32, height: i32) void {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
}

pub fn update(this: *This) void {
    _ = this;
}

pub fn render(this: *This) void {
    ray.DrawRectangle(this.x, this.y, this.width, this.height, colors.window_background);

    if (this.flags.show_modeline) {
        const modeline_height = 20;
        ray.DrawRectangle(this.x, this.y + this.height - modeline_height, this.width, modeline_height, colors.modeline_background);
        ray.DrawText("Window!", this.x + 4, this.y + this.height - 18, modeline_height - 4, colors.text_color);
    }
}

pub fn deinit(this: *This) void {
    _ = this;
    // We don't own the buffer
}
