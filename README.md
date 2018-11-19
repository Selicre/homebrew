# Yet-to-be-named homebrew game engine

This is a small SNES game base. It has an embedded tilemap renderer, sprite system and a lot of other things.

# Building

To build this, you'll need [snesgfx](https://hyper.is-a.cat/gogs/x10A94/snesgfx/), [tiled](https://hyper.is-a.cat/gogs/x10A94/tiled/) and [piped-asm](https://github.com/x10A94/piped-asm). You'll need to modify the Makefile and the rsutils' manifest to adjust where they are on your system.

To just build the output ROM, use `mkdir build; make`.
To make intermediate files for editing in Tiled, use `mkdir build; make render_tiles; make render_blockdefs`.

## Tilemap renderer

The chunk format is one byte per block, with metadata, which contains two pointers to block mappings. If the MSB of the block byte is set, it's pulled from the second pointer rather than the first one. The block mappings format is interlaced and contains all top left corner data first (`$100` bytes), then top right, etc.

## Editing

Levels are stored in the Tiled JSON format. Reloading the graphics and palette is up to the engine as of right now, but in the future it can be done using triggers within the chunk. The build script will automatically determine which block mappings to use, and in the future it would even be able to automatically generate block mappings from a single big set.
