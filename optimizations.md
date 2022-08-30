# Possible optimizations that might even make the program faster

I'm trying to not do most clever optimizations until after I can acutally
profile them and measure benefits.

## Text data structure
Lots of things to consider here.
There is also a difference between making single editing operations,
which should all be fast, and running a program.

### Ideal node size
What is the best size? Maybe its even ideal to avoid multiples of 64 bytes, to spread hits over cache sets.

#### Letting internal and leaf nodes have different size
Maybe e.g. internal should only be 128 bytes?

### Allocating virtual memory pages?
Instead of making increasingly large arenas,
what if we just set aside 16GB of virtual address space?
Will not work for WebAssembly.

#### Not using full 64-bit pointers to nodes
If the nodes are all in the same area, smaller indexes could be used

### Should the down pointers contain child size?
A classic B+-tree has some sort of key for each child pointer.
I was thinking number of text bytes in subtree.
We could instead get the data from the child when needed.
This might be better, since we can do less updates when changing leaf nodes.
Profiling! Cachegrind!

### Letting internal nodes have dirty child sizes
As long as the child and parent always agree about the "dirty" state,
the child can update its size without having to pay its parent a visit.
This becomes a bit more problematic with parent's parent. Dirty all the way up.

Actually this isn't all that bad. A leaf node must always know its byte size,
but the size copy in the internal nodes can be set to sentinel values.
If any of an internal nodes children is such a sentinel, the internal node itself gets a sentinel size.

### How should leaf nodes be split?
Probably not in the middle

### Adding bulk leaf nodes without splitting
If we are adding a block of text,
we can know that we need at least n new leaf nodes.

### Keeping track of newlines
If we keep this data in internal nodes,
we can get line number in O(log n) time.

## Rendering optimizations

### Knowing when the buffer has changed
It would be nice to only update the atlas and texture
if we know that the buffer has changed.
Even if an area we arent looking at has changed,
changes can still affect line numbers

## Architecture changes
Could we separate rendering and text work threads?
I guess we have to when we start executing code?
I don't think making the Rope+ thread-safe is
going to give any perforance benefits.
Keep the entire thing behind a mutex?

## Cool things for the language to do
The entire point is to have a fast language, so here are some things the compiler can do to skip as much work as possible

### Enter long strands of text in bulk
If we have several commands that all input text, then we can compile those commands together, or have a buffer.
This buffer can't be unbounded, but we want to avoid `if buffer_full then flush_buffer() end` before every insertion,
so the compiler can block together code that has a know maximum number of additions, and then do fewer checks of remaining space.

### Delete long strands of text in bulk
If we remove things, both from before and after the cursor, those deletions can be postponed until we actaully start moving the cursor.

### Combine add-buffer and delete-buffering
If we first delete 10 chars, then add 20 chars, they should "cancel out" into a single replace 10, and a single add 10 in the final data structure.
