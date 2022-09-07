const ray = @import("raylib");
const rlgl = @import("rlgl");

// Draws the
pub fn texturePart(ix: i32, iy: i32, iwidth: i32, iheight: i32, texture: ray.Texture, color: ray.Color) void {
    const x = @intToFloat(f32, ix);
    const y = @intToFloat(f32, iy);
    const w = @intToFloat(f32, iwidth);
    const h = @intToFloat(f32, iheight);
    texturePartF(x, y, w, h, texture, color);
}

pub fn texturePartF(x: f32, y: f32, width: f32, height: f32, texture: ray.Texture, color: ray.Color) void {
    _ = rlgl.rlCheckRenderBatchLimit(4);

    rlgl.rlSetTexture(texture.id);
    rlgl.rlBegin(rlgl.RL_QUADS);
    rlgl.rlNormal3f(0.0, 0.0, 1.0); // Normal vector pointing towards viewer
    rlgl.rlColor4ub(color.r, color.g, color.b, color.a);

    rlgl.rlTexCoord2f(0.0, 0.0);
    rlgl.rlVertex2f(x, y);
    rlgl.rlTexCoord2f(0.0, height);
    rlgl.rlVertex2f(x, y + height);
    rlgl.rlTexCoord2f(width, height);
    rlgl.rlVertex2f(x + width, y + height);
    rlgl.rlTexCoord2f(width, 0.0);
    rlgl.rlVertex2f(x + width, y);

    rlgl.rlEnd();
}
