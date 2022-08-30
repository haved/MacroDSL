/// This file provides general access to font resources, reference counted
/// Only access the fonts and font references from the OpenGL thread, no safety here
const std = @import("std");
const Font = @import("Font.zig");

const This = @This();
pub var instance: ?This = null;

pub const FontReference = struct {
    reference_count: u32,
    font_name: []u8,
    font_size: u32,
    reference_index: usize,
    font: Font,

    /// Call once you no longer use the reference
    /// Only call from the OpenGL thread
    pub fn deinit(this: *FontReference) void {
        this.reference_count -= 1;
        if (this.reference_count > 0)
            return; // We did not bring the reference count to 0

        // There should definitly be an instance, but if this font outlived the cache, don't crash
        if (instance) |*it| {
            it.removeFont(this.reference_index);
            this.font.deinit(it.alloc);
            it.alloc.free(this.font_name);
            it.alloc.destroy(this);
        }
    }

    /// Call this to get another reference to the same font
    /// Both need to be deinit() for the font to unload
    pub fn clone(this: *FontReference) *FontReference {
        this.reference_count += 1;
        return this;
    }
};

alloc: std.mem.Allocator,
loaded_fonts: std.ArrayListUnmanaged(*FontReference),

/// Creates a global instance of the font cache (called =instance=)
pub fn createInstance(alloc: std.mem.Allocator) !void {
    std.debug.assert(instance == null);
    instance = This{
        .alloc = alloc,
        .loaded_fonts = .{},
    };
}

/// Unloads the global font cache instance (called =instance=)
pub fn destoryInstance() void {
    if (instance) |*it| {
        // We should in theory not have any fonts left
        for (it.loaded_fonts.items) |font| {
            std.debug.print(
                "WARNING: Font leak detected: {s} size {}!\n",
                .{ font.font_name, font.font_size },
            );
        }
        it.loaded_fonts.deinit(it.alloc);
        instance = null;
    }
}

/// Loads a font, or gets a reference to it if already loaded.
/// If file_name is null, the function will return error if the font isn't already loaded.
/// You must remeber to destroy the reference when done with it.
/// Can only be called from the OpenGL thread.
pub fn loadFont(this: *This, font_name: []const u8, file_name: ?[:0]const u8, font_size: u32) !*FontReference {
    // First check if the requested font is already loaded
    for (this.loaded_fonts.items) |font| {
        if (std.mem.eql(u8, font.font_name, font_name) and font.font_size == font_size) {
            // We found the font! Return a reference to it
            return font.clone();
        }
    }

    // We didn't find the font with that name + size, try to load it
    // In which case file_name should not be null
    return try this.loadNewFont(font_name, file_name orelse return error.FileNotSpecified, font_size);
}

fn loadNewFont(this: *This, font_name: []const u8, file_name: [:0]const u8, font_size: u32) !*FontReference {
    const font_reference = try this.alloc.create(FontReference);
    errdefer this.alloc.destroy(font_reference);

    var font = try Font.init(this.alloc, file_name, font_size);
    errdefer font.deinit(this.alloc);

    font_reference.* = .{
        .reference_count = 1,
        .font_name = try this.alloc.dupe(u8, font_name),
        .font_size = font_size,
        .reference_index = this.loaded_fonts.items.len,
        .font = font,
    };
    try this.loaded_fonts.append(this.alloc, font_reference);
    return font_reference;
}

/// Gets a new reference to the default font
/// Errors if no deafult font is loaded
pub fn getDefaultFont(this: *This) !*FontReference {
    // For now just return the first font loaded
    if (this.loaded_fonts.items.len == 0)
        return error.NoDefaultFont;
    return this.loaded_fonts.items[0].clone();
}

/// This function is called by a FontReference after its reference count reaches 0
/// Our only job is to remove the entry from the list
/// (OpenGL thread only, no need to mutex)
fn removeFont(this: *This, font_index: usize) void {
    // We swap remove the font,
    _ = this.loaded_fonts.swapRemove(font_index);
    if (font_index < this.loaded_fonts.items.len) {
        // Inform the FontReference it now lives at this index
        this.loaded_fonts.items[font_index].reference_index = font_index;
    }
}
