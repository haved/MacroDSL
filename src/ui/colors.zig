
pub const Color = @import("raylib").Color;

pub fn ofa(r: u8, g: u8, b: u8, a: u8) Color {
    return .{.r = r, .g = g, .b = b, .a = a};
}

pub fn of(r: u8, g: u8, b: u8) Color {
    return ofa(r, g, b, 255);
}

pub const ColorMap = struct {
    background: Color = of(33, 36, 43),

    window_background: Color = of(40, 44, 52),
    modeline_background: Color = of(25, 28, 34),

    split_bar: Color = of(29, 32, 38),
    split_bar_hover: Color = of(33, 36, 42),
    split_bar_pressed: Color = of(25, 28, 34),

    text_color: Color = of(200, 200, 200),
};

pub var current_map = ColorMap{};
