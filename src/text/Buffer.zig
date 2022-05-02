const Allocator = @import("std").mem.Allocator;
const RopePlus = @import("ropeplus.zig").RopePlus;

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
content: RopePlus,

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
