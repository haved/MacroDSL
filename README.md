
# MacroDSL

A tool for quickly editing text by interactivly defining macros and running them fast. Written in rust.
Can be built both for native and web. The interactive environment is rendered using OpenGL / WebGL.

## Structure
 - `macro-dsl`: The main library, including editor, language and editor rendering
 - `macro-dsl-native`: A native binary for opening the editor in a window
 - `macro-dsl-wasm`: A wasm target for opening the editor in a web page

## Resources used

 - [Rustwasm WebGL example](https://rustwasm.github.io/wasm-bindgen/examples/webgl.html)
 - [WebGL water tutorial rust](https://github.com/chinedufn/webgl-water-tutorial)

## Alternative to Rust: C++, SDL2 and Emscripten

 - [SDL2 Wiki > Installation #Emscripten](http://wiki.libsdl.org/Installation#emscripten) and the docs linked to from there
 - [Emscripten > Optimizing WebGL #Which GL Mode To Target](https://emscripten.org/docs/optimizing/Optimizing-WebGL.html#which-gl-mode-to-target)
 - [Emscripten + SDL2 + OpenGL ES 2](https://erik-larsen.github.io/emscripten-sdl2-ogles2/) a tutorial for getting things on screen

