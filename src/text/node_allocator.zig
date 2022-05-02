//! An allocator for allocating nodes of equal size.
//! Works by preallocating a continous chunk of virtual memory.

const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const mmap = @import("mmap.zig");

/// Allocator for allocating lots of objects of the same size.
/// You do not need to free the values allocated here, like an arena.
pub fn NodeAllocator(T: type, maxCount: u32) type {
    return struct {
        const This = @This();

        alloc: Allocator,
        /// Any nodes that get freed are pushed to this list
        free_node_stack: ArrayList(*Node),
        /// The
        next_fresh_node: usize,

        pub fn init(alloc: Allocator) This {
            return This{
                .alloc = alloc,
                .free_node_stack = ArrayList(*Node).init(alloc),
            };
        }

        pub fn deinit(this: *This) void {
            this.free_node_stack.deinit();
        }

        /// Places the node in the freelist, which lets it be reused.
        /// It is not a requirement, since all nodes get freed when the allocator is deinit.
        /// If the memory allocation of the freelist fails, we just don't care
        pub fn freeNode(this: *This, node: *Node) void {
            this.free_node_stack.append(node) catch {};
        }
    };
}
