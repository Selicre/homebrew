
#[bank(01)]
; TODO: generate this from an image, somehow
GFXLogo:
	incbin "gfx_logo.bin"
.end
	define GFXLogoSize .end-GFXLogo
GFXLogoPal:
	incbin "logo0.pal"
	incbin "logo1.pal"
.end
	define GFXLogoPalSize .end-GFXLogoPal

GFXLogoMap:
	incbin "map_logo.bin"
.end
	define GFXLogoMapSize .end-GFXLogoMap

GFXBG:
	incbin "../build/bg.gfx4"

MapBG:
	incbin "../build/bg.map"

GFXLevel:
	incbin "../build/level.gfx4"

PalLevel:
	incbin "../build/palette.pal"

GFXSprites:
	incbin "../build/sprites.gfx4"


BlockMappingsGrassy:
	incbin "../build/grassy.bdef"

BlockMappingsCave:
	incbin "../build/cave.bdef"
; Uncompressed for now.
incsrc "../build/chunks.asm"
