# Raylib-zig
This is an extremely stripped down version of Not-Nik's [raylib-zig](https://github.com/Not-Nik/raylib-zig).
It imports the C header from raylib directly.

It also expects you to init the submodule and build the library yourself:
``` sh
git submodule update --init
cd raylib/src
zig build
```

