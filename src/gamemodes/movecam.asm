define Level_Speed 		$80
define Level_CamXStart	$82
define Level_CamYStart	$84
define Level_CamXEnd		$86
define Level_CamYEnd		$88
define Level_SpeedM		$8A


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
Level_LoadQueue:
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
GM_LevelInit:
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

	LDX.w #Level_LoadQueue
	JSL LoadDataQueue
	JSL InitObjMgr

	; Spawn one object
	LDA.w #ObjDebugCtlr
	STA $1000
	LDA.w #ObjDebugCtlr>>8
	STA $1001

	LDA.w #$0080
	STA $1000+obj_XPos
	LDA.w #$0040
	STA $1000+obj_YPos

	; Spawn another object
	;LDA.w #ObjBouncyFlower
	;STA $1040
	;LDA.w #ObjBouncyFlower>>8
	;STA $1041

	LDA.w #$0100
	STA $1040+obj_XPos
	LDA.w #$0040
	STA $1040+obj_YPos

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
	STA.b Level_CamXStart
	STA.b Level_CamYStart
	JSL ScrollMgrInit

	LDA #$3100
	STA.b Level_CamXEnd
	LDA #$3120
	STA.b Level_CamYEnd
	LDA.w #GMID_Level-GamemodePtrs
	STA.b Gamemode
	LDA.w #VBlank_SyncCameraValues
	STA.w RunFrame_VBlank
	JMP FadeinInit

GM_Level:
	; Scroll the thing
	JSL InitVRAMBuffers
	REP #$30
	JMP .no_debug
	; Controller stuff
	LDA.w JOY1
	BIT #$0F00				; If no controller buttons are held..
	BNE +
	STZ.b Level_Speed		; Remove all speed
+	INC.b Level_Speed		; Otherwise, add 1
	;BNE ++
	LDA.b Level_Speed
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
	STA.b Level_SpeedM

	LDA.w JOY1
	BIT #$0100				; adjust camera position
	BEQ +
	
	TAX
	LDA.b CamX
	SEC : ADC.b Level_SpeedM	; note: carry is set to move the camera immediately
	STA.b CamX
	TXA

+	BIT #$0200
	BEQ +

	TAX
	LDA.b CamX
	CLC : SBC.b Level_SpeedM
	STA.b CamX
	TXA

+	BIT #$0400
	BEQ +

	TAX
	LDA.b CamY
	SEC : ADC.b Level_SpeedM
	STA.b CamY
	TXA

+	BIT #$0800
	BEQ +
	
	TAX
	LDA.b CamY
	CLC : SBC.b Level_SpeedM
	STA.b CamY
	TXA
+
.no_debug:
	; Follow object 0
	LDA.w ObjectTable+obj_XPos
	SEC : SBC #$0080
	STA.b CamX
	LDA.w ObjectTable+obj_YPos
	SEC : SBC #$0080
	STA.b CamY

	; Add camera borders
	LDA.b CamX
	CMP.b Level_CamXStart
	BPL +
	STZ.b CamX
+
	LDA.b CamY
	CMP.b Level_CamYStart
	BPL +
	STZ.b CamY
+
	LDA.b Level_CamXEnd
	CMP.b CamX
	BPL +
	STA.b CamX
+
	LDA.b Level_CamYEnd
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

	JSL ScrollMgr


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
	
	JSL ObjectMgr

	RTS
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
