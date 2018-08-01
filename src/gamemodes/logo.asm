define Logo_Timer $80

#[bank(00)]
LogoInit_LoadQueue:
	db $01
	dl GFXLogo
	dw $0000, GFXLogoSize
	db $01
	dl GFXLogoMap
	dw $410C, GFXLogoMapSize
	db $00
	dl GFXLogoPal
	dw $0000, GFXLogoPalSize
	db $FF

#[bank(02)]
GM_LogoInit:
	SEP #$30
	LDA #%00000001	; enable NMI & IRQ
	STA.w NMITIMEN
	LDA #%10000000	; turn screen off, activate vblank
	STA.w INIDISP
	REP #$30
	LDX.w #LogoInit_LoadQueue
	JSL LoadDataQueue
	SEP #$30		; turn AXY 8-bit

	LDA #%00000010 ; bg mode 1, 8x8 tiles
	STA.w BGMODE

	LDA #%01000001	; tilemap at 0x8000, no mirroring
	STA.w BG1SC
	LDA #%01001001	; tilemap at 0x9000, no mirroring
	STA.w BG2SC
	LDA #%01010001	; tilemap at 0xA000, no mirroring
	STA.w BG3SC

	LDA #%00000001	; enable BG1
	STA.w TM
	LDA #%00000000	; no subscreen
	STA.w TS
	LDA #%00000000
	STA.w OBSEL
	; Set up IRQ to split the screen in two

	SEP #$30
	LDA #%10100001	; enable NMI & IRQ
	STA.w NMITIMEN
	REP #$30
	LDA.w #GMID_Logo-GamemodePtrs
	STA.b Gamemode
	LDA.w #60
	STA.b Logo_Timer
	JMP FadeinInit


GM_Logo:
	DEC.b Logo_Timer
	BNE +
	LDA.w #GMID_MovecamInit-GamemodePtrs
	JMP FadeoutInit
+
	RTS
