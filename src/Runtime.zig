//! This struct constains the state of the program.
//! It owns all open buffers, and has a two-way reference to the frame, if open.
//!
//! Thread safety:
//! This struct is in no way thread safe, so use locks if multithreading access.
//! Buffers have their own locks, so they live their own lives.
//! However, if deleting buffers, you must have exclusive access to /both/ the buffer and the runtime.

const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;

const Buffer = @import("text/Buffer.zig");
const Frame = @import("ui/Frame.zig");

const This = @This();

alloc: Allocator,
buffers: std.ArrayListUnmanaged(*Buffer) = .{},
default_buffer: ?*Buffer = null,
macro_buffer: ?*Buffer = null,
message_buffer: ?*Buffer = null,

/// The frame currently showing the runtime,
/// unless running in a headless mode
frame: ?Frame = null,

pub fn init(alloc: Allocator) !This {
    return This{ .alloc = alloc };
}

/// Closes the runtime and frees everything it owned.
/// Can not be done if the frame is still attached to it.
pub fn deinit(this: *This) !void {
    if (this.frame != null)
        return error.RuntimeHasOpenFrame;

    for (this.buffers.items) |buffer| {
        buffer.deinit();
        this.alloc.destroy(buffer);
    }
    this.buffers.deinit(this.alloc);
}

/// Creates a frame for this runtime. There can only be one.
/// Must be destroyed using destroyFrame().
/// The calling thread owns the OpenGL context
pub fn createFrame(this: *This, width: c_int, height: c_int) !*Frame {
    if (this.frame != null) return error.RuntimeHasFrame;

    this.frame = try Frame.init(this, width, height);
    return &this.frame.?;
}

/// Destroys the frame
pub fn destroyFrame(this: *This) !void {
    if (this.frame) |*frame| {
        frame.deinit();
        this.frame = null;
    } else return error.RuntimeHasNoFrame;
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

    // Notify the frame about the removal
    if (this.frame) |frame| {
        frame.onBufferDeleted(buffer);
    }
}
