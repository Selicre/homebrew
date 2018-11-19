
ASM=deps/piped-asm/target/release/piped
SNESGFX=deps/snesgfx/target/release/rsgfx

PALGEN=$(SNESGFX) pal
GFX2GEN=$(SNESGFX) gfx2
GFX4GEN=$(SNESGFX) gfx4
EXTSPGEN=$(SNESGFX) extsp
RSUTILS=cargo run --manifest-path=rsutils/Cargo.toml --
TMAPGEN=$(RSUTILS) tilemap
BDEFGEN=$(RSUTILS) blockdefs
CHUNKGEN=$(RSUTILS) chunks

OUTPUT=build/out.sfc

SOURCE=$(shell find src)

PAL_FILES=$(patsubst palettes/%.png,build/%.pal, $(wildcard palettes/*.png))
GFX4_FILES=$(patsubst graphics/4/%.png,build/%.gfx4, $(wildcard graphics/4/*.png))
BDEF_FILES=$(patsubst mappings/blockdefs/%.json,build/%.bdef, $(wildcard mappings/blockdefs/*.json))
TMAP_FILES=$(patsubst mappings/tilemaps/%.json,build/%.map, $(wildcard mappings/tilemaps/*.json))
WORLDMAP=worldmap.json

$(OUTPUT): $(PAL_FILES) $(GFX4_FILES) $(BDEF_FILES) $(TMAP_FILES) build/chunks.asm $(SOURCE)
	cd src; \
	../$(ASM) main.asm ../$(OUTPUT)

build/chunks.asm: worldmap.json
	$(RSUTILS) chunks $< $@

build/%.bdef build/%.bdef.png: mappings/blockdefs/%.json
	$(BDEFGEN) $< $@
build/%.bdef.png: build/%.bdef

render_blockdefs: $(BDEF_FILES)


render_tiles: tiles_bg.png tiles.png
tiles_bg.png: build/bg.gfx4 build/palette.pal
	$(EXTSPGEN) build/bg.gfx4 build/palette.pal tiles_bg.png
tiles.png: build/level.gfx4 build/palette.pal
	$(EXTSPGEN) build/level.gfx4 build/palette.pal tiles.png

build/%.map: mappings/tilemaps/%.json
	$(TMAPGEN) $< $@

build/%.pal: palettes/%.png
	$(PALGEN) $< $@

build/%.gfx4: graphics/4/%.png
	$(GFX4GEN) $< $@

clean:
	rm build/*
