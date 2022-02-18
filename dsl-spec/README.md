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
let buffer = Buffer(content=#"input");
current = buffer.Marker(line=1,col=0);

macro replace_div_figure {
    let start =
    macro find_div_figure {
        let start = search "<div" => it.first;
        search {
            "class=" => 2x f,
            ">" => return find_div_figure
        };
        search {
            "figure",
            '"' => return find_div_figure
        };
        
        return start;
    };
    
    current = start;
    
    search 'src='; f;
    let src_end = search '"' => it.first;
    let src_begin = rsearch "/" => it.after;
    let src: String = substring src_begin src_end;
    
    current = start;
    mut width: ?String = null;
    search {
        /max-width: ([0-9]+)?/ => width = it.0,
        "/div>" => current = it.first };
        
    search "/div>";
    delete(start, current);
    
    write('{{< figure src="$src"');
    if (width != null)
        write(' width="$width"');
    write(" >}}");
    
    search "</div>" => delete(it);
    write("{{< /figure >}}");
};
20x macro1;

```

