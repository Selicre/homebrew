; main player character


Physics_AccelTable:
	define AccelWalk $18
	define AccelRun $18
	define DecelStill $10
	define DecelWalk $28
	define DecelRun $50

	; address with glrdx (onground, holding left, holding right, direction (right=0), sprinting)
	; note that #$00 is used when speed is 0

	dw $00,$00,$00,$00
	dw AccelWalk,AccelRun,DecelWalk,DecelRun
	dw $10000-DecelWalk,$10000-DecelRun,$10000-AccelWalk,$10000-AccelRun
	dw $00,$00,$00,$00
	dw $10000-DecelStill,$10000-DecelStill,DecelStill,DecelStill
	dw AccelWalk,AccelRun,DecelWalk,DecelRun
	dw $10000-DecelWalk,$10000-DecelRun,$10000-AccelWalk,$10000-AccelRun
	dw $00,$00,$00,$00

Physics_JumpTable:
	define JumpHeightBase $500
	define JumpHeightIncrease $28
	dw -JumpHeightBase-JumpHeightIncrease*0,-JumpHeightBase-JumpHeightIncrease*1
	dw -JumpHeightBase-JumpHeightIncrease*2,-JumpHeightBase-JumpHeightIncrease*3
	dw -JumpHeightBase-JumpHeightIncrease*4,-JumpHeightBase-JumpHeightIncrease*5
	dw -JumpHeightBase-JumpHeightIncrease*6,-JumpHeightBase-JumpHeightIncrease*7

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
	; Update Y position & apply gravity
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

Marker:
	LDA.b obj_OnGround
	BEQ +
	LDA.w JOY1
	AND.w Joypad1Prev
	AND.w #JOY_B
	BEQ ++
	LDA.b obj_XSpeed
	BPL +++
	EOR.w #$FFFF : INC
+++
	AND.w #$FF00
	XBA
	ASL
	TAX
	LDA.l Physics_JumpTable,x
	STA.b obj_YSpeed
	STZ.b obj_OnGround
	BRA +
++
	; Clamp to the ground
	LDA.w #$0100
	STA.b obj_YSpeed
	; Animate feets
	LDA.b obj_XSpeed
	CLC : ADC.b obj_Anim
	STA.b obj_Anim
+
	; apply X momentum
	; This is probably the best way to rearrange a complex bitfield but idk
	LDA.w JOY1
	AND.w #JOY_Left|JOY_Right
	ORA.b obj_XSpeed
	BNE +
	JMP .no_x_movement
+
	STZ.w $00
	STZ.w $02
	LDY.w #$00FF
	LDA.w JOY1
	AND.w #JOY_X|JOY_Y
	BEQ +
	STY.w $00	; is sprinting?
+
	LDA.w JOY1
	AND.w #JOY_Left
	BEQ +
	STY.w $01
+
	LDA.w JOY1
	AND.w #JOY_Right
	BEQ +
	STY.w $02
+
	; Build the glrdx bitfield
	SEP #$30
	LDA #$00
	LDX.b obj_OnGround
	CPX.b #$01	; is non-zero?
	ROL
	LDX.w $01
	CPX.b #$01	; is non-zero?
	ROL
	LDX.w $02
	CPX.b #$01
	ROL
	LDX.b obj_XSpeed+1	; msb of xspeed
	CPX.b #$80
	ROL
	LDX.w $00
	STZ.w $00
	CPX.b #$01
	ROL
	ASL
	TAX
	REP #$30

	STX.w $54
	LDA.l Physics_AccelTable,x
	CLC : ADC.b obj_XSpeed
	STA.w $02
	EOR.b obj_XSpeed	; check if sign is swapped and set to 0 instead (if l+r are not pressed)
	EOR.w #$8000
	AND.w #$8000
	ORA.w $00
	BIT.w #$80FF
	BEQ +
	LDA.w $02
	; check if it's more than the current max speed
	STA.b obj_XSpeed
	BRA ++
+
	STZ.b obj_XSpeed
++
	LDX.w #$0140
	LDA.w JOY1
	BIT.w #JOY_X|JOY_Y
	BEQ +
	LDX.w #$0240
+
	STX.w $04

	LDA.b obj_XSpeed
	BMI .clamp_neg
	CMP.w $04
	BMI .no_x_movement
	LDA.w $04
	STA.b obj_XSpeed
	BRA .no_x_movement
.clamp_neg
	EOR.w #$FFFF : INC
	CMP.w $04
	BMI .no_x_movement
	LDA.w $04
	EOR.w #$FFFF : INC
	STA.b obj_XSpeed
.no_x_movement

	LDA.w JOY1
	BIT.w #JOY_Right
	BEQ +
	LDA.w #%01<<$E	; vh
	TSB.b obj_RenderF
+
	LDA.w JOY1
	BIT.w #JOY_Left
	BEQ +
	LDA.w #%01<<$E	; vh
	TRB.b obj_RenderF
+

	LDA.w JOY1
	BIT.w #JOY_A
	BEQ +
	LDA.b obj_XPos
	STA.w $1040+obj_XPos
	LDA.b obj_YPos
	STA.w $1040+obj_YPos
+

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
	LDA.b obj_OnGround
	BEQ .jumping
	LDA.b obj_Anim
	BIT.w #$1000
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
.jumping
	LDA.b obj_YSpeed
	BMI +
	LDA.b obj_RenderF
	ORA.w #(%0010010 << 9) | $184
	SEC
	JSL AddSpriteTile
	RTL
+
	LDA.b obj_RenderF
	ORA.w #(%0010010 << 9) | $186
	SEC
	PHA
	PHX
	PHY
	JSL AddSpriteTile
	PLY
	TYA : CLC : ADC #$0010 : TAY
	PLX
	LDA.b obj_RenderF
	BIT.w #%01000000<<8
	BEQ +
	TXA : CLC : ADC #$0003 : TAX
	BRA ++
+
	TXA : CLC : ADC #$0005 : TAX
++
	PLA
	INC : INC
	CLC
	JSL AddSpriteTile
	RTL


