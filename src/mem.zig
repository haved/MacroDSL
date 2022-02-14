/// A simple wrapper, used to indicate to the programmer that the struct owns the memory pointed to
pub fn Own(comptime T: type) type {
    return *T;
}
