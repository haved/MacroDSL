const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;

const Buffer = @import("text/buffer.zig").Buffer;
const Frame = @import("ui/frame.zig").Frame;

const This = @This();

alloc: Allocator,
buffers: std.ArrayListUnmanaged(*Buffer) = .{},
default_buffer: ?*Buffer = null,
macro_buffer: ?*Buffer = null,
message_buffer: ?*Buffer = null,

// We don't own the frames, we just notify them about removed buffers
frames: std.ArrayListUnmanaged(*Frame) = .{},

pub fn init(alloc: Allocator) !This {
    return This{ .alloc = alloc };
}

/// Subscribes the frame to runtime events.
/// Also prevents the runtime from being closed until all frames are removed.
pub fn addListeningFrame(this: *This, frame: *Frame) !void {
    try this.frames.append(this.alloc, frame);
}

/// Removes the given frame from the list of listening frames.
/// Errors if the frame given doesn't exist as a listener.
pub fn removeListeningFrame(this: *This, frame: *Frame) !void {
    const maybe_index = mem.indexOfScalar(*Frame, this.frames.items, frame);
    const index = maybe_index orelse return error.NotFound;
    _ = this.frames.swapRemove(index);
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

    try this.buffers.append(this.alloc, buffer);

    return buffer;
}

/// Checks that a buffer exists in and is owned by this frame
/// If a buffer gets removed from the runtime, all pointers to that buffer become invalid
pub fn hasBuffer(this: *This, buffer: *Buffer) bool {
    return mem.indexOfScalar(*Buffer, this.buffers.items, buffer) != null;
}

pub const BufferDestroyError = error{
    NotFound,
    ProtectedBuffer,
};

/// Marks a buffer for deletion, will be deleted at next cleanup
/// Some buffers are not possible to delete
pub fn destroyBuffer(this: *This, buffer: *Buffer) BufferDestroyError!void {
    if (!buffer.flags.deletable)
        return BufferDestroyError.ProtectedBuffer;

    // Check that buffer is actually ours
    const maybe_index = mem.indexOfScalar(*Buffer, this.buffers.items, buffer);
    const index = maybe_index orelse return BufferDestroyError.NotABuffer;

    // Remove the buffer from the list and memory
    this.buffers.swapRemove(index);
    this.alloc.delete(buffer);

    // Notify all frames about the removal
    for (this.frames.items) |frame| {
        frame.onBufferDeleted(buffer);
    }
}

/// Closes the runtime and frees everything it owned.
/// Can not be done if any frames are still attached to it.
pub fn deinit(this: *This) !void {
    if (this.frames.items.len != 0)
        return error.RuntimeHasOpenFrames;

    for (this.buffers.items) |buffer| {
        buffer.deinit();
        this.alloc.destroy(buffer);
    }
    this.buffers.deinit(this.alloc);
    this.frames.deinit(this.alloc);
}
