#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0; // Each pixel contains the atlas row and col for the glyph
uniform sampler2D fontAtlas;

uniform vec4 backgroundColor;
uniform vec4 foregroundColor;
uniform ivec2 cellSize; // How large each cell is

// Output fragment color
out vec4 finalColor;

void main()
{
    // Get the pixel in the window
    ivec2 pixel = ivec2(fragTexCoord);
    // Calculate which cell that is in
    ivec2 cell = pixel / cellSize;
    // The offset inside the cell, in pixels
    ivec2 in_cell = pixel % cellSize;

    // Find which glyph belongs in this cell
    ivec2 glyph = ivec2 (texelFetch(texture0, cell, 0).xy * 255);
    // Position in font atlas, in UV space
    ivec2 fontatlas_pos = (glyph * cellSize + in_cell);
    vec3 glyph_color = texelFetch(fontAtlas, fontatlas_pos, 0).xyz;
    finalColor = vec4(glyph_color, 1);
}
