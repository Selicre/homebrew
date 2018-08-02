# Yet-to-be-named homebrew game engine

This is a small SNES game base. It has an embedded tilemap renderer, sprite system and a lot of other things.

## Tilemap renderer

The chunk format is one byte per block, with metadata, which contains two pointers to block mappings. If the MSB of the block byte is set, it's pulled from the second pointer rather than the first one. The block mappings format is interlaced and contains all top left corner data first (`$100` bytes), then top right, etc.
