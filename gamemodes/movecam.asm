define Movecam_Speed $80


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

; is also in bank 0 because lol
Movecam_Load_Queue:
	db $01
	dl Graphics01
	dw $0000, $4000
	db $00
	dl Palette
	dw $0000, $0080
	db $00
	dl Palette
	dw $0080, $0080
	db $01
	dl BGTilemap01
	dw $4000, $2000
	db $FF

#[bank(02)]
GMInit_Movecam:
	SEP #$30
	LDA #%10000000	; turn screen off, activate vblank
	STA.w INIDISP
	REP #$30
	LDX.w #Movecam_Load_Queue
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

	LDA #%00010011	; enable BG1-2 + OBJ
	STA.w TM
	LDA #%00000011	; enable BG1-2
	STA.w TS
	LDA #%00000000
	STA.w OBSEL
	LDA #%00001111	; end vblank, setting brightness to 15
	; Set up IRQ to split the screen in two

	REP #$20
	LDA #$0030
	STA.w VTIME
	LDA.w #SplitIRQ
	STA.b IRQPtr
	SEP #$30
	LDA #%00001111	; end vblank, setting brightness to 15
	STA.w INIDISP
	REP #$30
	RTS

GM_Movecam:
	; Controller stuff
	LDA $4218
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
	CMP #$0010				; max speed = [-4; 4]
	BMI +
	LDA #$0010
+
	CMP #$FFF0
	BPL +
	LDA #$FFF0
+
	STA $00
	LDA $4218
	BIT #$0100				; adjust camera position
	BEQ +
	TAX
	LDA $20
	SEC : ADC $00
	STA $20
	TXA
+	BIT #$0200
	BEQ +
	TAX
	LDA $20
	CLC : SBC $00
	STA $20
	TXA
+	BIT #$0400
	BEQ +
	TAX
	LDA $22
	SEC : ADC $00
	STA $22
	TXA
+	BIT #$0800
	BEQ +
	TAX
	LDA $22
	CLC : SBC $00
	STA $22
	TXA
+
	INC $24

	; Add left/top borders
	LDA.b CamX
	CMP #$0000
	BPL +
	STZ.b CamX
+
	LDA.b CamY
	CMP #$0000
	BPL +
	STZ.b CamY
+
	; Draw the HUD
	BRA +
	LDA.w CamX
	LDX.w #$0028
	LDY.w #$0010
	JSR HexSpriteText
	LDA.w CamY
	LDX.w #$0028
	LDY.w #$0018
	JSR HexSpriteText
	LDA.w SysLoad
	AND.w #$00FF
	LDX.w #$0020
	LDY.w #$0020
	JSR HexSpriteText
	LDA.w SysLoadLo
	AND.w #$00FF
	LDX.w #$0020
	LDY.w #$0028
	JSR HexSpriteText
+
Thing:
	; Draw the misc test sprites
	LDA.w #$0060
	CLC : SBC.w CamX
	TAX
	LDA.w #$00A0
	CLC : SBC.w CamY
	TAY
	LDA.w #(%00110001 << 8) + $88
	SEC
	JSL AddSpriteTile

	LDA.w #$0040
	CLC : SBC.w CamX
	TAX
	LDA.w #$00A0
	CLC : SBC.w CamY
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
	LDA.w #$0120
	CLC : ADC 1,s
	LSR
	SEC : SBC.w CamX
	TAX
	LDA 1,s
	ASL : ASL
	CLC : ADC 1,s
	ASL
	SEC : SBC.w CamY
	TAY
	LDA 1,s
	AND.w #%00000011
	ASL
	ORA.w #%00100001
	XBA
	ORA.w #$0086
	SEC
	JSL AddSpriteTile
	PLY
	CPY.w CamX
	BMI -


	RTS
