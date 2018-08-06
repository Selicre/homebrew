; Helper methods for drawing sprites

; Adds a single sprite to the OAM.
; A: tile ID + properties
; X: X position
; Y: Y position
; Carry flag: larger sprite size
; Various improvements by Drex#6494

AddSpriteTileLeave:
	PLA
	PLX
	PLP
	RTL						; If it is, bail

AddSpriteTile:
	PHP						; Stack +1
	STX.b Scratch
	PHX						; Stack +2
	PHA						; Stack +2
	LDA.w SprInputPtr		; Test if the OAM table is full
	CMP.w #SprInputSub-4
	BPL AddSpriteTileLeave
	LDA 3,s					; load x
	CMP #$FFF0
	BMI AddSpriteTileLeave	; if outside of range, leave
	CMP #$0100
	BPL AddSpriteTileLeave	; if outside of range, leave
	TYA
	CMP #$FFF0
	BMI AddSpriteTileLeave	; if outside of range, leave
	CMP #$00E0
	BPL AddSpriteTileLeave	; if outside of range, leave

	PLA
	LDX.w SprInputPtr
	STA $0002,x
	SEP #$20    			; A 8-bit
	LDA.b Scratch
	STA $0000,x
	TYA
	STA $0001,x
	REP #$21				; AXY 16-bit, also clear carry
	TXA
	ADC #$0004
	STA.w SprInputPtr
AddSpriteTileHiOAM:
	LDY.w SprInputSubPtr
	LDX.w SprInputIndex
	PLA            ; Stack 1
	BIT #$0100    ; Is the top bit set?
	BEQ +
	SEP #$20    ; A 8-bit
	LDA.w .ptr_to_x_table,x
	ORA $0000,y
	STA $0000,y
+
	PLP            ; Stack 2, also sets A to 16 bits
	BCC +
	SEP #$20    ; A 8-bit
	LDA.w .ptr_to_s_table,x
	ORA $0000,y
	STA $0000,y
	REP #$20    ; A 16-bit
+	; Increment everything
	INX
	CPX #$0004
	BNE +
	INC.w SprInputSubPtr
	LDX #$0000
+	STX.w SprInputIndex
	RTL
.ptr_to_x_table:
; bit    0,   2,   4,   6
    db $01, $04, $10, $40
.ptr_to_s_table:
; bit    1,   3,   5,   7
    db $02, $08, $20, $80

InitSprites:
	LDA #$0500
	STA.w SprInputLastPtr
	RTS

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
	LDX.w SprInputPtr
	; Fill rest with $E0 (moves just enough offscreen)
	LDA #$E0E0
-
	STA.w $0000,x
	INX
	INX
	CPX.w SprInputLastPtr
	BMI -
	LDX.w SprInputPtr
	STX.w SprInputLastPtr
	RTS


DrawAllSprites:
	LDX.w #.queue
	JSL LoadDataQueue
	RTS
.queue
	db $02
	dl $7E0300
	dw $0000, $0220
	db $FF
