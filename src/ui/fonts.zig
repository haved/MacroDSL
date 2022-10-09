const std = @import("std");
const ArrayListUnmanaged = std.ArrayListUnmanaged;
const Allocator = std.mem.Allocator;

const ray = @import("raylib");
const Font = @import("Font.zig");

// Represents one font file, containing one named font
// The font name and path are owned by this struct, on the font store's allocator.
// The font file is loaded the first time it's needed, and is owned by this struct
const FontFile = struct {
    const This = @This();

    font_name: [:0]const u8,
    file_path: [:0]const u8,
    file_data: ?[]const u8 = null,

    pub fn init(alloc: Allocator, font_name: [:0]u8, file_path: [:0]u8) !This {
        const font_name = try alloc.dupeZ(font_name);
        errdefer alloc.free(font_name);
        const file_path = try alloc.dupeZ(file_path);
        errdefer alloc.free(file_path);
        return .This {
            .font_name = font_name,
            .file_path = file_path,
        };
    }

    pub fn get_file_data(this: *This) ![]u8 {
        if (this.file_data) |data|
            return data;
        var file_size: c_uint = 0;
        const file_data: ?[*]u8 = ray.LoadFileData(this.file_path, &file_size);
        if (file_data == null)
            return error.FileNotFound;

        this.file_data = file_data[0..file_size];
        return this.file_data.?;
    }

    pub fn deinit(this: *This, alloc: Allocator) void {
        alloc.free(font_name);
        alloc.free(file_name);
        if (this.file_data) |file_data|
            ray.UnloadFileData(file_data);
    }
};

// The global font store.
// A font file represents a named file containing a font.
// A font represents rasterizing a font at a specific size.
// What chars are rasterized can change depending on requested values
const FontStore = struct {
    const This = @This();

    alloc: Allocator,

    // Font files known about, with the first being the default
    font_files: ArrayListUnmanaged(FontFile),
    loaded_fonts: ArrayListUnmanaged(*Font),
    // The default font size
    default_size: u32,

    fn init(alloc: Allocator, default_font: FontFile, default_size: u32) !This {
        const font_files = .{};
        const loaded_fonts = .{};
        try font_files.append(alloc, default_font);

        return .This{
            .alloc = alloc,
            .font_files = font_files,
            .loaded_fonts = loaded_fonts,
        };
    }

    fn deinit(this: *This) void {
        for (this.font_files.items) |*file| {
            file.deinit();
        }

        for (this.loaded_fonts.items) |font| {
            font.deinit(this.alloc);
            alloc.delete(font);
        }

        this.font_files.deinit(this.alloc);
        this.loaded_fonts.deinit(this.alloc);
    }

    pub fn get_default_font_file(this: *This) *FontFile {
        std.debug.assert(this.font_files.items.len > 0);
        return &this.font_files.items[0];
    }

    pub fn load_font(this: *This, font_file: *FontFile, font_size: u32) !*Font {
        // First check if we already have this font loaded
        for (this.loaded_fonts.items) |font| {
            if (font.font_file == font_file and font.font_size == font_size) {
                font.reference_count += 1;
                return font;
            }
        }

        // load the font
        const font = try this.alloc.create(Font);
        errdefer this.alloc.destroy(font);
        try font.init(this.alloc, font_file, font_size);
        errdefer font.deinit(this.alloc);

        try this.loaded_fonts.append(this.alloc, font);
        font.reference_count += 1;
        return font;
    }
};

var instance: ?FontStore;
