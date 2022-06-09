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

        fn variableLocationFromName(comptime name: [:0]const u8) u32 {
            for (variables) |variable, i| {
                if (std.mem.eql(name, variable))
                    return i;
            }
            unreachable;
        }

        pub fn setUniform(this: *This, comptime name: [:0]const u8, comptime T: type, value: T) void {
            ray.SetShaderValue(
                this.handle orelse unreachable,
                variableLocationFromName(name),
                &value,
                comptime switch (T) {
                    .Float => ray.SHADER_UNIFORM_FLOAT,
                    .Integer => ray.SHADER_UNIFORM_INT,
                    .Array => |array| switch (array.child) {
                        .Float => switch (array.len) {
                            2 => ray.SHADER_UNIFORM_VEC2,
                            3 => ray.SHADER_UNIFORM_VEC3,
                            4 => ray.SHADER_UNIFORM_VEC4,
                        },
                        .Integer => switch (array.len) {
                            2 => ray.SHADER_UNIFORM_IVEC2,
                            3 => ray.SHADER_UNIFORM_IVEC3,
                            4 => ray.SHADER_UNIFORM_IVEC4,
                        },
                    },
                },
            );
        }

        pub fn setSampler2D(comptime name: [:0]const u8, texture: c_int) void {
            ray.SetShaderValue(
                this.handle orelse unreachable,
                variableLocationFromName(name),
                &texture,
                ray.SHADER_UNIFORM_SAMPLE2D,
            );
        }
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
