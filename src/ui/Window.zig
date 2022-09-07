const std = @import("std");

const ray = @import("raylib");
const rlgl = @import("rlgl");
const draw = @import("draw.zig");
const Frame = @import("Frame.zig");
const Buffer = @import("../text/Buffer.zig");
const colors = &@import("colors.zig").current_map;
const shaders = @import("shaders.zig");
const Font = @import("Font.zig");
const fonts = @import("fonts.zig");
const FontReference = fonts.FontReference;

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

textmap: ray.Texture,

font: ?*FontReference,

/// Creates a Window containing the given buffer
/// The buffer is not owned by the window
pub fn init(frame: *Frame, buffer: *Buffer, flags: Flags) !This {
    const font = try fonts.instance.?.getDefaultFont();
    errdefer font.deinit();
    const textmap = ray.LoadTexture("res/test.png");
    errdefer ray.UnloadTexture(textmap);

    return This{
        .frame = frame,
        .buffer = buffer,
        .flags = flags,
        .textmap = textmap,
        .font = font,
    };
}

pub fn deinit(this: *This) void {
    // We don't own the buffer or frame
    if (this.font) |it| {
        it.deinit();
    }
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

    var grid_height = this.height;
    if (this.flags.show_modeline) {
        const modeline_height = 20;
        grid_height -= modeline_height;
        ray.DrawRectangle(this.x, this.y + this.height - modeline_height, this.width, modeline_height, colors.modeline_background);
        ray.DrawText("Window!", this.x + 4, this.y + this.height - 18, modeline_height - 4, colors.text_color);
    }

    // Draw text contents
    if (this.font) |font| {
        shaders.textGrid.bind();
        shaders.textGrid.setIVec2("cellSize", .{
            @intCast(i32, font.font.glyph_width),
            @intCast(i32, font.font.base_size),
        });
        shaders.textGrid.setTexture("fontAtlas", font.font.texture);
        draw.texturePart(this.x, this.y, this.width, grid_height, this.textmap, ray.WHITE);
        shaders.textGrid.unbind();
    }
}
