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
pub fn preallocateRegion(size: usize) ![]u8 {
    // Round size up to nearest whole number of pages
    const actual_size = roundUpToPageSize(size);

    const mmap_result = c.mmap(
        null,
        actual_size,
        c.PROT_WRITE | c.PROT_READ,
        c.MAP_PRIVATE | c.MAP_ANONYMOUS,
        -1,
        0,
    );
    if (mmap_result == c.MAP_FAILED) return error.OutOfVirtualMemory;

    // Convert the c pointer to a Zig slice
    const result: []u8 = @ptrCast([*]u8, mmap_result)[0..actual_size];

    return result;
}

/// Give the virtual address region back
pub fn freeRegion(region: []u8) void {
    const munmap_result = c.munmap(&region[0], region.len);
    if (munmap_result != 0) {
        const errno = c.__errno_location().*;
        c.@"error"(-1, errno, "munmap failed");
        unreachable;
    }
}
