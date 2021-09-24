const std = @import("std");
const Allocator = std.mem.Allocator;
const NodeAllocator = @import("NodeAllocator.zig").NodeAllocator;

/// A sensible node size for a RopePlus
pub const DefaultRopePlus = RopePlus(256);

/// A kind of mix between rope and B+ tree.
/// All nodes are node_size, located in in arenas, and aligned to node_size
/// Leaves contain bytes of the text buffer.
/// Leaves also point into an intrusive linked list of Markers.
/// Internal nodes contain pointers to nodes on the level below,
/// and how many text bytes are stored in that subtree.
/// Nodes also have pointers to parents and neighbours on their level.
///
///                  +-----+-------+----+-------+-------+
///                  | 104 | 0x000 | 77 | 0x200 |(empty)
///                  +-----+-------+----+-------+-------+
///                            ^               ^
///                           /                 \
///                          V                   V
///     +-----+----------+----------------+     +---------------+-----+
///     | 104 | ?*Marker | 104 bytes text | <-> | 77 | ?*Marker | 77 bytes text
///     +-----+----------+----------------+     +---------------+-----+
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

