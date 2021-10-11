const Allocator = @import("std").mem.Allocator;
const DefaultRopePlus = @import("ropeplus.zig").DefaultRopePlus;

pub const Buffer = struct {
    const This = @This();

    alloc: *Allocator,
    /// The name of this buffer, owned
    name: []u8,
    content: DefaultRopePlus,

    pub fn init(name: []const u8, alloc: *Allocator) !This {
        const name_copy = try alloc.dupe(u8, name);
        errdefer alloc.free(name_copy);

        const empty_content = try DefaultRopePlus.init(alloc);
        errdefer empty_content.deinit();

        return This{
            .alloc = alloc,
            .name = name_copy,
            .content = empty_content,
        };
    }

    pub fn deinit(this: *This) void {
        this.alloc.free(this.name);
        this.content.deinit();
    }
};
