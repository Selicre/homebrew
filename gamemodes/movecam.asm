define Movecam_Speed $80


HexSpriteText:
	STA.b Scratch+4
.addScore:
	LDA.b Scratch+4
	AND.w #$000F
	CLC : ADC.w #(%00110111 << 8) + $F0
	;SEC
	JSL AddSpriteTile
	LSR.b Scratch+4
	LSR.b Scratch+4
	LSR.b Scratch+4
	LSR.b Scratch+4
	TXA
	SEC : SBC.w #8
	TAX
	CPX #$0008
	BNE .addScore
	RTS

GM_Movecam:
	; Controller stuff
	LDA $4218
	BIT #$0F00				; If no controller buttons are held..
	BNE +
	STZ.b Movecam_Speed		; Remove all speed
	; TODO: fix compiler bug
+	INC.b $80		; Otherwise, add 1
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
	;RTS
;Lasdqwke:
	LDY #$0000
-
	INY
	PHY
	LDA.w #$0060
	ADC 1,s
	CLC : SBC.w CamX
	TAX
	LDA 1,s
	ASL : ASL
	CLC : SBC.w CamY
	TAY
	LDA.w #(%00110001 << 8) + $88
	SEC
	JSL AddSpriteTile
	PLY
	CPY.w CamX
	BMI -
	RTS
