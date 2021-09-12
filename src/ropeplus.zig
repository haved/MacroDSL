const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const assert = @import("assert.zig");

/// Number of bytes in one page of memory
const page_size = 4096;

/// A kind of mix between rope and B+ tree.
/// All nodes are node_size, located in in arenas.
/// When a new arena is needed, it is bigger than the previous.
/// Leaves contain bytes of the text buffer.
/// Internal nodes contain only pointers to nodes on the level below,
/// and how many text bytes are stored in that subtree.
/// Nodes also have pointers to neighbours on their level.
///
///          +-----+-------+----+-------+-------+
///          | 104 | 0x000 | 77 | 0x200 |(empty)
///          +-----+-------+----+-------+-------+
///                   /             \
///                  V               V
///     +----------------+--+     +---------------+----+
///     | 104 bytes text |    <-> | 77 bytes text |
///     +----------------+--+     +---------------+----+
///
pub fn RopePlus(comptime node_size:usize) type {
    return struct {
        const This = @This();
        const max_arena_count = 10;

        const Node = [node_size]u8;

        pub const InternalNode = struct {

        };

        pub const LeafNode = struct {

        };

        alloc: *Allocator,
        /// A stack of empty slots for nodes
        free_node_stack: ArrayList(*Node),
        arenas: [max_arena_count]?[*]Node,
        current_arena: u8,
        nodes_in_arena: usize,

        pub fn init(alloc: *Allocator) !This {
            return This{
                .alloc = alloc,
                .free_node_stack = ArrayList(*Node).init(alloc),
                .arenas = .{null} ** max_arena_count
            };
        }

        pub fn deinit(this: *This) void {
            this.clear();
            this.free_node_stack.deinit();
        }

        /// Empties the entire data structure
        pub fn clear(this: *This) void {
            this.free_node_stack.clearAndFree();
            for(this.arenas) |arena| {
                if(arena) |arena| {
                    this.alloc.free(arena);
                }
            }

            this.arenas = .{null} ** max_arena_count;
        }

        /// Gets the byte size of the requested arena
        fn get_arena_size(arena_index: u8) usize {
            assert.always(arena_index < max_arena_count);
            return page_size * (1<<arena_index);
        }
    };
}

pub const DefaultRopePlus = RopePlus(256);
