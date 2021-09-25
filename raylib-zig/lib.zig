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

            exe.linkSystemLibrary("raylib");
            exe.linkLibC();

            exe.addPackagePath("raylib", pkgdir ++ "/lib/raylib-zig.zig");
            exe.addPackagePath("raylib-math", pkgdir ++ "/lib/raylib-zig-math.zig");
        }
    };
}
