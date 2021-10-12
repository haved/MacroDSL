# Possible optimizations that might even make the program faster

I'm trying to not do most clever optimizations until after I can acutally
profile them and meassure benefits.

## Text data structure
Lots of things to consider here.
There is also a difference between making single editing operations,
which should all be fast, and running a program.

### Ideal node size
What is the best size?

### Allocating virtual memory pages?
Instead of making increasingly large arenas,
what if we just set aside 16GB of virtual address space?

#### Not using full 64-bit pointers to nodes
If the nodes are all in the same area, smaller indexes could be used

### Letting internal nodes have dirty child sizes
As long as the child and parent always agree about the "dirty" state,
the child can update its size without having to pay its parent a visit.
This becomes a bit more problematic with parent's parent. Dirty all the way up.

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

