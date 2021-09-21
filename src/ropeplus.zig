const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const assert = @import("assert.zig");

/// Number of bytes in one page of memory
const page_size = 4096;

/// A sensible node size for a RopePlus
pub const DefaultRopePlus = RopePlus(256);

/// A kind of mix between rope and B+ tree.
/// All nodes are node_size, located in in arenas, and aligned to node_size
/// Leaves contain bytes of the text buffer.
/// Internal nodes contain only pointers to nodes on the level below,
/// and how many text bytes are stored in that subtree.
/// Nodes also have pointers to parents and neighbours on their level.
///
///          +-----+-------+----+-------+-------+
///          | 104 | 0x000 | 77 | 0x200 |(empty)
///          +-----+-------+----+-------+-------+
///                    ^           ^
///                   /             \
///                  V               V
///     +----------------+--+     +---------------+----+
///     | 104 bytes text |    <-> | 77 bytes text |
///     +----------------+--+     +---------------+----+
///
pub fn RopePlus(comptime node_size:usize) type {
    return struct {
        const This = @This();
        const max_arena_count: u8 = 10;

        const Node = [node_size] u8;
        /// The type used to store length of node content (including sub-nodes)
        const NodeContentSize = u32;

        pub const InternalNode = struct {
            pub const DownPointer = struct {
                child: ?*Node,
                child_content_size: NodeContentSize
            };

            left_node: ?*Node,
            right_node: ?*Node,
        };

        pub const LeafNode = struct {
            left_node: ?*Node,
            right_node: ?*Node,
            parent_reverse_edge: ?*InternalNode.DownPointer,
            content_size: NodeContentSize,
            content: [max_content_size]u8,

            const max_content_size = node_size
                - @sizeOf(?*Node)*2
                - @sizeOf(?*InternalNode.DownPointer)
                - @sizeOf(NodeContentSize);
        };

        comptime {
            if(@sizeOf(InternalNode) > @sizeOf(Node)) @panic("InternalNode is the wrong size!");
            if(@sizeOf(LeafNode) != @sizeOf(Node)) @panic("LeafNode is the wrong size!");
        }

        node_allocator: NodeAllocator(Node),
        root_node: *Node,
        /// All leaf nodes are on level 0
        root_node_level: u8,

        pub fn init(alloc: *Allocator) !This {
            var node_allocator = try NodeAllocator(Node).init(alloc);
            errdefer node_allocator.deinit();

            const root_node = try node_allocator.allocateNode();

            return This{
                .node_allocator = node_allocator,
                .root_node = root_node,
                .root_node_level = 0
            };
        }

        pub fn deinit(this: *This) void {
            this.node_allocator.deinit();
        }
    };
}

/// Allocates larger and larger arenas for nodes
/// All nodes are aligned with their size
/// Freed nodes are stored in a side stack
/// Nodes need not be freed before deinit()
fn NodeAllocator(comptime Node: type) type {
    const node_size = @sizeOf(Node);

    comptime if (node_size % page_size != 0 and page_size % node_size != 0)
        @panic("Nodes and pages don't align");
    const smallest_arena_node_count: usize = if (page_size > node_size) page_size / node_size else 1;

    return struct {
        const This = @This();
        const max_arena_count = 10;

        alloc: *Allocator,
        /// A stack of empty slots for nodes
        free_node_stack: ArrayList(*Node),
        arenas: [max_arena_count]?[]Node,
        current_arena: u8,
        next_in_arena: usize,

        pub fn init(alloc: *Allocator) !This {
            return This{
                .alloc = alloc,
                .free_node_stack = ArrayList(*Node).init(alloc),
                .arenas = .{null} ** max_arena_count,
                .current_arena = 0,
                .next_in_arena = 0
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
                if(arena) |arena_| {
                    this.alloc.free(arena_);
                }
            }
            this.arenas = .{null} ** max_arena_count;
            this.current_arena = 0;
            this.next_in_arena = 0;
        }

        /// Allocates one Node
        pub fn allocateNode(this: *This) !*Node {
            if (this.free_node_stack.items.len > 0)
                return this.free_node_stack.pop();

            while (true) {
                if (this.arenas[this.current_arena]) |current_arena| {
                    if (this.next_in_arena <= current_arena.len) {
                        const result = &current_arena[this.next_in_arena];
                        this.next_in_arena += 1;
                        return result;
                    }

                    this.current_arena += 1;
                    this.next_in_arena = 0;
                    if (this.current_arena >= max_arena_count)
                        @panic("NodeAllocator was never designed to allocate this much");
                }

                // Allocate the new arena, with correct alignment
                this.arenas[this.current_arena] =
                    try this.alloc.allocWithOptions(
                        Node, get_arena_node_count(this.current_arena), node_size, null);
            }
        }

        /// Frees one Node. Does not actually give up any memory
        pub fn freeNode(this: *This, node: *Node) !void {
            try this.free_node_stack.append(node);
        }

        /// Gets the node count of the requested arena
        fn get_arena_node_count(arena_index: u8) usize {
            if (arena_index >= max_arena_count) unreachable;
            return smallest_arena_node_count * (@intCast(usize, 1) << @intCast(u6,arena_index));
        }
    };
}
