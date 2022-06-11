/// Struct containing a monospaced font loaded into a texture as a regular grid
const std = @import("std");
const ray = @import("raylib");

const This = @This();

base_size: u32, // This is also the height
glyph_width: u32, // The width of every glyph

texture: ray.Texture, // (Owned) texture containing the grid atlas
texture_size: usize, // Always a square POT sized texture
glyphs_per_row: u32, // equal to texture_size / glyph_width

cell_codepoints: []i32, // (Owned) What codepoint is located at each cell
default_cell: usize, // The index of a default cell, to be used when a codepoint is unknown

/// Loads a monospaced font into an OpenGL texture as a regular grid
/// Must be called from the OpenGL thread
pub fn init(alloc: std.mem.Allocator, file_name: [:0]const u8, font_size: u32) !This {
    var file_size: c_uint = 0;
    const file_data: ?[*]u8 = ray.LoadFileData(file_name, &file_size);
    if (file_data == null) // Raylib already warns about missing file
        return error.FileNotFound;
    defer ray.UnloadFileData(file_data);

    const font_chars: ?[*]c_int = null; // The raylib default char set is 32..126
    const glyph_count = 95;

    const c_glyphs: ?[*]ray.GlyphInfo = ray.LoadFontData(
        file_data,
        @intCast(c_int, file_size),
        @intCast(c_int, font_size),
        font_chars,
        glyph_count,
        ray.FONT_DEFAULT,
    );
    if (c_glyphs == null)
        return error.FontDataLoading;
    defer ray.UnloadFontData(c_glyphs, glyph_count);
    const glyphs = c_glyphs.?[0..glyph_count];

    // Now the texture is loaded into glyphs, place them in a texture
    // First we need the font width, use the advanceX of the first glyph
    const glyph_width: u32 = @intCast(u32, glyphs[0].advanceX);

    // Find a suitable power of 2 to hold all the glyphs
    var size: u32 = 64;
    var glyphs_per_row: u32 = undefined;
    while (true) {
        glyphs_per_row = @divFloor(size, glyph_width);
        const glyphs_per_col = @divFloor(size, font_size);
        if (glyphs_per_row * glyphs_per_col >= glyph_count) break;
        size *= 2;
    }

    var atlas_image = ray.GenImageColor(@intCast(c_int, size), @intCast(c_int, size), ray.BLACK);
    defer ray.UnloadImage(atlas_image);

    const cell_codepoints = try alloc.alloc(i32, glyph_count);

    for (glyphs) |glyph, i| {
        cell_codepoints[i] = glyph.value;
        if (glyph.advanceX != glyph_width)
            return error.FontNotMonospaced;

        const row = @mod(i, glyphs_per_row);
        const col = i / glyphs_per_row;

        const source_rect = ray.Rectangle{
            .x = 0,
            .y = 0,
            .width = @intToFloat(f32, glyph.image.width),
            .height = @intToFloat(f32, glyph.image.height),
        };
        var dest_rect = source_rect;
        dest_rect.x = @intToFloat(f32, @intCast(i32, row * glyph_width) + glyph.offsetX);
        dest_rect.y = @intToFloat(f32, @intCast(i32, col * font_size) + glyph.offsetY);
        ray.ImageDraw(&atlas_image, glyph.image, source_rect, dest_rect, ray.WHITE);
    }

    const texture = ray.LoadTextureFromImage(atlas_image);

    return This{
        .base_size = font_size,
        .glyph_width = glyph_width,
        .texture = texture,
        .texture_size = size,
        .glyphs_per_row = glyphs_per_row,

        .cell_codepoints = cell_codepoints,
        .default_cell = 0,
    };
}

/// Unloads the font texture from the GPU
/// Must be called from the OpenGL thread
pub fn deinit(this: *This, alloc: std.mem.Allocator) void {
    alloc.free(this.cell_codepoints);
    ray.UnloadTexture(this.texture);
}
