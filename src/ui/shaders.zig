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
            errdefer this.unload();

            this.bind();

            inline for (variables) |variable, i| {
                const loc = ray.GetShaderLocation(handle, variable);
                // If the uniform is not found, or not used in the shader, we get -1
                // raylib already gives a warning about this, no need to crash and burn
                this.variable_locations[i] = loc;
            }
        }

        fn unload(this: *This) void {
            if (this.handle) |handle| {
                ray.UnloadShader(handle);
                this.handle = null;
            }
        }

        pub fn bind(this: *This) void {
            ray.BeginShaderMode(this.handle orelse unreachable);
        }

        pub fn unbind(this: *This) void {
            _ = this;
            ray.EndShaderMode();
        }

        fn variableIndexFromName(comptime name: [:0]const u8) usize {
            for (variables) |variable, i| {
                if (std.mem.eql(u8, name, variable))
                    return i;
            }
            unreachable;
        }

        fn makeSetterFunction(comptime T: type, uniform_type: c_int) type {
            return struct {
                fn invoke(this: *This, comptime name: [:0]const u8, value: T) void {
                    ray.SetShaderValue(
                        this.handle orelse unreachable,
                        this.variable_locations[variableIndexFromName(name)],
                        &value,
                        uniform_type,
                    );
                }
            };
        }

        pub const setFloat = makeSetterFunction(f32, ray.SHADER_UNIFORM_FLOAT).invoke;
        pub const setVec2 = makeSetterFunction([2]f32, ray.SHADER_UNIFORM_VEC2).invoke;
        pub const setVec3 = makeSetterFunction([3]f32, ray.SHADER_UNIFORM_VEC3).invoke;
        pub const setVec4 = makeSetterFunction([4]f32, ray.SHADER_UNIFORM_VEC4).invoke;
        pub const setInt = makeSetterFunction(u32, ray.SHADER_UNIFORM_INT).invoke;
        pub const setIVec2 = makeSetterFunction([2]u32, ray.SHADER_UNIFORM_IVEC2).invoke;
        pub const setIVec3 = makeSetterFunction([3]u32, ray.SHADER_UNIFORM_IVEC3).invoke;
        pub const setIVec4 = makeSetterFunction([4]u32, ray.SHADER_UNIFORM_IVEC4).invoke;
        pub const setSampler2D = makeSetterFunction(c_int, ray.SHADER_UNIFORM_SAMPLER2D).invoke;
    };
}

pub var textGrid: Shader("../glsl/textGrid.vs", "../glsl/textGrid.fs", &[_][:0]const u8{
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
