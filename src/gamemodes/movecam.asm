define Movecam_Speed 		$80
define Movecam_CamXStart	$82
define Movecam_CamYStart	$84
define Movecam_CamXEnd		$86
define Movecam_CamYEnd		$88
define Movecam_SpeedM		$8A


HexSpriteText:
	STA.b Scratch+4
	PHY
.addScore:
	LDA.b 1,s
	TAY
	LDA.b Scratch+4
	AND.w #$000F
	CLC : ADC.w #(%00110111 << 8) + $F0
	;SEC
	PHX
	JSL AddSpriteTile
	PLX
	LSR.b Scratch+4
	LSR.b Scratch+4
	LSR.b Scratch+4
	LSR.b Scratch+4
	TXA
	SEC : SBC.w #8
	TAX
	CPX #$0008
	BNE .addScore
	PLY
	RTS

#[bank(00)]
SplitIRQ:
	PHA
	PHY
	PHX
	PHP
	REP #$20
	SEP #$10
	LDA $24		; load layer 2 x pos
	LSR			; half it
	TAX
	STX $210F
	XBA
	TAX
	STX $210F
	PLP
	PLX
	PLY
	PLA
	RTI

VBlank_SyncCameraValues:
	REP #$30			; A, XY 16-bit
	DEC $22
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
	INC $22
	JSR DrawAllSprites
	JSL UploadScrollBuffer
	JSR HDMASetup
VBlank_DoNothing:
	REP #$30
	PLA : PLA
	JMP MainLoop

; is also in bank 0 because why not
Movecam_LoadQueue:
	db $01
	dl GFXLevel
	dw $0000, $4000
	db $00
	dl GFXLevelPal
	dw $0000, $0080
	db $00
	dl GFXLevelPal
	dw $0080, $0080
	db $01
	dl GFXLevelMap
	dw $4000, $2000
	db $03
	dl Chunks0123
	dw LevelChunks, $1000
	db $FF

#[bank(02)]
GM_MovecamInit:
	SEP #$30
	LDA #%00000001	; enable NMI & IRQ
	STA.w NMITIMEN
	LDA #%10000000	; turn screen off, activate vblank
	STA.w INIDISP

	; Clean level data
	REP #$30
	LDA #$0000
	LDX.w #LevelChunks>>16
	STX $02
	LDX.w #LevelChunks
	STX $00

	JSL InitVRAMBuffers

	LDX.w #Movecam_LoadQueue
	JSL LoadDataQueue

	LDA.w #BlockMappings						; 01 02
	STA.l LevelMeta
	LDA.w #BlockMappings<<8|BlockMappings>>16	; 03 01
	STA.l LevelMeta+2
	LDA.w #BlockMappings>>8						; 01 02
	STA.l LevelMeta+4
	
	LDA.w #BlockMappings						; 01 02
	STA.l LevelMeta + LevelMetaSize
	LDA.w #BlockMappings<<8|BlockMappings>>16	; 03 01
	STA.l LevelMeta+2 + LevelMetaSize
	LDA.w #BlockMappings>>8						; 01 02
	STA.l LevelMeta+4 + LevelMetaSize
	
	LDA.w #BlockMappings						; 01 02
	STA.l LevelMeta + 2*LevelMetaSize
	LDA.w #BlockMappings<<8|BlockMappings>>16	; 03 01
	STA.l LevelMeta+2 + 2*LevelMetaSize
	LDA.w #BlockMappings>>8						; 01 02
	STA.l LevelMeta+4 + 2*LevelMetaSize
	
	LDA.w #BlockMappings						; 01 02
	STA.l LevelMeta + 3*LevelMetaSize
	LDA.w #BlockMappings<<8|BlockMappings>>16	; 03 01
	STA.l LevelMeta+2 + 3*LevelMetaSize
	LDA.w #BlockMappings>>8						; 01 02
	STA.l LevelMeta+4 + 3*LevelMetaSize
	LDA #$0000
	JSL DrawStartingTilemap
	JSL UploadBuffer

	SEP #$30		; turn AXY 8-bit

	LDA #%00000001 ; bg mode 1, 8x8 tiles
	STA.w BGMODE

	LDA #%01000001	; tilemap at 0x8000, no mirroring
	STA.w BG1SC
	LDA #%01001001	; tilemap at 0x9000, no mirroring
	STA.w BG2SC
	LDA #%01010001	; tilemap at 0xA000, no mirroring
	STA.w BG3SC

	LDA #%00010011	; enable BG1-2 + OBJ
	STA.w TM
	LDA #%00000011	; enable BG1-2
	STA.w TS
	LDA #%00000000
	STA.w OBSEL


	; Set up IRQ to split the screen in two

	;REP #$20
	;LDA #$0030
	;STA.w VTIME
	;LDA.w #SplitIRQ
	;STA.b IRQPtr
	SEP #$30
	LDA #%10100001	; enable NMI & IRQ
	STA.w NMITIMEN
	REP #$30
	LDA #$0000
	STA.b Movecam_CamXStart
	STA.b Movecam_CamYStart
	LDA #$3100
	STA.b Movecam_CamXEnd
	LDA #$3120
	STA.b Movecam_CamYEnd
	LDA.w #GMID_Movecam-GamemodePtrs
	STA.b Gamemode
	LDA.w #VBlank_SyncCameraValues
	STA.w RunFrame_VBlank
	JMP FadeinInit
	;RTS

GM_Movecam:
	; Scroll the thing
	JSL InitVRAMBuffers
	REP #$30

	; Controller stuff
	LDA.w JOY1
	BIT #$0F00				; If no controller buttons are held..
	BNE +
	STZ.b Movecam_Speed		; Remove all speed
+	INC.b Movecam_Speed		; Otherwise, add 1
	;BNE ++
	LDA.b Movecam_Speed
	LSR
	LSR
	LSR
	LSR
	CMP #$0007				; max speed = [-4; 4]
	BMI +
	LDA #$0007
+
	CMP #$FFF7
	BPL +
	LDA #$FFF7
+
	STA.b Movecam_SpeedM

	LDA.w JOY1
	BIT #$0100				; adjust camera position
	BEQ +
	
	PHA
	LDA #$0140			; scroll downward
	JSL DrawTilemapColumn
	PLA

	TAX
	LDA.b CamX
	SEC : ADC.b Movecam_SpeedM	; note: carry is set to move the camera immediately
	STA.b CamX
	TXA

+	BIT #$0200
	BEQ +

	PHA
	LDA #$FFC0			; scroll left
	JSL DrawTilemapColumn
	PLA

	TAX
	LDA.b CamX
	CLC : SBC.b Movecam_SpeedM
	STA.b CamX
	TXA

+	BIT #$0400
	BEQ +

	PHA
	LDA #$00E0			; scroll downward
	JSL DrawTilemapRow
	PLA

	TAX
	LDA.b CamY
	SEC : ADC.b Movecam_SpeedM
	STA.b CamY
	TXA

+	BIT #$0800
	BEQ +

	PHA
	LDA #$FFF0			; scroll upward
	JSL DrawTilemapRow
	PLA

	TAX
	LDA.b CamY
	CLC : SBC.b Movecam_SpeedM
	STA.b CamY
	TXA
+

	; Add camera borders
	LDA.b CamX
	CMP.b Movecam_CamXStart
	BPL +
	STZ.b CamX
+
	LDA.b CamY
	CMP.b Movecam_CamYStart
	BPL +
	STZ.b CamY
+
	LDA.b Movecam_CamXEnd
	CMP.b CamX
	BPL +
	STA.b CamX
+
	LDA.b Movecam_CamYEnd
	CMP.b CamY
	BPL +
	STA.b CamY
+

; Update BG
	LDA.b CamX
	LSR : LSR
	STA.b BGX
	LDA.b CamY
	LSR : LSR : LSR : LSR
	STA.b BGY

	; Draw the HUD
	;BRA +
	LDA.w CamX
	LDX.w #$0028
	LDY.w #$0010
	JSR HexSpriteText
	LDA.w CamY
	LDX.w #$0028
	LDY.w #$0018
	JSR HexSpriteText
	LDA.w SysLoad
	LDX.w #$0020
	LDY.w #$0020
	JSR HexSpriteText
	LDA.w SysLoadLo
	LDX.w #$0020
	LDY.w #$0028
	JSR HexSpriteText
+
Thing:
	; Draw the misc test sprites
	LDA.w #$0080
	SEC : SBC.w CamX
	TAX
	LDA.w #$0090
	SEC : SBC.w CamY
	TAY
	LDA.w #(%00110001 << 8) + $88
	SEC
	JSL AddSpriteTile

	LDA.w #$0060
	SEC : SBC.w CamX
	TAX
	LDA.w #$0090
	SEC : SBC.w CamY
	TAY
	LDA.w #(%00110001 << 8) + $8A
	SEC
	JSL AddSpriteTile
	RTS
	; Draw the test sprite array

	LDY #$0000
-
	INY
	PHY
	LDA.w #$00A0
	CLC : ADC 1,s
	SEC : SBC.w CamX
	TAX
	LDA 1,s
	ASL : ASL
	CLC : ADC 1,s
	ASL : ASL
	SEC : SBC.w CamY
	TAY
	LDA 1,s
	AND.w #%00000011
	ASL
	ORA.w #%00100000
	XBA
	ORA.w #$0006
	SEC
	JSL AddSpriteTile
	PLY
	CPY.w #$0080
	BPL +
	CPY.w CamX
	BMI -
+
	RTS
