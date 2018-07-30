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

HDMASetup:
	PHP
	REP #$20	; 16 bit A
	LDY #$02	;
	STY $4300	;
	LDY #$0D
	STY $4301
	LDA.w #HDMABright2	; get pointer to brightness table
	STA $4302	; store it to low and high byte pointer
	LDY.b #HDMABright2>>16
	STY $4304	; store to bank pointer byte
	LDY #$01	; Enable HDMA on channel 3
	STY $420C	;
	PLP
	RTS		; return
