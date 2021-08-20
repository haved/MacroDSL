
pub struct Editor {
    name: String,
    content: String
}

pub struct MacroDSLEnvironment {
    editor: Editor,
    macro_editor: Editor
}

impl Editor {
    pub fn new(name: &str, content: &str) -> Self {
        Self {
            name: String::from(name),
            content: String::from(content)
        }
    }
}

impl MacroDSLEnvironment {
    pub fn new() -> Self {
        Self {
            editor: Editor::new("Main Buffer", "This is the editor"),
            macro_editor: Editor::new("Macro", "# Your macro gets written here")
        }
    }
}
