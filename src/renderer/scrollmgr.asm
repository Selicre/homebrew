; Scroll manager routine
; Updates the screen as you move the camera. This uses routines defined below.
; The routines called should use 3,s and 5,s (bare stack) as the X and Y loading seams respectively.
; Call with 16-bit AXY

define ScrollMgr_Column	DrawTilemapColumn
define ScrollMgr_Row	DrawTilemapRow

#[bank(03)]
ScrollMgr:
	LDA.b CamX
	CLC : ADC.w #$0140	; $140px in front
	AND #$FFF0
	PHA					; stack +2

	LDA.b CamY
	CLC : ADC.w #$00F0	; $F0px below
	AND #$FFF0
	PHA					; stack +2
	
	LDA.w HScrollSeam
	CMP 3,s
	BEQ +++			; Same column?

	BMI +
	SEC : SBC #$0210
+

	JSL ScrollMgr_Column

	LDA 3,s
	STA.w HScrollSeam
	BRA .end
+++
	LDA.w VScrollSeam
	CMP 1,s
	BEQ +++			; Same row?
	
	BMI +
	SEC : SBC #$0110
+
	JSL ScrollMgr_Row
	LDA 1,s
	STA.w VScrollSeam
+++
.end
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

ScrollMgr_Debug:
	LDA.w JOY1
;	AND.w JoypadPrev
	BIT #$8000
	BEQ +
	LDA.w HScrollSeam
	CLC : ADC.w #$0010
	AND.w #$7FF
	STA.w HScrollSeam
	STA 3,s
	JSL ScrollMgr_Column
+
	LDA.w JOY1
;	AND.w JoypadPrev
	BIT #$4000
	BEQ +
	LDA.w VScrollSeam
	CLC : ADC.w #$0010
	AND.w #$7FF
	STA.w VScrollSeam
	STA 1,s
	JSL ScrollMgr_Row
+
	PLA
	PLA
	RTL
