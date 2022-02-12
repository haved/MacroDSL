const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;

const Own = @import("../mem.zig").Own;

const ray = @import("raylib");
const Window = @import("window.zig").Window;
const colors = &@import("colors.zig").current_map;

/// The layout to be used for an area of a frame
pub const Layout = struct {
    const This = @This();

    pub const SplitDirection = enum { horizontal, vertical };

    pub const Content = union(enum) {
        window: Window,
        split: SplitContent,
        border: struct {
            alloc: Allocator,
            child: Own(Layout),
            border_width: i32
        },
        empty
    };

    pub const SplitContent = struct {
        alloc: Allocator,
        layout1: Own(Layout),
        layout2: Own(Layout),
        split_direction: SplitDirection,
        split_bar_width: i32,
        moveable: bool = true,
        mouse_state: enum { standby, hover, pressed } = .standby,
        // The position on the current split bar where the dragging started
        drag_start: i32 = 0,
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
                           alloc: Allocator) !Layout {
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
    pub fn initBorderLayout(child: Layout, border_width: i32, alloc: Allocator) !Layout {
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
        if (width < 0 or height < 0) @panic("negative layout bounds");
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
            .split => {
                this.recalculateSplitLayout();
            },
            .border => |border| {
                var bw = border.border_width;
                if (bw*2 > this.width or bw*2 > this.height)
                    bw = 0;
                border.child.setBounds(this.x + bw, this.y + bw, this.width - bw*2, this.height - bw*2);
            }
        }
    }

    fn recalculateSplitLayout(this: *This) void {
        const split = &this.content.split;

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
        layout1_size = @maximum(layout1_size, 0);
        layout2_size = @maximum(layout2_size, 0);

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
                this.handleSplitBarUpdate();
                split.layout1.update();
                split.layout2.update();
            },
            .border => |border| {
                border.child.update();
            }
        }
    }

    // The split bar can be hovered, pressed and then dragged.
    // It must still respect minimum sizes.
    fn handleSplitBarUpdate(this: *This) void {
        const split = &this.content.split;

        if (!split.moveable)
            return;

        const horiz = split.split_direction == .horizontal;
        const layout1_size = if(horiz) &split.layout1.height else &split.layout1.width;
        const layout2_size = if(horiz) &split.layout2.height else &split.layout2.width;
        const mx = ray.GetMouseX();
        const my = ray.GetMouseY();
        const mouse_pos = if (horiz) my else mx;
        if (this.isPointInLayout(mx, my)
                and !split.layout1.isPointInLayout(mx, my)
                and !split.layout2.isPointInLayout(mx, my)) {
            // Mouse cursor is on split bar
            if (ray.IsMouseButtonPressed(ray.MOUSE_LEFT_BUTTON)) {
                split.mouse_state = .pressed;
                split.drag_start = mouse_pos;
            }
            else if(ray.IsMouseButtonUp(ray.MOUSE_LEFT_BUTTON))
                split.mouse_state = .hover;
        }
        else if(split.mouse_state == .hover or ray.IsMouseButtonUp(ray.MOUSE_LEFT_BUTTON))
            split.mouse_state = .standby;

        // If we are pressing, and the mouse has moved
        if (split.mouse_state == .pressed and mouse_pos != split.drag_start) {
            const drag = mouse_pos - split.drag_start;
            const diff = if (drag < 0)
                @minimum(0, @maximum(drag, split.layout1_min_size-split.layout1.width))
                else
                @maximum(0, @minimum(drag, split.layout2.width-split.layout2_min_size));
            layout1_size.* += diff;
            if(horiz) split.layout2.y += diff else split.layout2.x += diff;
            layout2_size.* -= diff;
            split.drag_start += diff;

            // Update the desired split ratio since the user moved the bar
            split.layout1_desired_size_ratio = layout1_size.*;
            split.layout2_desired_size_ratio = layout2_size.*;

            split.layout1.recalculateLayout();
            split.layout2.recalculateLayout();
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
