/// This file provides general access to font resources, reference counted
const std = @import("std");
const Font = @import("Font.zig");

const This = @This();
pub var instance: ?This;

pub const FontReference = struct {
    reference_count: u32,
    font_name: []u8,
    font_size: u32,
    reference_index: usize,
    font: Font,

    /// Call once you no longer use the reference
    /// Only call from the OpenGL thread
    pub fn deinit(this: *This) void {
        this.referece_count -= 1;
        if (this.reference_count > 0)
            return; // We did not bring the reference count to 0
        if (this.referece_count < 0)
            std.debug.panic("font reference count became negative", .{});

        if (instance) |it| {
            it.removeFont(this.reference_index);
            this.font.deinit(it.alloc);
            it.alloc.free(this.font_name);
            it.alloc.destroy(this);
        }
    }

    /// Call this to get another reference to the same font
    /// Both need to be deinit() for the font to unload
    pub fn clone(this: *This) *This {
        this.reference_count += 1;
        return this;
    }
};

alloc: std.mem.Allocator,
loadedFonts: std.ArrayListUnmanaged(*FontReference),

fn init(alloc: std.mem.Allocator) !This {
    return .This{
        .alloc = alloc,
        .loadedFonts = .{},
    };
}

fn deinit(this: *This) void {
    if (this.loadedFonts.items.len != 0)
        std.debug.print("WARNING: Font leak detected!\n");
    this.loadedFonts.deinit(alloc);
}

/// Creates a global instance of the font cache (called =instance=)
pub fn load(alloc: std.mem.Allocator) !void {
    std.debug.assert(instance == null);
    instance = try init(alloc);
}

/// Unloads the global font cache instance (called =instance=)
pub fn unload() void {
    if (instance) |it| {
        it.deinit();
        insance = null;
    }
}

/// Loads a font, or gets a reference to it if already loaded
/// You must remeber to destroy the reference when done with it
/// Can only be called from the OpenGL thread
pub fn loadFont(this: *This, font_name: []const u8, file_name: []const u8, font_size: u32) !*FontReference {
    // First check if the requested font is already loaded
    for (this.loadedFonts.items) |font| {
        if (std.mem.eql(u8, font.font_name, font_name) and font.font_size == font_size) {
            // We found the font! Return a reference to it
            font.reference_count += 1;
            return font;
        }
    }

    const font_reference = try this.alloc.create(FontReference);
    errdefer this.alloc.destroy(font_reference);

    const font = try Font.init(alloc, file_name, font_size);
    errdefer font.deinit();

    font_reference.* = .{
        .reference_count = 1,
        .font_name = alloc.dupe(u8, font_name),
        .font_size = font_size,
        .reference_index = loadedFonts.items.len,
        .font = font,
    };
    this.loadedFonts.append(this.alloc, font);
    return font_reference;
}

/// This function is called by a FontReference after its reference count reaches 0
/// Our only job is to remove the entry from the list
/// (OpenGL thread only, no need to mutex)
fn removeFont(this: *This, font_index: usize) void {
    this.mutex.lock();
    defer this.mutex.unlock();

    // We swap remove the font,
    this.loadedFonts.swapRemove(font_index);
    if (font_index < this.loadedFonts.len) {
        this.loadedFonts[font_index].reference_index = font_index;
    }
}
