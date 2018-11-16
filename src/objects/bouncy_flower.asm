; Bouncy flower object
; Draws a flower that obeys gravity, and reverses direction on collision.

ObjBouncyFlower:
	LDA.w #ObjBouncyFlowerMain
	STA.b obj_ID
	STZ.b obj_YSpeed
	STZ.b obj_XSpeed
	STZ.b obj_YSubpx
	LDA.w #$0100
	STA.b obj_XSpeed
	LDA.w #$0F0F
	STA.b obj_Size
ObjBouncyFlowerMain:
	; Update Y position
	LDA.b obj_YSpeed
	CMP #$0400
	BPL +
	CLC : ADC #$0040
	STA.b obj_YSpeed
+
	JSL SimpleLayerCollision
	PHA
.bounceDown
	AND.w #%0100
	BEQ +
	LDA.w #-$600
	STA.b obj_YSpeed
+
.bounceLeft
	LDA 1,s
	AND.w #%0010
	BEQ +
	LDA.w #$0100
	STA.b obj_XSpeed
+
.bounceRight
	LDA 1,s
	AND.w #%0001
	BEQ +
	LDA.w #-$100
	STA.b obj_XSpeed
+
	PLA

	LDA.b obj_XPos
	SEC : SBC.w CamX
	TAX
	LDA.b obj_YPos
	SEC : SBC.w CamY
	TAY
	;        vhppccc
	LDA.w #(%0011111 << 9) | $18C
	SEC
	JSL AddSpriteTile
	RTL
