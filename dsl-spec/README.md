## DSL specification

This folder is for the definition of the macro langauge that will be front and center in the editor.
It has a few goals:
 - Be automatically writeable from recoring key commands
  - Macros should be called as they are declared
 - Also be writeable by hand
 - Compiled, type safe and fast
  - Tail call optimization yess
 - Compact for text editing commands
  - Easy repeated commands
  - Nice string literals
   - Ability to hide very long string literals (?)
   - Refer to string literals by name, have a nice map somewhere :)
 - Pattern-matchy searching
 
### General idea

```
def buffer = Buffer(content=""input1"")
def marker = buffer.Marker(line=1,col=0)
use marker



macro 

```

