HDMATable:
	db $A0
	db $00, $01, $02, $03, $04, $05, $06, $07
	db $10, $11, $12, $13, $14, $15, $16, $17
	db $20, $21, $22, $23, $24, $25, $26, $27
	db $30, $31, $32, $33, $34, $35, $36, $37
	db $00

HDMABright:
db $30,$00,$00
db $02,$0F,$00
db $02,$0E,$00
db $02,$0D,$00
db $02,$0C,$00
db $02,$0B,$00
db $02,$0A,$00
db $02,$09,$00
db $02,$08,$00
db $02,$07,$00
db $02,$06,$00
db $02,$05,$00
db $02,$04,$00
db $02,$03,$00
db $02,$02,$00
db $02,$01,$00
db $02,$00,$00
db $00

HDMABright2:
db $1C,$00,$00
db $90,$0F,$00
db $0E,$00
db $0D,$00
db $0C,$00
db $0B,$00
db $0A,$00
db $09,$00
db $08,$00
db $07,$00
db $06,$00
db $05,$00
db $04,$00
db $03,$00
db $02,$00
db $01,$00
db $00,$00
db $00

HDMAPaletteAddr:
	db $C0				; 0
	dw HDMAAddrBlock
	db $C0				; 40
	dw HDMAAddrBlock
	db $C0				; 80
	dw HDMAAddrBlock
	db $A0				; C0 ~ E0
	dw HDMAAddrBlock
	db $00


HDMAAddrBlock:
	db $A4,$A4,$A4,$A4,$A4,$A4,$A4,$A4
	db $A4,$A4,$A4,$A4,$A4,$A4,$A4,$A4
	db $A4,$A4,$A4,$A4,$A4,$A4,$A4,$A4
	db $A4,$A4,$A4,$A4,$A4,$A4,$A4,$A4
	db $A4,$A4,$A4,$A4,$A4,$A4,$A4,$A4
	db $A4,$A4,$A4,$A4,$A4,$A4,$A4,$A4
	db $A4,$A4,$A4,$A4,$A4,$A4,$A4,$A4
	db $A4,$A4,$A4,$A4,$A4,$A4,$A4,$A4


HDMAPalette:
	db $C0
	dw LCH_Rainbow_64
	db $C0
	dw LCH_Rainbow_64
	db $C0
	dw LCH_Rainbow_64
	db $A0
	dw LCH_Rainbow_64
	db $00

HDMAPaletteDark:
	db $C0
	dw LCH_Rainbow_Dark_64
	db $C0
	dw LCH_Rainbow_Dark_64
	db $C0
	dw LCH_Rainbow_Dark_64
	db $A0
	dw LCH_Rainbow_Dark_64
	db $00

LCH_Rainbow_64:
	incbin "../build/lch_rainbow_64.pal"
LCH_Rainbow_Dark_64:
	incbin "../build/lch_rainbow_dark_64.pal"

HDMASetup:
	PHP
	REP #$20	; A 16 bit
	SEP #$10	; XY 8 bit
	LDY #%01000010	; byte, byte, indirect
	STY $4330	;
	LDY.b #CGDATA
	STY $4331
	LDA.w #HDMAPalette	; get pointer to brightness table
	STA $4332	; store it to low and high byte pointer
	LDY.b #HDMAPalette>>16
	STY $4334	; store to bank pointer byte
	LDY.b #LCH_Rainbow_64>>16
	STY $4337

	LDY #%01000010	; byte, byte, indirect
	STY $4340	;
	LDY.b #CGDATA
	STY $4341
	LDA.w #HDMAPaletteDark	; get pointer to brightness table
	STA $4342	; store it to low and high byte pointer
	LDY.b #HDMAPaletteDark>>16
	STY $4344	; store to bank pointer byte
	LDY.b #LCH_Rainbow_Dark_64>>16
	STY $4347

	LDY #%01000010	; byte, byte, indirect
	STY $4350	;
	LDY.b #CGDATA
	STY $4351
	LDA.w #HDMAPalette	; get pointer to brightness table
	STA $4352	; store it to low and high byte pointer
	LDY.b #HDMAPalette>>16
	STY $4354	; store to bank pointer byte
	LDY.b #LCH_Rainbow_64>>16
	STY $4357

	LDY #%01000000	; byte, indirect
	STY $4310	;
	LDY.b #CGADD
	STY $4311
	LDA.w #HDMAPaletteAddr	; get pointer to brightness table
	STA $4312	; store it to low and high byte pointer
	LDY.b #HDMAPaletteAddr>>16
	STY $4314	; store to bank pointer byte
	LDY.b #HDMAAddrBlock>>16
	STY $4317
	LDY #%00111010	; Enable HDMA on channels 1, 3, 4
	STY $420C	;
	PLP
	RTS		; return

HDMASetup2:
	PHP
	REP #$20	; A 16 bit
	SEP #$10	; XY 8 bit
	LDY #$02	;
	STY $4300	;
	LDY #$0D	; 210D: BG0 horiz scroll
	STY $4301
	LDA.w #HDMABright2	; get pointer to brightness table
	STA $4302	; store it to low and high byte pointer
	LDY.b #HDMABright2>>16
	STY $4304	; store to bank pointer byte
	LDY #$01	; Enable HDMA on channel 3
	STY $420C	;
	PLP
	RTS		; return
