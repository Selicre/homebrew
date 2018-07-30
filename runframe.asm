
RunFrame:
	REP #$30	; AXY 16-bit
	JSR ResetSprites
	LDA.b Gamemode
	AND #$00FF
	TAX
	JSR (GamemodePtrs,x)
	JSR FillSpritesEnd
	RTS

GamemodePtrs:
	dw GM_Movecam
	dw GM_Level

GM_Level:
	RTS

incsrc "gamemodes/movecam.asm"
