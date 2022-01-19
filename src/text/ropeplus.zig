const std = @import("std");
const Allocator = std.mem.Allocator;
const NodeAllocator = @import("nodeAllocator.zig").NodeAllocator;

/// A sensible node size for a RopePlus
pub const DefaultRopePlus = RopePlus(256);

/// A kind of mix between rope and B+ tree.
/// All nodes are node_size, located in arenas, and aligned to node_size.
/// Leaves contain bytes of the text buffer.
/// Leaves also point into an intrusive linked list of stored markers.
/// Internal nodes contain pointers to nodes on the level below.
/// These are called down pointers, and they also include how many text bytes are stored in that subtree.
/// These must of course be updated when a child node is updated.
/// All nodes also have pointers to their parent and neighbours on their level.
///
///            +-----+-----+-------+----+-------+-------+
///            | 181 | 104 | 0x000 | 77 | 0x200 |(empty)
///            +-----+-----+-------+----+-------+-------+
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
        pub const NodeContentSize = u64;
        /// The type used to store count of down pointers in an internal node.
        pub const DownPointerCount = u8;

        /// A Node, either a leaf node or an internal node.
        /// Needs to have size equal to node_size, and be aligned to node_size.
        /// This allows pointers into nodes to find the start of the node.
        pub const Node = struct {
            bytes_in_subtree: NodeContentSize align(node_size),
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
                if (@sizeOf(@This()) != node_size)
                    @compileError(std.fmt.comptimePrint("sizeOf Node ({}) is not node_size ({})",
                                                        .{@sizeOf(@This()), node_size}));
                if (@alignOf(@This()) != node_size)
                    @compileError("Node is not node_size aligned");
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
                bytes_in_child: NodeContentSize
            };
            const sizeof_down_pointer = sizeof_node_ptr + @sizeOf(NodeContentSize);
            const size_left_for_down_pointers = size_left_for_content - @sizeOf(DownPointerCount);
            pub const max_down_pointers = size_left_for_down_pointers / sizeof_down_pointer;

            down_pointer_count: DownPointerCount,
            down_pointers: [max_down_pointers]DownPointer,
        };

        /// A leaf node only contains bytes.
        /// The first 'bytes_in_subtree' bytes of the content array is used.
        pub const LeafNodeData = struct {
            pub const max_content_length = size_left_for_content;
            content: [max_content_length]u8,
        };

        node_allocator: NodeAllocator(Node),
        root_node: *Node,

        pub fn init(alloc: Allocator) !This {
            var node_allocator = try NodeAllocator(Node).init(alloc);
            errdefer node_allocator.deinit();

            const root_node = try node_allocator.allocateNode();
            // We don't need to free the node, since the node_allocator "owns" it.
            root_node.* = create_empty_leaf_node();

            return This{
                .node_allocator = node_allocator,
                .root_node = root_node
            };
        }

        pub fn deinit(this: *This) void {
            // All nodes are "owned" by the node_allocator, so no need to free each node
            this.node_allocator.deinit();
        }

        /// Creates an empty leaf node with no parent
        pub fn create_empty_leaf_node() Node {
            return Node{
                .bytes_in_subtree = 0,
                .left_node = null,
                .right_node = null,
                .parent_reverse_edge = null,
                .content = .{
                    .leaf = .{
                        .content = undefined,
                    }
                }
            };
        }

        /// Creates an empty internal node with no parent
        pub fn create_empty_internal_node() Node {
            return Node{
                .bytes_in_subtree = 0,
                .left_node = null,
                .right_node = null,
                .parent_reverse_edge = null,
                .content = .{
                    .internal = .{
                        .down_pointer_count = 0,
                        .down_pointers = undefined,
                    }
                }
            };
        }

        pub fn get_length(this: *This) NodeContentSize {
            return this.root_node.bytes_in_subtree;
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

        /// Gives the leftmost child of an internal node
        pub fn get_leftmost_child(node: *Node) *Node {
            if(node.content.internal) |internal| {
                if (internal.down_pointer_count == 0)
                    unreachable;
                return internal.down_pointers[0].child;
            } else unreachable;
        }

        /// Gives the rightmost child of an internal node
        pub fn get_rightmost_child(node: *Node) *Node {
            if(node.content.internal) |internal| {
                const count = internal.down_pointer_count;
                if (count == 0)
                    unreachable;
                return internal.down_pointers[count-1].child;
            } else unreachable;
        }

        /// Returns the parent node given a pointer to one of its down pointers
        pub fn down_pointer_to_parent_node(down_ptr: *InternalNodeData.DownPointer) *Node {
            const down_ptr_int = @ptrToInt(down_ptr);
            // Because all Nodes are aligned to node_size, we can find the start
            const node_ptr_int = down_ptr_int - down_ptr_int % node_size;
            return @intToPtr(*Node, node_ptr_int);
        }

        /// Returns the index of the given down pointer in the node that owns it.
        pub fn down_pointer_to_down_pointer_index(down_ptr: *InternalNodeData.DownPointer) DownPointerCount {
            const node = down_pointer_to_down_pointer_index(down_ptr);
            return down_ptr - node.content.internal.down_pointers;
        }

        /// Connect the parent and child in a two way connection.
        /// The down pointer index must be within the down_pointer_count.
        /// Updates the parent's bytes_in_subtree.
        ///
        /// If handle_removed is .subtract, the current child's size is subtracted.
        /// if handle_removed is .ignore, the current down pointer is assumed to be garbage.
        ///
        /// If handle_added is .add, the added child's size is added.
        /// if handle_added is .ignore, the child is assumed to already be a non-removed child.
        inline fn establish_down_pointer_relation(parent: *Node, down_ptr_index: DownPointerCount,
                                                  handle_removed: enum {subtract, ignore},
                                                  handle_added: enum {add, ignore},
                                                  child: *Node) void {
            if (down_ptr_index >= parent.content.internal.down_pointer_count) unreachable;

            const down_pointer = &parent.content.internal.down_pointers[down_ptr_index];
            if (handle_removed == .subtract)
                parent.bytes_in_subtree -= down_pointer.bytes_in_child;

            down_pointer.* = .{
                .child = child,
                .bytes_in_child = child.bytes_in_subtree
            };
            child.parent_reverse_edge = down_pointer;

            if (handle_added == .update)
                parent.bytes_in_subtree += child.bytes_in_subtree;
        }

        /// Replaces the root node with a new node,
        /// which becomes the parent of the exising root node
        fn give_root_node_parent(this: *This) !void {
            const old_root = this.root_node;
            this.root_node = try this.node_allocator.allocateNode();
            this.root_node.* = create_empty_internal_node();
            this.root_node.content.internal.down_pointer_count = 1;
            establish_down_pointer_relation(this.root_node, 0, .ignore, .add, old_root);
        }

        /// Make sure the node has a parent node with enough space for another child
        /// Will fail if allocation fails, in which case nothing is changed
        fn assure_has_parent_with_extra_space(this: *This, node: *Node) !void {
            if (node.parent_reverse_edge) |parent_reverse_edge| {
                const parent = down_pointer_to_parent_node(parent_reverse_edge);
                // If the current parent doesn't have room for more children, split it
                if (parent.content.internal.down_pointer_count + 1 > InternalNodeData.max_down_pointers)
                    try this.split_internal_node(parent, null);
            } else {
                // We have to parent, we are the current root node, make a new one
                if (node != this.root_node) unreachable;
                try this.give_root_node_parent();
            }
        }

        /// Attaches the two-way linked list between four concecutive nodes
        /// The left_left and right_right nodes can be null
        fn update_same_level_pointers(left_left: ?*Node, left_node: *Node, right_node: *Node, right_right: ?*Node) !void {
            if (left_left) |it|
                it.right_node = left_node;
            left_node.left_node = left_left;
            left_node.right_node = right_node;
            right_node.left_node = left_node;
            right_node.right_node = right_right;
            if (right_right) |it|
                it.left_node = right_node;
        }

        /// Adds a new child at the given position, possibly moving existing children back to make room.
        /// Will update the bytes_in_subtree with the size of the inserted child.
        /// The parent node must have room for the child.
        /// The index must be within or exactly at the end of the exisiting child list.
        fn insert_child_in_internal_node(parent: *Node, index: DownPointerCount, child: *Node) !void {
            if (parent.content != .internal) unreachable;
            const parent_internal = &parent.content.internal;
            // The inserted child must be inside or next to the existing list. No holes!
            if (index > parent_internal.down_pointer_count) unreachable;

            // The last child in the current list
            var down_ptr = parent_internal.down_pointer_count-1;

            // Increase the amount of children
            parent_internal.down_pointer_count+=1;
            if (parent_internal.down_pointer_count >= InternalNodeData.max_down_pointers) unreachable;

            // Move all children that come at or after index
            while (down_ptr >= index) {
                const movechild = parent_internal.down_pointers[down_ptr];
                // We just move each child, so don't subtract or add content size
                establish_down_pointer_relation(parent, down_ptr+1, .ignore, .ignore, movechild);
                down_ptr-=1;
            }

            // Finally insert the new child
            establish_down_pointer_relation(parent, index, .ignore, .add, child);
        }

        /// Splits the specified node into two nodes,
        /// and updates the parent node, possibly splitting it too.
        /// If there is no parent node, it is created.
        ///
        /// This function works for both internal and leaf nodes,
        /// but which kind must be specified at compile time.
        ///
        /// Exising content is split between the two new nodes
        /// according to the optional parameter left_split, like so:
        /// (left_split), (total-left_split)
        ///
        /// Note that existing content, in the case of internal nodes, is the set of child nodes.
        ///
        /// if left_split == null, the content is split (total+1)/2, total/2
        ///
        /// If allocation fails, no modification is made to the data structure
        pub fn split_node(this: *This, node: *Node, left_split: ?u32, comptime leaf_node: bool) !void {
            // Make sure we are compiled for the kind of node given
            if (leaf_node != (node.content==.leaf)) unreachable;

            // Calculate left_size and right_size
            const total = if(leaf_node) node.bytes_in_subtree
                          else node.content.internal.down_pointer_count;
            var left_size = (total+1)/2;
            if(left_split) |it| {
                if (it > total) unreachable;
                left_size = it;
            }
            const right_size = total - left_size;

            // The current node becomes the left node, create a new node for the right node
            const left_node = node;
            const right_node = try this.node_allocator.allocateNode();
            errdefer this.node_allocator.freeNode(right_node);

            if (leaf_node)
                right_node.* = create_empty_leaf_node()
            else
                right_node.* = create_empty_internal_node();

            // Make sure we have a parent, and that it has enough space for an additional child
            try this.assure_has_parent_with_space(node);

            // Share the content between the left and right nodes
            if (leaf_node) {
                // Move text bytes from the left leaf node to the right leaf node
                left_node.bytes_in_subtree = left_size;
                right_node.bytes_in_subtree = right_size;
                for (left_node.content.leaf.content[left_size..]) |b, i|
                    right_node.content.leaf.content[i] = b;
            } else {
                // Move child nodes from left internal node to right internal node
                left_node.content.internal.down_pointer_count = left_size;
                right_node.content.internal.down_pointer_count = right_size;
                for (left_node.content.internal.down_pointers[left_size..]) |down_ptr, i| {
                    establish_down_pointer_relation(right_node, i, .ignore, .add, down_ptr.child);
                }
                // The moved children have had their size added to right_node's bytes_in_subtree
                // Remove this byte count from left_node
                left_node.bytes_in_subtree -= right_node.bytes_in_subtree;
            }

            // Insert right_node as a child of our parent, right after left_node.
            // Also update the down pointer to the left_node with its new size.
            const parent = down_pointer_to_parent_node(node.parent_reverse_edge);
            const left_node_down_inx = down_pointer_to_down_pointer_index(node.parent_reverse_edge);
            const right_node_down_inx = left_node_down_inx+1;
            insert_child_in_internal_node(parent, right_node_down_inx, right_node);
            establish_down_pointer_relation(parent, left_node_down_inx, .subtract, .add, left_node);

            // Update pointers between nodes on this level
            update_same_level_pointers(node.left_node, left_node, right_node, node.right_node);
        }

        /// Panics if the data structure is somehow incorrect
        pub fn validate_invariants(this: *This) void {
            this.validate_node(this.root_node);
        }

        /// Recursivly validates the node and the nodes bellow
        ///
        /// For leaf nodes:
        ///  - Checks that the byte count is a legal number
        ///
        /// For internal nodes:
        ///  - Checks that the byte count is correct
        ///    - Our childrens byte counts sum up to our byte count
        ///    - The down pointers agree with the children
        ///  - Makes sure all children correctly point back up to node
        ///  - Makes sure all children have correct horizontal pointers between them
        ///    - Even checks the leftmost and rightmost horizontal pointers, "cross edges".
        ///  - All subtrees are the same height
        ///
        /// Returns the depth to leaf nodes, if node is a leaf node, returns 0
        fn validate_node(node: *Node) u32 {
            switch(node.content) {
                .leaf => {
                    if(node.bytes_in_subtree > LeafNodeData.max_content_length)
                        @panic("Leaf node is overfull!");
                    return 0;
                },
                .internal => |internal| {
                    if (internal.down_pointer_count == 0)
                        @panic("Empty internal node is not allowed");

                    // we create our own subtree byte count to check
                    const byte_count_sum: NodeContentSize = 0;

                    // every child should have the same height down to level 0
                    var common_child_depth: ?u32 = null;

                    // Iterate over each child
                    for (internal.down_pointers[0..internal.down_pointer_count]) |down_pointer, i| {
                        const child = down_pointer.child;

                        // validate the child
                        const child_depth = validate_node(child);

                        // also make sure that all children have the same depth
                        if (common_child_depth == null)
                            common_child_depth = child_depth;
                        if (child_depth != common_child_depth)
                            @panic("Child nodes have different heights");

                        // Make sure child and parent agree on bytes in child subtree
                        if (child.bytes_in_subtree != down_pointer.bytes_in_child)
                            @panic("Down pointer has different byte count compared to the child");
                        // Add up bytes in all child subtrees
                        byte_count_sum += down_pointer.bytes_in_child;

                        // Make sure the child points correctly back
                        if (child.parent_reverse_edge != &down_pointer)
                            @panic("Child isn't pointing back at down pointer");

                        // check the child's left and right pointer
                        const childs_left_neighbour = if (i > 0)
                            internal.down_pointers[i-1].child
                            else if(node.left_node) |left_node|
                            get_rightmost_child(left_node)
                            else null;

                        const childs_right_neighbour = if (i+1 < internal.down_pointer_count)
                            internal.down_pointers[i+1].child
                            else if(node.right_node) |right_node|
                            get_leftmost_child(right_node)
                            else null;

                        if (childs_left_neighbour != child.left_node
                                or childs_right_neighbour != child.right_node)
                            @panic("Child left or right pointer doesn't point to correct neighbour child");
                    }

                    if (byte_count_sum != node.bytes_in_subtree)
                        @panic("Internal node's bytes_in_subtree not equal sum of children");

                    // all our children have the same height, we have that height+1
                    return common_child_depth + 1;
                }
            }
        }
    };
}
