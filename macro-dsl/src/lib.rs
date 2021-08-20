
pub struct Marker {
    pos: u32
}

pub struct Buffer {
    name: String,
    content: String,
    markers: Vec<Marker>
}

impl Buffer {
    pub fn new(name: &str, content: &str) -> Self {
        Self {
            name: String::from(name),
            content: String::from(content),
            markers: vec!()
        }
    }
}

pub struct Window {
    buffer_index: u32,
    marker_index: u32,
    twin_marker_index: Option<u32>
}

impl Window {
    pub fn new(buffer_index: u32, marker_index: u32) -> Self {
        Self {
            buffer_index,
            marker_index,
            twin_marker_index: None
        }
    }
}

pub struct MacroDSLEnvironment {
    buffers: Vec<Buffer>,
    windows: Vec<Window>,
    macro_editor: Buffer,
    width: u32,
    height: u32
}

impl MacroDSLEnvironment {
    pub fn new() -> Self {
        Self {
            buffers: vec!(Buffer::new("Main Buffer", "This is the editor")),
            windows: vec!(Window::new(0, 0)),
            macro_editor: Buffer::new("Macro", "# Your macro gets written here"),
            width: 0, height: 0
        }
    }

    pub fn render(&mut self) {

    }

    pub fn resize(&mut self, width: u32, height: u32) {
        self.width = width;
        self.height = height;
    }
}
