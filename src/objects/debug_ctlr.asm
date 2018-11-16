; Debug controller
; Tells you the block type under itself

ObjDebugCtlr:
	LDA.w #ObjDebugCtlrMain
	STA.b obj_ID
	STZ.b obj_YSpeed
	STZ.b obj_XSpeed
	STZ.b obj_YSubpx
	STZ.b obj_OnGround
	STZ.b obj_RenderF
	LDA.w #$0907
	STA.b obj_Size
;	LDA.w #$0100
;	STA.b obj_XSpeed
ObjDebugCtlrMain:
	LDA.w JOY1
	BIT.w #JOY_Select
	BEQ +
	LDA.w #-$0400
	STA.b obj_YSpeed
+
	; Update Y position
	LDX.b obj_YSpeed
	CPX #$0460
	BPL +
	LDA.w JOY1
	BIT.w #JOY_B
	BEQ ++
	TXA
	CLC : ADC #$0030
	BRA +++
++
	TXA
	CLC : ADC #$0060
+++
	STA.b obj_YSpeed
+

	LDA.b obj_OnGround
	BEQ +
	; Clamp to the ground
	LDA.b obj_YSpeed
	CLC : ADC #$00C0
	STA.b obj_YSpeed
	; Animate feet
	LDA.b obj_XSpeed
	XBA
	SEP #$20
	CLC : ADC.b obj_Anim
	STA.b obj_Anim
	REP #$20
	; Decelerate
	LDA.w JOY1
	BIT.w #JOY_Left|JOY_Right
	BNE ++++
	LDA.b obj_XSpeed
	BEQ ++
	BPL +++
	CLC : ADC.w #$0080
	BMI ++
	LDA.w #$0000
	BRA ++
+++
	SEC : SBC.w #$0080
	BPL ++
	LDA.w #$0000
++
	STA.b obj_XSpeed
++++

	LDA.w JOY1
	AND.w Joypad1Prev
	BIT.w #JOY_B
	BEQ +++
	LDA.w #-$600
	STA.b obj_YSpeed
+++
	BRA ++
+
	LDA.w #$0000
	STA.b obj_Anim
++

	LDA.w JOY1
	BIT.w #JOY_Right				; adjust camera position
	BEQ +
	LDA.b obj_XSpeed
	CMP #$0400
	BPL ++
	CLC : ADC.w #$0040
	STA.b obj_XSpeed
++
	LDA.w #%01<<$E	; vh
	TSB.b obj_RenderF
	LDA.w JOY1
+
	BIT.w #JOY_Left				; adjust camera position
	BEQ +
	LDA.b obj_XSpeed
	CMP #$FCFF
	BMI ++
	CLC : ADC.w #-$0040
	STA.b obj_XSpeed
++
	LDA.w #%01<<$E	; vh
	TRB.b obj_RenderF
	LDA.w JOY1
+
	BIT.w #JOY_A
	BEQ +
	LDA.b obj_XPos
	STA.w $1040+obj_XPos
	LDA.b obj_YPos
	STA.w $1040+obj_YPos
+

	LDA.w JOY1
	BIT.w #JOY_X
	BNE +
	LDA.w #$0000
	STA.b obj_OnGround
	JSL SimpleLayerCollision
	BIT.w #%0100
	BEQ +
	LDA.w #$00FF
	STA.b obj_OnGround
+
	; Camera follows this object
	JSL CameraFollow

	LDA.b obj_XPos
	SEC : SBC.w CamX
	SBC.w #$0003
	TAX
	LDA.b obj_YPos
	SEC : SBC.w CamY
	SBC.w #$0007
	TAY
	LDA.b obj_Anim
	BIT.w #$0010
	BEQ +
	LDA.b obj_RenderF
	ORA.w #$02
	BRA ++
+
	LDA.b obj_RenderF
++
	;        vhppccc
	ORA.w #(%0010010 << 9) | $180
	SEC
	JSL AddSpriteTile

	RTL
