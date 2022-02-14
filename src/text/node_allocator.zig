const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const page_size = 4096;

/// Can we fit a whole number of size in a page,
/// or a whole number of pages in the given size?
fn page_align_possible(size: usize) bool {
    return size % page_size == 0 or page_size % size == 0;
}

/// Allocator for allocating lots of objects of the same size.
/// Always allocates a whole multiple of pages from the underlying allocator.
/// The type's alignment must divide the page size
///
/// Nothing is freed until the entire structure is deinit(),
/// Freeing a single node will add it to a freelist, but is not a requirement.
pub fn NodeAllocator(T: type) type {
    // Make sure the given type fits perfectly with our allocated pages
    comptime std.debug.assert(page_align_possible(@sizeOf(T)));
    comptime std.debug.assert(page_align_possible(@alignOf(T)));

    // How many nodes must be allocated to get a whole number of pages
    const minimum_node_allocation_count = @maximum(page_size / @sizeOf(T), 1);
    // What alignment is required to satify both T alignment and page alignment
    const minimum_node_allocation_alignment = @maximum(page_size, @alignOf(T));

    return struct {
        const This = @This();
        const max_area_count = 24;

        alloc: Allocator,
        /// Any nodes that get freed are pushed to this list
        free_node_stack: ArrayList(*Node),
        areas: [max_area_count]?[]Node = .{null} ** max_area_count,
        current_area: i8 = -1,
        next_node_in_area: usize = 0,

        pub fn init(alloc: Allocator) This {
            return This{
                .alloc = alloc,
                .free_node_stack = ArrayList(*Node).init(alloc),
            };
        }

        pub fn deinit(this: *This) void {
            this.free_node_stack.deinit();
            for (this.areas) |area| {
                if (area) |it| {
                    this.alloc.free(it);
                }
            }
        }

        /// How many nodes should be in the given area.
        /// Will always fit in a whole number of pages.
        fn nodesInArea(area_index: i8) usize {
            if (area_index < 0)
                return 0;
            if (area_index > 10)
                area_index -= (area_index - 10) / 4;
            return @shlExact(minimum_node_allocation_count, area_index);
        }

        pub fn allocateNode(this: *This) !*Node {
            if (this.free_node_stack.items.len > 0)
                return this.free_node_stack.pop();

            if (this.next_node_in_area < nodesInArea(this.current_area)) {
                const new_node = &this.areas[this.current_area][this.next_node_in_area];
                this.next_node_in_area += 1;
                return new_node;
            }

            // The previous area is full!
            // Allocate a new one!
            this.current_area += 1;
            if (this.current_area >= max_area_count)
                return Allocator.Error.OutOfMemory;
            this.areas[this.current_area] =
                try this.alloc.alignedAlloc(T, minimum_node_allocation_alignment, nodesInArea(this.current_area));
            return &this.areas[this.current_area][0];
        }

        /// Places the node in the freelist, which lets it be reused.
        /// It is not a requirement, since all nodes get freed when the allocator is deinit.
        /// If the memory allocation of the freelist fails, we just don't care
        pub fn freeNode(this: *This, node: *Node) void {
            this.free_node_stack.append(node) catch {};
        }
    };
}
