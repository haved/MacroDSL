#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
// in vec4 fragColor;

uniform sampler2D texture0;
uniform vec4 backgroundColor;
uniform vec4 foregroundColor;
uniform vec2 gridSize; // The size of the rectangle we fill
uniform vec2 cellSize; // How large each cell is

// Output fragment color
out vec4 finalColor;

void main()
{
    vec2 cell = floor(gradTexCoord * gridSize / cellSize);
    finalColor = vec4(cell.x / 20, cell.y / 20, 0, 1);
}
