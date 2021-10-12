const std = @import("std");
const Allocator = std.mem.Allocator;
const NodeAllocator = @import("nodeAllocator.zig").NodeAllocator;

/// A sensible node size for a RopePlus
pub const DefaultRopePlus = RopePlus(256);

/// A kind of mix between rope and B+ tree.
/// All nodes are node_size, located in arenas, and aligned to node_size.
/// Leaves contain bytes of the text buffer.
/// Leaves also point into an intrusive linked list of stored markers.
/// Internal nodes contain pointers to nodes on the level below,
/// and how many text bytes are stored in that subtree.
/// All nodes also have pointers to parents and neighbours on their level.
///
///                  +-----+-------+----+-------+-------+
///                  | 104 | 0x000 | 77 | 0x200 |(empty)
///                  +-----+-------+----+-------+-------+
///                            ^               ^
///                           /                 \
///                          V                   V
///     +-----+----------+----------------+     +---------------+---------------+
///     | 104 | ?*Marker | 104 bytes text | <-> | 77 | ?*Marker | 77 bytes text |
///     +-----+----------+----------------+     +---------------+---------------+
///
pub fn RopePlus(comptime node_size: usize) type {
    return struct {
        const This = @This();

        /// The type used to store length of node content (including sub-nodes)
        const NodeContentSize = u64;
        const DownPointerCount = u64;

        /// A Node, either a leaf node or an internal node.
        /// Needs to have size equal to node_size, and be aligned to node_size.
        /// This allows pointers into nodes to find the start of the node.
        pub const Node = struct {
            content_size: NodeContentSize align(node_size),
            left_node: ?*Node,
            right_node: ?*Node,
            /// The parent of this node needs to know how much text there is in this subtree
            parent_reverse_edge: ?*InternalNodeData.DownPointer,
            content: union(enum) {
                internal: InternalNodeData,
                leaf: LeafNodeData
            },

            // Check that all requirements for Node are met.
            comptime {
                if (@sizeOf(@This()) != node_size) {
                    const msg = std.fmt.comptimePrint("sizeOf Node ({}) is not node_size ({})",
                                                      .{@sizeOf(@This()), node_size});
                    @compileError(msg);
                }
                if (@alignOf(@This()) != node_size) {
                    @compileError("Node is not node_size aligned");
                }
            }
        };
        const sizeof_node_ptr = @sizeOf(usize);
        const size_left_for_content = node_size
            - sizeof_node_ptr*2
            - @sizeOf(?*InternalNodeData.DownPointer)
            - @sizeOf(NodeContentSize)
            - 8; // Magic number 8 = size of union tag + padding for pointer alignment

        /// An internal node contains a bunch of pointers down to its children
        /// Each down pointer also has the amount of text bytes to be found in that subtree.
        pub const InternalNodeData = struct {
            pub const DownPointer = struct {
                child: ?*Node,
                child_content_size: NodeContentSize
            };
            const sizeof_down_pointer = sizeof_node_ptr + @sizeOf(NodeContentSize);
            const size_left_for_down_pointers = size_left_for_content - @sizeOf(DownPointerCount);
            pub const max_down_pointers = size_left_for_down_pointers / sizeof_down_pointer;

            down_pointer_count: DownPointerCount,
            down_pointers: [max_down_pointers]DownPointer,
        };

        /// A leaf node only contains bytes.
        /// The first 'content_size' bytes of the content array is used.
        pub const LeafNodeData = struct {
            pub const max_content_length = size_left_for_content;
            content: [max_content_length]u8,
        };

        node_allocator: NodeAllocator(Node),
        root_node: *Node,
        /// All leaf nodes are on level 0
        root_node_level: u8,

        pub fn init(alloc: *Allocator) !This {
            var node_allocator = try NodeAllocator(Node).init(alloc);
            errdefer node_allocator.deinit();

            const root_node = try node_allocator.allocateNode();
            root_node.* = create_empty_leaf_node();

            return This{
                .node_allocator = node_allocator,
                .root_node = root_node,
                .root_node_level = 0
            };
        }

        pub fn deinit(this: *This) void {
            // All nodes are allocated in the arenas, so no need to free each node
            this.node_allocator.deinit();
        }

        /// Creates an empty leaf node with no parent
        pub fn create_empty_leaf_node() Node {
            return Node{
                .content_size = 0,
                .left_node = null,
                .right_node = null,
                .parent_reverse_edge = null,
                .content = .{
                    .leaf = .{
                        .content = .{0}**LeafNodeData.max_content_length,
                    }
                }
            };
        }

        pub fn get_length(this: *This) NodeContentSize {
            return root_node.content_length;
        }

        /// Returns the leftmost leaf node
        pub fn get_first_leaf_node(this: *This) !Node {
            var node = this.root_node;
            while(true) {
                switch(node.content) {
                    .internal => |internal| {
                        if (internal.down_pointer_count == 0) unreachable;
                        node = internal.down_pointers[0].child;
                    },
                    .leaf => return node
                }
            }
        }

        /// Returns the rightmost leaf node
        pub fn get_last_leaf_node(this: *This) !Node {
            var node = this.root_node;
            while(true) {
                switch(node.content) {
                    .internal => |internal| {
                        const child_count = internal.down_pointer_count;
                        if (child_count == 0) unreachable;
                        node = internal.down_pointers[child_count-1].child;
                    },
                    .leaf => return node
                }
            }
        }

        /// Returns the parent node given a pointer to one of its down pointers
        pub fn down_pointer_to_node(down_ptr: *InternalNodeData.DownPointer) *Node {
            const down_ptr_int = @ptrToInt(down_ptr);
            // Because all Nodes are aligned to node_size, we can find the start
            const node_ptr_int = down_ptr_int - down_ptr_int % node_size;
            return @intToPtr(*Node, node_ptr_int);
        }

        /// Splits the specified leaf node into two leaf nodes,
        /// and updates the parent node, possibly splitting it too.
        ///
        /// Exisitng byte content is split between the two new nodes
        /// according to the optional parameter left_content, like so:
        /// (left_content), (total-left_content)
        ///
        /// if left_content == null, the content is split (total+1)/2, total/2
        ///
        /// If allocation fails, the rope is restored to its correct state
        pub fn split_leaf_node(this: *This, node: *Node, left_content: ?u32) !void {
            if (node.content != .leaf) unreachable;

            const total = node.content_size;
            var left_size = (total+1)/2;
            if(left_content) |it| {
                if (it > total) unreachable;
                left_size = it;
            }
            const right_size = total - left_size;
            if (left_size > LeafNodeData.max_content_length) unreachable;
            if (right_size > LeafNodeData.max_content_length) unreachable;

            // The current node becomes the left node
            const left_node = node;
            const right_node = try this.node_allocator.allocateNode();
            errdefer this.node_allocator.freeNode(right_node);
            right_node.* = create_empty_leaf_node();

            // Share the content between left and right
            left_node.content_size = left_size;
            right_node.content_size = right_size;
            @memcpy(right_node.content.leaf.content,
                    left_node.content.leaf.content[left_size..], right_size);

            // Update pointers on the right node
            right_node.right_node = left_node.right_node;
            right_node.left_node = left_node;

            // Update pointers on the left node
            left_node.right_node = right_node;
            // left_node already has the correct left pointer
            // A potential node to the left of the left node
            // already correctly points to the left node

            // Update pointer to the right of the right node
            if (right_node.right_node) |rightright|
                rightright.left_node = right_node;

            // If we have a parent, inform the parent
            if (node.parent_reverse_edge) |rev_edge| {
                const parent = down_ptr_to_node(node.parent_reverse_edge);

            } else {
                // We dont have a parant, so create a new root node!
                // TODO: Do this alloc first!
            }
        }
    };
}
