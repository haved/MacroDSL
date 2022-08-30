
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

 - [Raylib](https://www.raylib.com/index.html)
 
About memory, cache and speed:
 - [Algorithms for Modern Hardware](https://en.algorithmica.org/hpc/cpu-cache) - Especially chapter about [RAM & CPU Caches](https://en.algorithmica.org/hpc/cpu-cache/) 
 - [Gallery Of Processor Cache Effects](http://igoro.com/archive/gallery-of-processor-cache-effects)
 - [Measuring and Reducing CPU Usage in SQLite](https://www.sqlite.org/draft/cpu.html)
