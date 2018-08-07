; Bouncy flower object
; Draws a flower that obeys gravity, and reverses direction on collision.

ObjBouncyFlower:
	LDA.w #ObjBouncyFlowerMain
	STA.b obj_ID
	STZ.b obj_YSpeed
	STZ.b obj_XSpeed
	STZ.b obj_YSubpx
	;LDA.w #$0100
	;STA.b obj_XSpeed
ObjBouncyFlowerMain:
	; Update Y position
	LDA.b obj_YSpeed
	CLC : ADC #$0040
	STA.b obj_YSpeed

	LDA.b obj_YSpeed
	BPL +
	ORA #$00FF
	BRA ++
+
	AND #$FF00
++
	XBA
	CLC : ADC.b obj_YPos
	STA.b obj_YPos

	LDA.b obj_XSpeed
	BPL +
	ORA #$00FF
	BRA ++
+
	AND #$FF00
++
	XBA
	CLC : ADC.b obj_XPos
	STA.b obj_XPos

;	SEP #$20

;	LDA.b obj_YSpeed
;	CLC : ADC.b obj_YSubpx
;	STA.b obj_YSubpx
;	LDA.b obj_YSpeed+1
;	ADC.b obj_YPos
;	STA.b obj_YPos
;	BMI +
;	BCC .done
;	INC.b obj_YPos+1
;	BRA .done
;+
;	BCS .done
;;	DEC.b obj_YPos+1
;.done
;	REP #$20

.bounceY
	LDA.b obj_XPos
	CLC : ADC.w #$0008
	TAX
	LDA.b obj_YPos
	CLC : ADC.w #$0010
	TAY
	JSL GetBlockAt
	CMP #$0000
	BEQ +
	LDA.b obj_YSpeed
	BMI +
	EOR #$FFFF : INC
	CLC : ADC #$0080
	CMP #-$800
	BPL ..noclamp
	LDA #-$800
..noclamp
	STA.b obj_YSpeed
+

.bounceX
	LDA.b obj_XPos
	CLC : ADC.w #$0010
	TAX
	LDA.b obj_YPos
	;CLC : ADC.w #$0008
	TAY
	JSL GetBlockAt
	CMP #$0000
	BEQ ..nobounce

	LDA.b obj_XPos
	;CLC : ADC.w #$0010
	TAX
	LDA.b obj_YPos
	;CLC : ADC.w #$0008
	TAY
	JSL GetBlockAt
	CMP #$0000
	BEQ ..nobounce

	LDA.b obj_XSpeed
	EOR #$FFFF : INC
..noclamp
	STA.b obj_XSpeed
..nobounce

	LDA.b obj_XPos
	SEC : SBC.w CamX
	TAX
	LDA.b obj_YPos
	SEC : SBC.w CamY
	TAY
	;        vhppccc
	LDA.w #(%0011000 << 9) | $18A
	SEC
	JSL AddSpriteTile
	RTL
