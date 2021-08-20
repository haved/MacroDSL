use beryllium::*;
use gl33::*;

fn main() {
    let sdl = SDL::init(InitFlags::Everything).expect("couldn't start SDL");
    sdl.gl_set_attribute(SdlGlAttr::MajorVersion, 3).unwrap();
    sdl.gl_set_attribute(SdlGlAttr::MinorVersion, 3).unwrap();
    sdl.gl_set_attribute(SdlGlAttr::Profile, GlProfile::Core)
        .unwrap();
    #[cfg(target_os = "macos")]
    {
        sdl.gl_set_attribute(SdlGlAttr::Flags, ContextFlag::ForwardCompatible)
            .unwrap();
    }
    let win = sdl
        .create_gl_window(
            "Hello Window",
            WindowPosition::Centered,
            800,
            600,
            WindowFlags::Shown,
        )
        .expect("couldn't make a window and context");

    unsafe {
        let gl =
            GlFns::load_from(&|c_char_ptr| win.get_proc_address(c_char_ptr as *const i8)).unwrap();
        gl.ClearColor(0.2, 0.3, 0.3, 1.0);

        'main_loop: loop {
            while let Some(event) = sdl.poll_events().and_then(Result::ok) {
                match event {
                    Event::Quit(_) => break 'main_loop,
                    _ => (),
                }
            }

            win.swap_window();
        }
    }
}
