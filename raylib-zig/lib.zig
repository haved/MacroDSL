const std = @import("std");
const Builder = std.build.Builder;
const LibExeObjStep = std.build.LibExeObjStep;

pub fn Pkg(pkgdir: []const u8) type {
    return struct {
        pub fn link(exe: *LibExeObjStep, system_lib: bool) void {
            if (!system_lib) {
                exe.addLibPath(pkgdir ++ "/raylib/src");
                exe.addIncludeDir(pkgdir ++ "/raylib/src");
            }

            // This switch is stolen from raylib/src/build.zig
            switch (exe.target.toTarget().os.tag) {
                .windows => {
                    exe.linkSystemLibrary("winmm");
                    exe.linkSystemLibrary("gdi32");
                    exe.linkSystemLibrary("opengl32");
                },
                .linux => {
                    exe.linkSystemLibrary("GL");
                    exe.linkSystemLibrary("rt");
                    exe.linkSystemLibrary("dl");
                    exe.linkSystemLibrary("m");
                    exe.linkSystemLibrary("X11");
                },
                else => {
                    @panic("Unsupported OS");
                },
            }

            exe.linkSystemLibrary("raylib");
            exe.linkLibC();

            exe.addPackagePath("raylib", pkgdir ++ "/lib/raylib-zig.zig");
            exe.addPackagePath("rlgl", pkgdir ++ "/lib/rlgl-zig.zig");
            exe.addPackagePath("raylib-math", pkgdir ++ "/lib/raylib-zig-math.zig");
        }
    };
}
