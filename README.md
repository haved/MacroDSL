
# MacroDSL

A text editor with interactive macro creation and execution. Made to be fast.

## Dependencies

 - Zig
 - Raylib (vendored)
 
On Arch Linux you can install zig from pacman, run
```sh
sudo pacman -S zig
```

To build raylib, make sure you have the submodule

``` sh
git submodule update --init
cd raylib-zig/raylib/src
zig build
```

## Building native binaries

``` sh
zig build

# to run
zig build run
```

## References

 - [learnzig.org](https://ziglearn.org/)
 - [Raylib](https://www.raylib.com/index.html)
 - [Tetris in Zig and WebGL](https://github.com/raulgrell/tetris)
