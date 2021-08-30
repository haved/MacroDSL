
pub const Color = @import("raylib.zig").Color;

pub const ColorMap = struct {
    background: Color,
    split_bar: Color,
    window_background: Color
};

pub var current = ColorMap{
    .background = .{ .r = 33, .g = 36, .b = 43, .a = 255 },
    .split_bar = .{ .r = 29, .g = 32, .b = 38, .a = 255 },
    .window_background = .{ .r = 40, .g = 44, .b = 52, .a = 255 },
};
