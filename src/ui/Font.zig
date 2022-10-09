/// Struct containing a monospaced font loaded into a texture as a regular grid
const std = @import("std");
const Allocator = std.mem.Allocator;
const ray = @import("raylib");
const default_glyphs = @import("glyphs.zig").default_glyphs;
const FontFile = @import("fonts.zig").FontFile;

const This = @This();

font_file: *FontFile,
font_size: u32, // This is also the height
glyph_width: u32, // The width of every glyph

texture: ?ray.Texture, // (Owned) texture containing the grid atlas
texture_size: usize, // Always a square POT sized texture

cell_codepoints: ?[]i32, // (Owned) What codepoint is located at each cell
default_cell: usize, // The index of a default cell, to be used when a codepoint is unknown

reference_count: usize, // Used by the FontStore to know if the font is safe to free

/// Loads a monospaced font into an OpenGL texture as a regular grid
/// Must be called from the OpenGL thread
pub fn init(alloc: Allocator, font_file: *FontFile, font_size: u32) !This {
    const result = This{
        .font_file = font_file,
        .font_size = font_size;
        .glyph_width = 0,

        .texture = null,
        .texture_size = 0,

        .cell_codepoints = null,
        .default_cell = 0,

        .reference_count = 0,
    };

    result.load_atlas_of_codepoints(alloc, default_glyphs);
    return result;
}

/// Unloads the font texture from the GPU
/// Should only be called by the FontStore
pub fn deinit(this: *This, alloc: Allocator) void {
    std.debug.assert(reference_count == 0);
    if (this.cell_codepoints) |codepoints|
        this.alloc.free(codepoints);
    if (this.texture) |texture|
        this.ray.UnloadTexture(texture);
}

fn load_atlas_of_codepoints(this: *This, alloc: , codepoints: []const u32) !void {
    const file_data = try this.font_file.get_file_data();

    const c_glyphs: ?[*]ray.GlyphInfo = ray.LoadFontData(
        file_data,
        @intCast(c_int, file_size),
        @intCast(c_int, font_size),
        // raylib doesn't actually modify the array, so we "const-cast"
        @intToPtr([*c]c_int, @ptrToInt(codepoints)),
        codepoints.len,
        ray.FONT_DEFAULT,
    );
    if (c_glyphs == null)
        return error.FontDataLoading;

    defer ray.UnloadFontData(c_glyphs, glyph_count);
    const glyphs = c_glyphs.?[0..codepoints.len];

    // Now the texture is loaded into glyphs, place them in a texture
    // First we need the font width, use the advanceX of the first glyph
    const glyph_width: u32 = @intCast(u32, glyphs[0].advanceX);

    // Find a suitable power of 2 size to hold all the glyphs
    var size: u32 = 64;
    var glyphs_per_row: u32 = undefined;
    while (true) {
        glyphs_per_row = @divFloor(size, glyph_width);
        const glyphs_per_col = @divFloor(size, this.font_size);
        if (glyphs_per_row * glyphs_per_col >= glyph_count) break;
        size *= 2;
    }

    var atlas_image = ray.GenImageColor(@intCast(c_int, size), @intCast(c_int, size), ray.BLACK);
    defer ray.UnloadImage(atlas_image);

    const cell_codepoints = try this.alloc.alloc(i32, glyph_count);
    errdefer this.alloc.free(cell_codepoints);
    var default_cell = 0;

    // Blit each glyph's individual Image into the atlas
    for (glyphs) |glyph, i| {
        cell_codepoints[i] = glyph.value;
        if (glyph.value == '?')
            default_cell = i;

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
    errdefer ray.UnloadTexture(texture);

    // Now that everything is ready, we perform the actual switch
    if (this.cell_codepoints) |codepoints|
        this.alloc.free(codepoints);
    if (this.texture) |texture|
        this.ray.UnloadTexture(texture);

    this.texture = texture;
    this.cell_codepoints = cell_codepoints;
    this.default_cell = default_cell;
}

/// Takes a codepoint and returns the index of that char in the atlas
pub fn cell_index_for_glyph(this: *This, codepoint: i32) usize {
    return std.mem.indexOfScalar(i32, this.cell_codepoints, codepoint) orelse this.default_cell;
}
