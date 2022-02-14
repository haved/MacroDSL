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

Here is an example, which could be used to turn

```html
<div class="figure">
<img src="example.com/uploads/images/cat.jpg" class="" style="max-width: 500px">
Lorem ipsum
Dolor sit amet
</div>

This text I actually care about

<div class="table-holder">
This div should be left alone
</div>

<div class="figure">
<img src="example.com/uploads/images/dog.jpg" class="">
Some other text
</div>
```
into
```markdown 
{{< figure src="/cat.jpg" width="500">}}
Lorem ipsum
Dolor sit amet
{{< /figure >}}

This text I actually care about

<div class="table-holder">
This div should be left alone
</div>

{{< figure src="/dog.jpg">}}
Some other text
{{< /figure >}}
```

```
def buffer = Buffer(content=#"input"#);
current = buffer.Marker(line=1,col=0);

macro replace_div_figure {
    macro find_div_figure {
        let start = search "<div" | .first;
        first 
            "class=" => {2x f},
            ">" => {find_div_figure};
        first
            "figure" => {}
            '"' => {find_div_figure}
        
        current = start;
        search 'src=';
        f;
        let src_end = search '"' | .before;
        let src_begin = rsearch "/";
        let src = src_begin.substring(src_end);
    }
    
    
}
20x macro1

```

