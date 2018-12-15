
; RunFrame: game loop driver
; Gamemode is a variable that determines what routine is currently active.
; To switch to a different gamemode, set the MSB and reset the stack pointer.
; To fade out, switch to gamemode GM_Fadeout and set the FadeoutTarget variable.
; Same for fading in, with GM_Fadein. Note that the init routine will not run again.

#[bank(00)]
RunFrame:
	SEP #$30	; AXY 8-bit
	LDA.b #$40	; RTI
	STA.b NMIVector
	REP #$30	; AXY 16-bit
	JSR ResetSprites
	JSL RunFrameTrampoline
	JSR FillSpritesEnd
	JSL ScanlineProfiler
	SEP #$30	; AXY 8-bit
	LDA.b #$5C	; JML
	STA.b NMIVector
	; loop infinitely to wait for interrupts
-	WAI
	BRA -



#[bank(02)]
RunFrameTrampoline:
	SEP #$10	; XY 8-bit
	LDX.b Gamemode
	REP #$30
	JSR (GamemodePtrs,x)
	RTL

GamemodePtrs:
GMID_LogoInit:		dw GM_LogoInit
GMID_Logo:			dw GM_Logo
;GMID_MovecamInit:	dw GM_MovecamInit
;GMID_Movecam:		dw GM_Movecam
GMID_LevelInit:		dw GM_LevelInit
GMID_Level:			dw GM_Level
GMID_Fadein:		dw GM_Fadein
GMID_Fadeout:		dw GM_Fadeout


incsrc "gamemodes/logo.asm"
incsrc "gamemodes/movecam.asm"
incsrc "gamemodes/fade.asm"


ScanlineProfiler:
	; TODO: decompression queue
	SEP #$20	; A 8-bit
	LDA.w SLHV
	LDA.w STAT78	; reset to low byte
	LDA.w OPVCT
	XBA
	LDA.w OPVCT
	XBA
	REP #$20	; A 16-bit
	AND.w #$01FF
	STA.b SysLoad
	SEP #$20	; A 8-bit
	LDA.w OPHCT
	XBA
	LDA.w OPHCT
	XBA
	REP #$20	; A 16-bit
	AND.w #$01FF
	STA.b SysLoadLo
	RTL
