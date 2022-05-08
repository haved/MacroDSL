const std = @import("std");
const ray = @import("raylib");

// Takes the file names of vertex shader and fragment shader.
// If null, the default raylib shader is used for that stage.
fn Shader(vertex: ?[]const u8, fragment: ?[]const u8, variables: []const [:0]const u8) type {
    return struct {
        const This = @This();

        handle: ?ray.Shader = null,
        variable_locations: [variables.len]c_int = [_]c_int{0} ** variables.len,

        fn load(this: *This) !void {
            std.debug.assert(this.handle == null);

            const vertex_code = if (vertex) |vs| @embedFile(vs) else null;
            const fragment_code = if (fragment) |fs| @embedFile(fs) else null;

            const handle = ray.LoadShaderFromMemory(vertex_code, fragment_code);
            this.handle = handle;

            inline for (variables) |variable, i| {
                const loc = ray.GetShaderLocation(handle, variable);
                if (loc == -1)
                    return error.UnknownShaderUniform;
                this.variable_locations[i] = loc;
            }
        }

        fn unload(this: *This) void {
            ray.UnloadShader(this.handle orelse unreachable);
            this.handle = null;
        }

        pub fn bind(this: *This) void {
            ray.BeginShaderMode(this.handle orelse unreachable);
        }

        pub fn unbind(this: *This) void {
            _ = this;
            ray.EndShaderMode();
        }

        fn variableLocationFromName(comptime name: [:0]const u8) u32 {
            for (variables) |variable, i| {
                if (std.mem.eql(name, variable))
                    return i;
            }
            unreachable;
        }

        fn makeSetterFunction(T: type, uniform_type: c_int) fn (this: *This, comptime name: [:0]const u8, value: T) void {
            const typ = struct {
                fn func(this: *This, comptime name: [:0]const u8, value: T) void {
                    ray.SetShaderValue(
                        this.handle orelse unreachable,
                        variableLocationFromName(name),
                        &value,
                        uniform_type,
                    );
                }
            };
            return typ.func;
        }

        pub const setFloat = makeSetterFunction(f32, ray.SHADER_UNIFORM_FLOAT);
        pub const setVec2 = makeSetterFunction([2]f32, ray.SHADER_UNIFORM_VEC2);
        pub const setVec3 = makeSetterFunction([3]f32, ray.SHADER_UNIFORM_VEC3);
        pub const setVec4 = makeSetterFunction([4]f32, ray.SHADER_UNIFORM_VEC4);
        pub const setInt = makeSetterFunction(u32, ray.SHADER_UNIFORM_INT);
        pub const setIVec2 = makeSetterFunction([2]u32, ray.SHADER_UNIFORM_IVEC2);
        pub const setIVec3 = makeSetterFunction([3]u32, ray.SHADER_UNIFORM_IVEC3);
        pub const setIVec4 = makeSetterFunction([4]u32, ray.SHADER_UNIFORM_IVEC4);
        pub const setSampler2D = makeSetterFunction(c_int, ray.SHADER_UNIFORM_SAMPLER2D);
    };
}

pub var textGrid: Shader(null, "../glsl/textGrid.fs", &[_][:0]const u8{
    "backgroundColor",
    "foregroundColor",
    "gridSize",
    "cellSize",
}) = .{};

pub fn loadShaders() !void {
    try textGrid.load();
}

pub fn unloadShaders() void {
    textGrid.unload();
}
