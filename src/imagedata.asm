
#[bank(01)]
GFXLogo:
	incbin "gfx_logo.bin"
.end
	define GFXLogoSize .end - GFXLogo
GFXLogoPal:
	incbin "logo0.pal"
	incbin "logo1.pal"
.end
	define GFXLogoPalSize .end-GFXLogoPal

GFXLogoMap:
	incbin "map_logo.bin"
.end
	define GFXLogoMapSize .end-GFXLogoMap



GFXLevel:
	incbin "gfx_level.bin"

GFXLevelMap:
	incbin "map_level.bin"
	incbin "map_bg.bin"

GFXLevelPal:
	incbin "../build/palette.pal"


BlockMappings:
	; Fun thing: it only has 2 at the end because my hex editor threw
	; a really fucking obscure error whenever it tried to save it to the
	; previous filename. I'll rename it when I'm gonna be building this
	; from a json file anyway
	incbin "block_mappings2.bin"

; Uncompressed for now.
Chunks0123:
	incbin "chunks0123.bin"
