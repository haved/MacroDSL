const std = @import("std");
const c = @cImport({
    @cInclude("sys/mman.h");
    @cInclude("unistd.h");
    @cInclude("error.h");
    @cInclude("errno.h");
});

comptime {
    // We rely on one byte being 8 bits, portability be damned!
    std.debug.assert(std.mem.byte_size_in_bits == 8);
}

/// Gets the page size of the system at runtime, only performs the syscall once
pub fn getPageSize() usize {
    const static = struct {
        var page_size: ?usize = null;
    };
    if (static.page_size) |size| return size;

    // @cold(); // Once Zig issue #5177 is done
    static.page_size = @intCast(usize, c.sysconf(c._SC_PAGESIZE));
    return static.page_size.?;
}

/// Takes a number of bytes and rounds it up to the nearest whole number of pages
pub inline fn roundUpToPageSize(size: usize) usize {
    const page_size = getPageSize();
    return size + page_size - 1 - @mod(size + page_size - 1, page_size);
}

/// Sets aside =size= bytes of continous virtual memory, or rounds up to nearest page boundry
/// Only the first =useable= bytes will be writable, more can be requested using makeUseable()
pub fn preallocateRegion(size: usize, useable: usize) ![]u8 {
    // Round size up to nearest whole number of pages
    const actual_size = roundUpToPageSize(size);

    // mmap region of PROT_NONE, meaning we don't take up any physical memory
    const mmap_result = c.mmap(null, actual_size, c.PROT_NONE, c.MAP_PRIVATE | c.MAP_ANONYMOUS, -1, 0);
    if (mmap_result == c.MAP_FAILED) return error.OutOfVirtualMemory;

    errdefer {} //TODO: Unmap

    // Convert the c pointer to a Zig slice;
    const result: []u8 = @ptrCast([*]u8, mmap_result)[0..actual_size];

    // Access to the memory is PROT_NONE, and will page fault. Make the first =usable= bytes usable
    try makeUseable(result, 0, useable);

    return result;
}

/// Changes the protections on a memory mapped region to make more or less pages useable
/// Takes in the previous useable region, to only update pages with changed state
pub fn makeUseable(region: []u8, previousUseable: usize, newUseable: usize) !void {
    const previous_actual = roundUpToPageSize(previousUseable);
    const new_actual = roundUpToPageSize(newUseable);

    if (new_actual > region.len) return error.IndexOutOfBounds;

    var mprotect_result: c_int = 0;
    if (new_actual > previous_actual) { // Grow writable region
        mprotect_result = c.mprotect(
            @intToPtr(*u8, @ptrToInt(&region[0]) + previous_actual),
            new_actual - previous_actual,
            c.PROT_READ | c.PROT_WRITE,
        );
    } else if (new_actual < previous_actual) { // Shrink writable region
        mprotect_result = c.mprotect(
            @intToPtr(*u8, @ptrToInt(&region[0]) + new_actual),
            previous_actual - new_actual,
            c.PROT_NONE,
        );
    }

    if (mprotect_result != 0) {
        // Some errors are due to lack of memory, those should be handled
        const errno = c.__errno_location().*;
        if (errno == c.EAGAIN or errno == c.ENOMEM)
            return error.OutOfMemory;

        // Other errors are reason to abort
        c.@"error"(-1, errno, "mprotect failed");
        unreachable;
    }
}

// A silly little test, since zig test can't perform the real syscalls
// pub fn main() !void {
//     const region = try preallocateRegion(4 * 1024 * 1024, 4000);
//     try std.testing.expect(region.len == 4 * 1024 * 1024);
//     var i: usize = 0;
//     while (i < 4096) : (i += 1) {
//         region[i] = @intCast(u8, i % 256);
//     }
//     try makeUseable(region, 4000, 8000);
//     while (i < 8192) : (i += 1) {
//         region[i] = @intCast(u8, i % 256);
//     }
//     try makeUseable(region, 8000, 4000);
//     try std.testing.expectError(
//         error.IndexOutOfBounds,
//         makeUseable(region, 4000, 4 * 1024 * 1024 + 1),
//     );
// }
