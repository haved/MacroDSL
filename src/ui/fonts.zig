/// This file provides general access to font resources, reference counted
const std = @import("std");
const Font = @import("Font.zig");
const Atomic = std.atomic.Atomic;
const Mutex = std.Thread.Mutex;

const This = @This();
pub var instance: ?This;

pub const FontReference = struct {
    reference_count: Atomic(u32),
    font_name: []u8,
    font_size: u32,
    reference_index: usize,
    font: Font,

    pub fn deinit(this: *This) void {
        if (reference_count.fetchSub(1, .Monotonic) != 1)
            return; // We did not bring the reference count to 0
        if (instance) |it| {
            it.removeFont(this.reference_index);
            font.deinit(it.alloc);
            it.alloc.free(this.font_name);
            it.alloc.destroy(this);
        }
    }
};

alloc: std.mem.Allocator,
loadedFonts: std.ArrayListUnmanaged(*FontReference),
mutex: Mutex,

fn init(alloc: std.mem.Allocator) !This {
    return .This{
        .alloc = alloc,
        .loadedFonts = .{},
        .mutex = .{},
    };
}

fn deinit(this: *This) void {
    this.mutex.lock();
    defer this.mutex.unlock();

    if (this.loadedFonts.items.len != 0)
        std.debug.print("WARNING: Font leak detected!\n");
    this.loadedFonts.deinit(alloc);
}

pub fn load(alloc: std.mem.Allocator) !void {
    std.debug.assert(instance == null);
    instance = try init(alloc);
}

pub fn unload() void {
    if (instance) |it| {
        it.deinit();
        insance = null;
    }
}

pub fn loadFont(this: *This, font_name: []const u8, file_name: []const u8, font_size: u32) !*FontReference {
    this.mutex.lock();
    defer this.mutex.unlock();

    // First check if the requested font is already loaded
    for (this.loadedFonts.items) |font| {
        if (std.mem.eql(u8, font.font_name, font_name) and font.font_size == font_size) {
            // We want a reference to this font, increase its reference count to keep it alive
            if (font.reference_count.fetchAdd(1, .Monotonic) == 0) //TODO
                break; // Darn, the other owner of this font just decreased the reference count to 0
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
    return &font_reference;
}

/// This function is called by a FontReference after its reference count reaches 0
/// Our only job is to remove the entry from the list
fn removeFont(this: *This, font_index: usize) void {
    this.mutex.lock();
    defer this.mutex.unlock();

    // We swap remove the font,
    this.loadedFonts.swapRemove(font_index);
    if (font_index < this.loadedFonts.len) {
        this.loadedFonts[font_index].reference_index = font_index;
    }
}
