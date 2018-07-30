; Helper methods for drawing sprites

; Adds a single sprite to the OAM.
; A: tile ID + properties
; X: X position
; Y: Y position
; Carry flag: is 16x16 size

AddSpriteTile:
	PHP			; Stack 2
	PHX			; Stack 1
	PHA
	; TODO: maybe direct page fuckery?
	LDA.w SprInputPtr
	CMP.w #SprInputSub-4
	BMI +
	PLA
	PLX
	PLP
	RTL
+
	STA.b Scratch
	CLC : ADC #$0002
	STA.b Scratch+2
	PLA

	STA.b (Scratch+2)
	SEP #$30	; AXY 8-bit
	TXA			; TODO: maybe do some shit with ,x?
	STA.b (Scratch)
	INC.b Scratch
	TYA
	STA.b (Scratch)
	REP #$30	; AXY 16-bit
	INC.b Scratch
	LDA.b Scratch
	CLC : ADC.w #$0002
	STA.w SprInputPtr

AddSpriteTileHiOAM:
	LDA.w SprInputSubPtr
	STA.b Scratch
	PLA			; Stack 1
	BIT #$0100	; Is the top bit set?
	BEQ +
	LDA.w SprInputIndex
	AND #$0003	; The top few bits of the index are what we need.
	TAX
	LDA #$0000
	SEP #$20	; A 8-bit
	LDA.w .ptr_to_x_table,x
	ORA.b (Scratch)
	STA.b (Scratch)
	REP #$20	; A 16-bit
+
	PLP			; Stack 2
	BCC +
	LDA.w SprInputIndex
	AND #$0003	; The top few bits of the index are what we need.
	TAX
	SEP #$20	; A 8-bit
	LDA.w .ptr_to_s_table,x
	ORA.b (Scratch)
	STA.b (Scratch)
	REP #$20	; A 16-bit
+	; Increment everything
	INC.w SprInputIndex
	LDA.w SprInputIndex
	AND #$0003
	BNE +
	INC.w SprInputSubPtr
+	RTL
.ptr_to_x_table:
; bit    0,   2,   4,   6
	db $01, $04, $10, $40
.ptr_to_s_table:
; bit    1,   3,   5,   7
	db $02, $08, $20, $80

ResetSprites:
	PHP
	REP #$30
	LDA #$0300
	STA.w SprInputPtr
	LDA #$0500
	STA.w SprInputSubPtr
	LDA #$0000
	STA.w SprInputIndex
	; Fill HiOAM
	LDX #$0500
-
	STA.w $0000,x
	INX
	INX
	CPX #$0520
	BMI -
	PLP
	RTS

FillSpritesEnd:
	PHP
	SEP #$20	; Turn A 8-bit
	REP #$10	; Turn XY 16-bit
	; TODO: fill with 16-bit A
	LDX.w SprInputPtr
	; Fill rest with $E0 (moves just enough offscreen)
	LDA #$E0
-
	STA.w $0000,x
	INX
	CPX #$0500
	BMI -

	PLP
	RTS


DrawAllSprites:
	REP #$30

	LDX.w #.queue
	JSR LoadDataQueue
	SEP #$30
	RTS
.queue
	db $02
	dl $7E0300
	dw $0000, $0220
	db $FF
