const raylib = @import("raylib");
const rlgl = @import("rlgl");

pub fn texturedRectangle(ix: i32, iy: i32, iwidth: i32, iheight: i32, color: raylib.Color) void {
    const x = @intToFloat(f32, ix);
    const y = @intToFloat(f32, iy);
    const w = @intToFloat(f32, iwidth);
    const h = @intToFloat(f32, iheight);
    texturedRectangleF(x, y, w, h, color);
}

pub fn texturedRectangleF(x: f32, y: f32, width: f32, height: f32, color: raylib.Color) void {
    rlgl.rlBegin(rlgl.RL_QUADS);
    rlgl.rlNormal3f(0.0, 0.0, 1.0);
    rlgl.rlColor4ub(color.r, color.g, color.b, color.a);

    rlgl.rlTexCoord2f(0.0, 0.0);
    rlgl.rlVertex2f(x, y);
    rlgl.rlTexCoord2f(0.0, 1.0);
    rlgl.rlVertex2f(x, y + height);
    rlgl.rlTexCoord2f(1.0, 1.0);
    rlgl.rlVertex2f(x + width, y + height);
    rlgl.rlTexCoord2f(1.0, 0.0);
    rlgl.rlVertex2f(x + width, y);

    rlgl.rlEnd();
}
