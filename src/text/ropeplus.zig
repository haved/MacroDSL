const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;

const NodeAllocator = @import("node_allocator.zig").NodeAllocator;

/// Datastructure for holding text, indexing on byte count and newlines.
/// Built like a B+-tree, leaf nodes contain bytes of text, while internal nodes have many children.
/// All nodes have pointers to their children, parent, and neighbours.
/// These are used for quick navigation, and to keep parents informed about subtree content.
/// To aid in this, internal nodes are also internal_size aligned.
///
/// The internal nodes count bytes and newlines in its subtree,
/// but these counts can be made dirty to speed up tasks that don't use the indexing.
///
/// Leaf nodes can hold markers, that stay in place even if the text around it is modified.
pub fn RopePlus(leaf_size: usize, internal_size: usize) type {
    const LeafNode = struct {
        pub const content_size_type = u8;
        pub const max_content_size = leaf_size - @sizeOf(*IntrNode) - 2 * @sizeOf(*LeafNode) - 2 * @sizeOf(content_size_type);

        parent: *IntrNode,
        left_node: ?*LeafNode,
        right_node: ?*LeafNode,
        content_size: content_size_type,
        newline_count: content_size_type,
        content: [max_content_size]u8,
    };
    const IntrNode = struct {};

    comptime {
        assert(std.math.maxInt(content_size_type) >= max_content_size);
        assert(@sizeOf(LeafNode) == leaf_size);
        assert(@sizeOf(IntrNode) == internal_size);
    }

    return struct {
        const This = @This();
        pub const LeafNode = LeafNode;
        pub const IntrNode = IntrNode;

        leaf_alloc: NodeAllocator(LeafNode),
        intr_alloc: NodeAllocator(IntrNode),

        // level 0 is always the leaf nodes, and count up from there
        root_level: usize,
        root: *IntrNode,

        pub fn init(alloc: Allocator) !This {
            const leaf_alloc = try NodeAllocator.init(alloc);
            errdefer leaf_alloc.deinit();
            const intr_alloc = try NodeAllocator.init(alloc);
            errdefer intr_alloc.deinit();

            return This{
                .leaf_alloc = leaf_alloc,
                .intr_alloc = intr_alloc,
            };
        }

        pub fn deinit(this: *This) void {
            this.leaf_alloc.deinit();
            this.intr_alloc.deinit();
        }
    };
}
