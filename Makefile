
ASM=/home/x10a94/Projects/Rust/piped-asm/target/release/piped-asm
PALGEN=/home/x10a94/Projects/Rust/snesgfx/target/release/rsgfx pal

OUTPUT=build/out.sfc

SOURCE=$(shell find src)

PAL_FILES=$(patsubst palettes/%.png,build/%.pal, $(wildcard palettes/*.png))


$(OUTPUT): $(PAL_FILES) $(SOURCE)
	mkdir -p build
	cd src; \
	$(ASM) main.asm ../$(OUTPUT)

build/%.pal: palettes/%.png
	$(PALGEN) $< $@

clean:
	rm build/*


