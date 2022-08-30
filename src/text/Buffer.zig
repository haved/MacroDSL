const Allocator = @import("std").mem.Allocator;
//const RopePlus = @import("ropeplus.zig").RopePlus;

const This = @This();

pub const Flags = packed struct {
    listable: bool = true,
    deletable: bool = true,
    readonly: bool = false,
};

alloc: Allocator,
/// The name of this buffer, owned
name: []u8,
flags: Flags,
//content: RopePlus,

/// Bytes outside of the [0,127] range can represent any unicode codepoint
/// This lets us pretend to support different languages, but up to 128 additional codepoints
codepage: [128]i32 = [_]i32{0} ** 128,

pub fn init(alloc: Allocator, name: []const u8, flags: Flags) !This {
    const name_copy = try alloc.dupe(u8, name);
    errdefer alloc.free(name_copy);

    return This{
        .alloc = alloc,
        .name = name_copy,
        .flags = flags,
    };
}

pub fn deinit(this: *This) void {
    this.alloc.free(this.name);
    //this.content.deinit();
}

/// Empties the codepoints of this buffer into the given i32 buffer
/// Returns the amount of codepoints dumped, up to the length of buffer
pub fn dump_codepoints(this: *This, buffer: []i32) usize {
    const dummy_text: []u8 = "Woah this is actually very cool!";
    for (dummy_text) |text_byte, i| {
        if (i >= buffer.len)
            return buffer.len; // We have filled the buffer

        if (text_byte < 128)
            buffer[i] = text_byte
        else
            buffer[i] = this.codepage[text_byte - 128];
    }

    // We only filled the buffer up to dummy_text
    return dummy_text.len;
}
