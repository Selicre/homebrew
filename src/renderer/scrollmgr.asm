; Scroll manager routine
; Updates the screen as you move the camera. This uses routines defined below.
; The routines called should use 3,s and 5,s (bare stack) as the X and Y loading seams respectively.
; Call with 16-bit AXY

define ScrollMgr_Column	DrawTilemapColumn
define ScrollMgr_Row	DrawTilemapRow

#[bank(03)]
ScrollMgr:
	LDA.b CamX
	CLC : ADC.w #$0040	; $40px in front
	AND.w #$7F0
	PHA					; stack +2

	LDA.b CamY
	SEC : SBC.w #$0010	; $10px below
	AND.w #$7F0
	PHA					; stack +2
	
	LDA.w HScrollSeam
	CMP 3,s
	BEQ +++			; Same column?

	; TODO: remove this
	BPL +
	LDA #$01B0
	BRA ++
+
	LDA #$FFC0
++

	JSL ScrollMgr_Column
	LDA 3,s
	STA.w HScrollSeam
+++
	LDA.w VScrollSeam
	CMP 1,s
	BEQ +++			; Same column?
	; TODO: remove this
	
	BMI +
	LDA #$FFF0
	BRA ++
+
	LDA #$00E0
++
	JSL ScrollMgr_Row
	LDA 1,s
	STA.w VScrollSeam
+++
	PLA
	PLA
	RTL

ScrollMgrInit:
	LDA.b CamX
	CLC : ADC.w #$0040	; $40px in front
	AND.w #$7F0
	STA.w HScrollSeam

	LDA.b CamY
	SEC : SBC.w #$0010	; $10px below
	AND.w #$7F0
	STA.w VScrollSeam
	RTL
