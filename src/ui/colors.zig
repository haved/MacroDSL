
pub const Color = @import("../raylib.zig").Color;

pub const ColorMap = struct {
    background: Color,

    window_background: Color,
    split_bar: Color,
    split_bar_hover: Color,
    split_bar_pressed: Color,

    text_color: Color
};

pub var current = ColorMap{
    .background = .{ .r = 33, .g = 36, .b = 43, .a = 255 },
    .window_background = .{ .r = 40, .g = 44, .b = 52, .a = 255 },

    .split_bar = .{ .r = 29, .g = 32, .b = 38, .a = 255 },
    .split_bar_hover = .{ .r = 33, .g = 36, .b = 42, .a = 255 },
    .split_bar_pressed = .{ .r = 25, .g = 28, .b = 34, .a = 255 },

    .text_color = .{ .r = 200, .g = 200, .b = 200, .a = 255 }
};
