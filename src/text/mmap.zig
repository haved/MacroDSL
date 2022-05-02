const mman = @cImport(@cInclude("sys/mman.h"));
const unistd = @cImport(@cInclude("unistd.h"));

pub const mmap = mman.mmap;
pub const munmap = mman.munmap;
pub fn getPageSize() usize {
    return unistd.sysconf(unistd._SC_PAGESIZE);
}
