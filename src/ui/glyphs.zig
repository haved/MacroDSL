pub const default_glyphs = generate_default_glyphs().glyphs;

// Creates a c_int array containing the codepoints for all default glyphs
fn generate_default_glyphs() type {
    comptime var glyphs: [101]c_int = undefined;

    var i: usize = 0;
    while (i < 95) : (i += 1) {
        glyphs[i] = @intCast(c_int, ' ' + i);
    }
    glyphs[95] = 'æ';
    glyphs[96] = 'ø';
    glyphs[97] = 'å';
    glyphs[98] = 'Æ';
    glyphs[99] = 'Ø';
    glyphs[100] = 'Å';

    return struct {
        pub const glyphs = glyphs;
    };
}
