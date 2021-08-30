const std = @import("std");
const assert = std.debug.assert;
const mem = std.mem;
const Allocator = mem.Allocator;

const ray = @import("raylib.zig");

const Window = @import("window.zig").Window;

/// The layout to be used for an area of a frame
pub const Layout = struct {
    const This = @This();

    /// Pixels used for the split bar
    const split_bar_width = 8;
    const split_bar_color = ray.MAROON;

    pub const SplitDirection = enum { horizontal, vertical };

    pub const Content = union(enum) {
        window: Window,
        split: struct {
            /// The allocator owning layout1 and layout2
            alloc: *Allocator,
            layout1: *Layout,
            layout2: *Layout,
            split_direction: SplitDirection,
            layout1_weight: u32,
            layout2_weight: u32,
        },
        empty
    };

    content: Content,
    width: i32 = 0,
    height: i32 = 0,

    pub fn initSplitLayout(layout1: Layout, layout2: Layout, split_direction: SplitDirection,
                           layout1_weight: u32, layout2_weight: u32, alloc: *Allocator) !Layout {
        const layout1_ptr = try alloc.create(Layout);
        errdefer alloc.destroy(layout1_ptr);
        const layout2_ptr = try alloc.create(Layout);
        errdefer alloc.destroy(layout2_ptr);

        layout1_ptr.* = layout1;
        layout2_ptr.* = layout2;

        return Layout{
            .content = .{
                .split = .{
                    .alloc = alloc,
                    .layout1 = layout1_ptr,
                    .layout2 = layout2_ptr,
                    .split_direction = split_direction,
                    .layout1_weight = layout1_weight,
                    .layout2_weight = layout2_weight
                }
            }
        };
    }

    pub fn resize(this: *This, width: i32, height: i32) void {
        assert(width >= 0 and height >= 0);
        this.width = width;
        this.height = height;
        this.propagateSize();
    }

    /// Make sure the content fits snuggly inside the layout
    /// For split layouts, new or removed space is distributed
    pub fn propagateSize(this: *This) void {
        switch (this.content) {
            .empty => {},
            .window => |*window| window.setSize(this.width, this.height),
            .split => |split| {
                const horz = split.split_direction == .horizontal;
                var layout1_size = if(horz) split.layout1.height else split.layout1.width;
                var layout2_size = if(horz) split.layout2.height else split.layout2.width;
                var current_size = @intCast(u32, layout1_size + split_bar_width + layout2_size);
                const wanted_size = if(horz) this.height else this.width;

                const total_weight = split.layout1_weight + split.layout2_weight;
                while (current_size < wanted_size) {
                    current_size += 1;
                    if (current_size % total_weight < split.layout1_weight)
                        layout1_size += 1
                    else
                        layout2_size += 1;
                }

                while (current_size > wanted_size) {
                    if (current_size % total_weight < split.layout1_weight)
                        layout1_size -= 1
                    else
                        layout2_size -= 1;
                    current_size -= 1;
                }

                // Make sure each side has a non-negative size, even if the split bar can't fit
                layout1_size = std.math.max(layout1_size, 0);
                layout2_size = std.math.max(layout2_size, 0);

                if (horz) {
                    split.layout1.resize(this.width, layout1_size);
                    split.layout2.resize(this.width, layout2_size);
                } else {
                    split.layout1.resize(layout1_size, this.height);
                    split.layout2.resize(layout2_size, this.height);
                }
            },
        }
    }

    pub fn render(this: *This, x: i32, y: i32) void {
        switch (this.content) {
            .empty => {},
            .window => |*window| {
                window.render(x, y, this.width, this.height);
            },
            .split => |split| {
                ray.DrawRectangle(x, y, this.width, this.height, split_bar_color);
                split.layout1.render(x, y);
                if (split.split_direction == .horizontal)
                    split.layout2.render(x, y + split.layout1.height + split_bar_width)
                else
                    split.layout2.render(x + split.layout1.width + split_bar_width, y);
            },
        }
    }

    /// Deinit the layout, and every sub-layout and window it owns
    pub fn deinit(this: *This) void {
        switch (this.content) {
            .window => |*window| {
                window.deinit();
            },
            .split => |*split| {
                split.layout1.deinit();
                split.layout2.deinit();
                split.alloc.destroy(split.layout1);
                split.alloc.destroy(split.layout2);
            },
            .empty => {},
        }
    }
};
