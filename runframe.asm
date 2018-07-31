
; RunFrame: game loop driver
; Gamemode is a variable that determines what routine is currently active.
; To switch to a different gamemode, set the MSB and reset the stack pointer.
; To fade out, switch to gamemode GM_Fadeout and set the FadeoutTarget variable.
; Same for fading in, with GM_Fadein. Note that the init routine will not run again.

#[bank(00)]
RunFrame:
	REP #$30	; AXY 16-bit
	JSR ResetSprites
	JSL RunFrameTrampoline
	JSR FillSpritesEnd
	RTS

#[bank(02)]
RunFrameTrampoline:
	SEP #$10	; XY 8-bit
	LDX.b Gamemode
	REP #$30
	BPL +
	PHX
	JSR (GamemodeInitPtrs-$0080,x)
	PLA
	AND #$007F
	TAX
	STX.b Gamemode
+	JSR (GamemodePtrs,x)
	RTL

GamemodePtrs:
GMID_Logo:		dw GM_Logo
GMID_Movecam:	dw GM_Movecam
GMID_Level:		dw GM_Level

GamemodeInitPtrs:
	dw GMInit_Logo
	dw GMInit_Movecam
	dw GMInit_Level

GM_Level:
	RTS

GMInit_Level:
	RTS

incsrc "gamemodes/logo.asm"
incsrc "gamemodes/movecam.asm"
