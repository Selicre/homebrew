
; RunFrame: game loop driver
; Gamemode is a variable that determines what routine is currently active.
; To switch to a different gamemode, set the MSB and reset the stack pointer.
; To fade out, switch to gamemode GM_Fadeout and set the FadeoutTarget variable.
; Same for fading in, with GM_Fadein. Note that the init routine will not run again.

#[bank(00)]
RunFrame:
	REP #$30	; AXY 16-bit
	LDA.w #VBlank_DoNothingRTI
	STA.b VBlankPtr
	JSR ResetSprites
	JSL RunFrameTrampoline
	JSR FillSpritesEnd
	JSL ScanlineProfiler
	LDA.w RunFrame_VBlank
	STA.b VBlankPtr
	RTS

VBlank_SyncCameraValues:
	REP #$30			; A, XY 16-bit
	; discard the return address and the flags
	SEP #$30			; A, XY 8-bit
	; sync camera scroll values
	LDA $20
	STA $210D
	LDA $21
	STA $210D
	LDA $22
	STA $210E
	LDA $23
	STA $210E
	LDA $24
	STA $210F
	LDA $25
	STA $210F
	LDA $26
	STA $2110
	LDA $27
	STA $2110
	REP #$30
	;JSR HDMASetup
	JSR DrawAllSprites
VBlank_DoNothing:
	REP #$30
	PLA : PLA
	JMP MainLoop


#[bank(02)]
RunFrameTrampoline:
	SEP #$10	; XY 8-bit
	LDX.b Gamemode
	REP #$30
	BPL +
	JSR (GamemodeInitPtrs-$0080,x)
	RTL
+	JSR (GamemodePtrs,x)
	RTL

GamemodePtrs:
GMID_Logo:		dw GM_Logo
GMID_Movecam:	dw GM_Movecam
GMID_Level:		dw GM_Level
GMID_Fadein:	dw GM_Fadein
GMID_Fadeout:	dw GM_Fadeout

GamemodeInitPtrs:
	dw GMInit_Logo
	dw GMInit_Movecam
	dw GMInit_Level
	dw GMInit_Fadein
	dw GMInit_Fadeout


GM_Level:
	RTS

GMInit_Level:
	RTS

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
