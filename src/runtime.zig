const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;

const Buffer = @import("text/buffer.zig").Buffer;
const Frame = @import("ui/frame.zig").Frame;

const This = @This();

alloc: Allocator,
buffers: std.ArrayList(*Buffer),
default_buffer: ?*Buffer = null,
macro_buffer: ?*Buffer = null,
message_buffer: ?*Buffer = null,
// Gets informed about state changes
frame: ?*Frame = null,

pub fn init(alloc: Allocator) !This {
    const buffers = std.ArrayList(*Buffer).init(alloc);
    return This{ .alloc = alloc, .buffers = buffers };
}

pub fn getDefaultBuffer(this: *This) !*Buffer {
    if (this.default_buffer) |it| return it;
    this.default_buffer = try this.createBuffer("**default**", .{});
    return this.default_buffer.?;
}

pub fn getMacroBuffer(this: *This) !*Buffer {
    if (this.macro_buffer) |it| return it;
    this.macro_buffer = try this.createBuffer("**macro**", .{ .deletable = false });
    return this.macro_buffer.?;
}

pub fn getMessageBuffer(this: *This) !*Buffer {
    if (this.message_buffer) |it| return it;
    this.message_buffer = try this.createBuffer("**message**", .{ .deletable = false });
    return this.message_buffer.?;
}

/// Creates a new buffer.
/// The runtime owns the buffer. use destoryBuffer to delete, or let runtime deinit
pub fn createBuffer(this: *This, name: []const u8, flags: Buffer.Flags) !*Buffer {
    const buffer = try this.alloc.create(Buffer);
    errdefer this.alloc.destroy(buffer);

    buffer.* = try Buffer.init(this.alloc, name, flags);
    errdefer buffer.deinit();

    try this.buffers.append(buffer);

    return buffer;
}

/// Checks that a buffer exists in and is owned by this frame
/// If a buffer gets removed from the runtime, all pointers to that buffer become invalid
pub fn hasBuffer(this: *This, buffer: *Buffer) bool {
    return mem.indexOfScalar(*Buffer, this.buffers.items, buffer) != null;
}

pub const BufferDestroyError = error{
    NotABuffer,
    ProtectedBuffer,
};

/// Destorys a buffer, and also gives notice to the frame about the buffer no longer existing
/// You may not destroy the default, macro or message buffers
pub fn destroyBuffer(this: *This, buffer: *Buffer) BufferDestroyError!void {
    if (!buffer.flags.deletable)
        return BufferDestroyError.ProtectedBuffer;

    const maybe_index = mem.indexOfScalar(*Buffer, this.buffers.items, buffer);
    const index = maybe_index orelse BufferDestroyError.NotABuffer;

    this.buffers.swapRemove(index);
    if (this.frame) |frame|
        frame.onBufferDeleted(buffer);
}

pub fn deinit(this: *This) void {
    for (this.buffers.items) |buffer| {
        buffer.deinit();
        this.alloc.destroy(buffer);
    }
    this.buffers.deinit();
}
