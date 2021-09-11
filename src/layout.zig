const std = @import("std");
const assert = std.debug.assert;
const mem = std.mem;
const Allocator = mem.Allocator;

const ray = @import("raylib.zig");

const Window = @import("window.zig").Window;
const Own = @import("mem.zig").Own;
const colors = &@import("colors.zig").current;

/// The layout to be used for an area of a frame
pub const Layout = struct {
    const This = @This();

    pub const SplitDirection = enum { horizontal, vertical };

    pub const Content = union(enum) {
        window: Window,
        split: SplitContent,
        border: struct {
            alloc: *Allocator,
            child: Own(Layout),
            border_width: i32
        },
        empty
    };

    pub const SplitContent = struct {
        alloc: *Allocator,
        layout1: Own(Layout),
        layout2: Own(Layout),
        split_direction: SplitDirection,
        split_bar_width: i32,
        moveable: bool = true,
        mouse_state: enum { standby, hover, pressed } = .standby,
        // Minimum sizes for sublayouts when moving the bar
        layout1_min_size: i32,
        layout2_min_size: i32,
        // Last manually set size
        layout1_desired_size_ratio: i32,
        layout2_desired_size_ratio: i32,
    };

    content: Content,
    x: i32 = 0,
    y: i32 = 0,
    width: i32 = 0,
    height: i32 = 0,

    /// Creates a split layout containing the given layouts.
    /// Once bounds are set, the space is divided to the sub-layouts.
    /// If a sub-layout already has a size, that will affect the resulting split
    pub fn initSplitLayout(layout1: Layout, layout2: Layout, split_direction: SplitDirection,
                           split_bar_width: i32, moveable: bool,
                           layout1_min_size: i32, layout2_min_size: i32,
                           layout1_desired_size_ratio: i32, layout2_desired_size_ratio: i32,
                           alloc: *Allocator) !Layout {
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
                    .split_bar_width = split_bar_width,
                    .moveable = moveable,

                    .layout1_min_size = layout1_min_size,
                    .layout2_min_size = layout2_min_size,
                    .layout1_desired_size_ratio = layout1_desired_size_ratio,
                    .layout2_desired_size_ratio = layout2_desired_size_ratio
                }
            }
        };
    }

    /// Creates a border around an existing layout
    pub fn initBorderLayout(child: Layout, border_width: i32, alloc: *Allocator) !Layout {
        const child_ptr = try alloc.create(Layout);
        errdefer alloc.destruy(child_ptr);
        child_ptr.* = child;
        return Layout {
            .content = .{
                .border = .{
                    .alloc = alloc,
                    .child = child_ptr,
                    .border_width = border_width
                }
            }
        };
    }

    pub fn setBounds(this: *This, x: i32, y: i32, width: i32, height: i32) void {
        assert(width >= 0 and height >= 0);
        this.x = x;
        this.y = y;
        this.width = width;
        this.height = height;
        this.recalculateLayout();
    }

    /// Make sure the content fits snuggly inside the layout
    /// For split layouts, new or removed space is distributed
    pub fn recalculateLayout(this: *This) void {
        switch (this.content) {
            .empty => {},
            .window => |*window| window.setBounds(this.x, this.y, this.width, this.height),
            .split => |*split| {
                this.recalculateSplitLayout(split);
            },
            .border => |border| {
                var bw = border.border_width;
                if (bw*2 > this.width or bw*2 > this.height)
                    bw = 0;
                border.child.setBounds(this.x + bw, this.y + bw, this.width - bw*2, this.height - bw*2);
            }
        }
    }

    fn recalculateSplitLayout(this: *This, split: *SplitContent) void {
        if (&this.content.split != split) unreachable;

        const horz = split.split_direction == .horizontal;
        var layout1_size = if(horz) split.layout1.height else split.layout1.width;
        var layout2_size = if(horz) split.layout2.height else split.layout2.width;
        var current_size = layout1_size + split.split_bar_width + layout2_size;
        const wanted_size = if(horz) this.height else this.width;

        while (current_size < wanted_size) {
            current_size += 1;

            const layout1_undersized = layout1_size < split.layout1_min_size;
            const layout2_undersized = layout2_size < split.layout2_min_size;

            if (layout1_undersized and !layout2_undersized)
                layout1_size += 1
            else if (layout2_undersized and !layout1_undersized)
                layout2_size += 1
            else if (layout1_size * split.layout2_desired_size_ratio
                         < layout2_size * split.layout1_desired_size_ratio)
                layout1_size += 1
            else
                layout2_size += 1;
        }

        while (current_size > wanted_size) {
            current_size -= 1;

            const layout1_at_min = layout1_size <= split.layout1_min_size;
            const layout2_at_min = layout2_size <= split.layout2_min_size;

            if(layout1_at_min and !layout2_at_min)
                layout2_size -= 1
            else if(layout2_at_min and !layout1_at_min)
                layout1_size -= 1
            else if (layout1_size * split.layout2_desired_size_ratio
                         > layout2_size * split.layout1_desired_size_ratio)
                layout1_size -= 1
            else
                layout2_size -= 1;
        }

        // Make sure each side has a non-negative size, even if the split bar can't fit
        layout1_size = std.math.max(layout1_size, 0);
        layout2_size = std.math.max(layout2_size, 0);

        if (horz) {
            split.layout1.setBounds(this.x, this.y, this.width, layout1_size);
            split.layout2.setBounds(this.x, this.y + layout1_size + split.split_bar_width, this.width, layout2_size);
        } else {
            split.layout1.setBounds(this.x, this.y, layout1_size, this.height);
            split.layout2.setBounds(this.x + layout1_size + split.split_bar_width, this.y, layout2_size, this.height);
        }
    }

    fn isPointInLayout(this: *const This, x: i32, y: i32) bool {
        return x >= this.x and y >= this.y and x < this.x+this.width and y < this.y+this.height;
    }

    pub fn update(this: *This) void {
        switch (this.content) {
            .empty => {},
            .window => |*window| {
                window.update();
            },
            .split => |*split| {
                this.handleSplitBarUpdate(split);
                split.layout1.update();
                split.layout2.update();
            },
            .border => |border| {
                border.child.update();
            }
        }
    }

    fn handleSplitBarUpdate(this: *This, split: *SplitContent) void {
        if (&this.content.split != split) unreachable;

        if (!split.moveable)
            return;

        // Handle moving of the split bar
        const mx = ray.GetMouseX();
        const my = ray.GetMouseY();
        if (this.isPointInLayout(mx, my)
                and !split.layout1.isPointInLayout(mx, my)
                and !split.layout2.isPointInLayout(mx, my)) {
            // Mouse cursor is on split bar
            if (ray.IsMouseButtonPressed(ray.MOUSE_LEFT_BUTTON))
                split.mouse_state = .pressed
                else if(ray.IsMouseButtonUp(ray.MOUSE_LEFT_BUTTON))
                split.mouse_state = .hover;
        } else {
            // We are not hovering the split bar
            if(split.mouse_state == .hover or ray.IsMouseButtonUp(ray.MOUSE_LEFT_BUTTON))
                split.mouse_state = .standby;

            if (split.mouse_state == .pressed) {
                switch(split.split_direction) {
                    .vertical => {
                        while (mx < split.layout1.x+split.layout1.width
                                   and split.layout1.width > split.layout1_min_size) {
                            split.layout1.width -= 1;
                            split.layout2.x -= 1;
                            split.layout2.width += 1;
                        }
                        while (mx > split.layout2.x
                                   and split.layout2.width > split.layout2_min_size) {
                            split.layout1.width += 1;
                            split.layout2.x += 1;
                            split.layout2.width -= 1;
                        }

                    },
                    .horizontal => {
                        while (my < split.layout1.y+split.layout1.height
                                   and split.layout1.height > split.layout1_min_size) {
                            split.layout1.height -= 1;
                            split.layout2.y -= 1;
                            split.layout2.height += 1;
                        }
                        while (my > split.layout2.y
                                   and split.layout2.height > split.layout2_min_size) {
                            split.layout1.height += 1;
                            split.layout2.y += 1;
                            split.layout2.height -= 1;
                        }
                    }
                }

                // Update the desired split ratio since the user moved the bar
                split.layout1_desired_size_ratio = split.layout1.width;
                split.layout2_desired_size_ratio = split.layout2.width;

                split.layout1.recalculateLayout();
                split.layout2.recalculateLayout();
            }
        }
    }

    pub fn render(this: *This) void {
        switch (this.content) {
            .empty => {},
            .window => |*window| {
                window.render();
            },
            .split => |split| {
                split.layout1.render();
                split.layout2.render();
                const bar_color = switch(split.mouse_state) {
                    .standby => colors.split_bar,
                    .hover => colors.split_bar_hover,
                    .pressed => colors.split_bar_pressed,
                };
                if (split.split_direction == .horizontal) {
                    ray.DrawRectangle(this.x, split.layout2.y-split.split_bar_width,
                                      this.width, split.split_bar_width, bar_color);
                } else {
                    ray.DrawRectangle(split.layout2.x-split.split_bar_width, this.y,
                                      split.split_bar_width, this.height, bar_color);
                }
            },
            .border => |border| {
                border.child.render();
            }
        }
    }

    /// Deinit the layout, and every sub-layout and window it owns
    pub fn deinit(this: *This) void {
        switch (this.content) {
            .empty => {},
            .window => |*window| {
                window.deinit();
            },
            .split => |*split| {
                split.layout1.deinit();
                split.layout2.deinit();
                split.alloc.destroy(split.layout1);
                split.alloc.destroy(split.layout2);
            },
            .border => |border| {
                border.child.deinit();
                border.alloc.destroy(border.child);
            }
        }
    }
};
