
pub fn always(ok: bool) void {
    if(!ok) @panic("always_assert assertion failed");
}

pub const debug = @import("std").debug.assert;
