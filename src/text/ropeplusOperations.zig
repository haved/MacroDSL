const std = @import("std");

/// A collection of text operations on the rope plus structure.
/// Methods for working with nodes are defined in the RopePlus struct itself.
pub fn RopePlusOperations(RopePlus: type) type {
    return struct {
        pub fn append_to_end(rope: *RopePlus, bytes: []u8) !void {

        }

        pub fn read_into_linear_buffer(rope: *RopePlus, offset: usize, target: []u8) usize {

        }
    };
}
