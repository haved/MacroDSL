const Allocator = @import("std").mem.Allocator;

pub const Buffer = struct {
    const This = @This();

    alloc: *Allocator,
    name: []u8,

    pub fn init(name: []const u8, alloc: *Allocator) !This {
        const name_copy = try alloc.dupe(u8, name);
        errdefer alloc.free(name_copy);

        return This{
            .alloc = alloc,
            .name = name_copy
        };
    }

    pub fn deinit(this: *This) void {
        this.alloc.free(this.name);
    }
};
