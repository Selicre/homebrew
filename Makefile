
ASM=/home/x10a94/Projects/Rust/piped-asm/target/release/piped
PALGEN=/home/x10a94/Projects/Rust/snesgfx/target/release/rsgfx pal
GFX2GEN=/home/x10a94/Projects/Rust/snesgfx/target/release/rsgfx gfx2
GFX4GEN=/home/x10a94/Projects/Rust/snesgfx/target/release/rsgfx gfx4

OUTPUT=build/out.sfc

SOURCE=$(shell find src)

PAL_FILES=$(patsubst palettes/%.png,build/%.pal, $(wildcard palettes/*.png))
GFX4_FILES=$(patsubst graphics/4/%.png,build/%.gfx4, $(wildcard graphics/4/*.png))


$(OUTPUT): $(PAL_FILES) $(GFX4_FILES) $(SOURCE)
	cd src; \
	$(ASM) main.asm ../$(OUTPUT)

build/%.pal: palettes/%.png
	$(PALGEN) $< $@

build/%.gfx4: graphics/4/%.png
	$(GFX4GEN) $< $@

clean:
	rm build/*
