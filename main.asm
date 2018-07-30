; main asm source file
; over here will be global attributes, linker data, etc.
incsrc "lib/registers.asm"
incsrc "ram.asm"

Start:
	SEI				; disable interrupts
	CLC : XCE		; switch to native mode
	SEP #$30		; A and XY 8-bit
	STZ.w MEMSEL		; slow rom access
	STZ.w MDMAEN	; \ disable any (H)DMA
	STZ.w HDMAEN	; /
	; disable joypad, set NMI and V/H count to 0
	STZ.w NMITIMEN

	LDA #%10000000	; turn screen off, activate vblank
	STA.w INIDISP
	REP #$30		; turn AXY 16-bit
	; Init system stack
	LDA #$01FF
	TCS

	BRA +
.queue
	db $01
	dl Graphics01
	dw $0000, $4000
	db $00
	dl Palette
	dw $0000, $0080
	db $00
	dl Palette
	dw $0080, $0080
	db $01
	dl BGTilemap01
	dw $4000, $2000
	db $FF

+	LDX.w #.queue
	JSR LoadDataQueue
	SEP #$30		; turn AXY 8-bit

	LDA #%00000010 ; bg mode 1, 8x8 tiles
	STA.w BGMODE

	LDA #%01000001	; tilemap at 0x8000, no mirroring
	STA.w BG1SC
	LDA #%01001001	; tilemap at 0x9000, no mirroring
	STA.w BG2SC
	LDA #%01010001	; tilemap at 0xA000, no mirroring
	STA.w BG3SC

	LDA #%00010011	; enable BG1-2 + OBJ
	STA.w TM
	LDA #%00000011	; enable BG1-2
	STA.w TS
	LDA #%00000000
	STA.w OBSEL

	REP #$10		; turn XY 16-bit
	; Clean memory
	LDX #$0000
-	INX
	STZ $00,x
	CPX #$05FF
	BNE -
	
	;JSR ResetSprites
	;JSR FillSpritesEnd

	; Set up IRQ to split the screen in two

	REP #$20
	LDA #$0030
	STA.w VTIME
	LDA.w #SplitIRQ
	STA.b IRQPtr
	SEP #$20

	LDA #%00001111	; end vblank, setting brightness to 15
	STA.w INIDISP

	LDA #%10100001	; enable NMI, IRQ & joypad
	STA.w NMITIMEN
	
	CLI				; enable interrupts
	STA $20
	;JMP MainLoop

MainLoop:
	CLI
	LDA #$01
	STA.b GameRunning
	JSR RunFrame
	STZ.b GameRunning
	; TODO: decompression queue
	SEP #$20	; A 8-bit
	LDA.w SLHV
	LDA.w STAT78	; reset to low byte
	LDA.w OPVCT
	XBA
	LDA.w OPVCT
	XBA
	REP #$20	; A 16-bit
	AND.w #$01FF
	STA.b SysLoad
	SEP #$20	; A 8-bit
	LDA.w OPHCT
	XBA
	LDA.w OPHCT
	XBA
	REP #$20	; A 16-bit
	AND.w #$01FF
	STA.b SysLoadLo
	REP #$30
; loop infinitely
-	WAI
	BRA -

SplitIRQ:

	PHA
	PHX
	PHP
	REP #$20
	SEP #$10
	LDA $24		; load layer 2 x pos
	LSR			; half it
	TAX
	STX $210F
	XBA
	TAX
	STX $210F
	PLP
	PLX
	PLA
	RTI


incsrc "runframe.asm"
incsrc "sprites.asm"
incsrc "hdma.asm"

VBlank:
	; Currently on the stack: P register, return address
	REP #$30			; A, XY 16-bit
	PHA
	LDA.w DecQRunning
	BEQ +
	; Direct page here must be $0002
	PLA
	STA.b DecQSavedA
	STX.b DecQSavedX
	STY.b DecQSavedY
	SEP #$20			; A 8-bit
	PLA
	STA.b DecQSavedP
	; TODO: right?
	PLA
	STA.b DecQSavedIP
	PLX
	STX.b DecQSavedIP+1
	LDX #0000
	TCD				; reset direct page
	BRA ++
+
	LDA.w GameRunning
	BEQ +
	PHX : PHY
	SEP #$30
	LDA $24
	STA $210F
	LDA $25
	STA $210F
	CLI
	REP #$30
	PLX : PLY
	PLA
	RTI		; Don't update anything if the game is lagging
	; discard the return address and the flags
+
	PLA : PLA : PLA
++
	SEP #$30			; A, XY 8-bit
	; sync camera scroll values
	LDA $20
	STA $210D
	LDA $21
	STA $210D
	LDA $22
	STA $210E
	LDA $23
	STA $210E
	LDA $24
	STA $210F
	LDA $25
	STA $210F
	LDA $26
	STA $2110
	LDA $27
	STA $2110
	JSR DrawAllSprites

	;JSR HDMASetup
	; finish
	LDA #$01
	JMP MainLoop

; IRQ handler

IRQ:
	CMP $4211	; Dummy read
	JMP (IRQPtr)

; DMA queue
; Loads a queue from the first bank. Uses the accumulator as the data pointer.
; Format:
; OP AA AA AA BB BB SS SS
; OP: $00 - load into VRAM
;     $01 - load into CGRAM
;     $02 - load into OAM
;     $FF - quit
LoadDataQueue:
	PHA
	PHY
	PHP
	SEP #$20	; 8-bit A
.loop:
	LDA $00,x	; offset $01: command
	BMI .end	; if $FF, end
	LDY $01,x	; A bus address
	STY $4302
	LDA $03,x
	STA $4304
	LDY $06,x	; Write size
	STY $4305
	LDY $00,x	; read command again
	BEQ .loadCGRAM	; if 0, branch
	CPY #$0001
	BEQ .loadVRAM	; if 1, branch
.loadOAM:
	LDA $04,x	; B bus address in OAM
	STA.w OAMADD
	LDA #%00000000
	STA $4300	; 1 byte increment
	LDA #$04	; Destination: OAM
	STA $4301
	BRA .startDMA
.loadCGRAM:
	LDA $04,x	; B bus address in CGRAM
	STA $2121
	LDA #%00000000
	STA $4300	; 1 byte increment
	LDA #$22	; Destination: CGRAM
	STA $4301
	BRA .startDMA
.loadVRAM:
	LDY $04,x	; B bus address
	STY $2116
	LDA #$80	; Video port control
	STA $2115
	LDA #%00000001	; Word increment mode
	STA $4300
	LDA #$18	; Destination: VRAM
	STA $4301
.startDMA:
	LDA #$01	; Turn on DMA
	STA $420B
	REP #$20
	TXA
	CLC : ADC #$0008
	TAX
	SEP #$20
	BRA .loop	; Loop again
.end:
	PLP
	PLY
	PLA
	RTS


BRK:
-	BRA -

#[bank(01)]
Graphics01:
	incbin "graphics.bin"

BGTilemap01:
	incbin "map4.bin"
	incbin "map3.bin"

Palette:
	dw $7eee, $7fdd, $0000, $0d71, $13ff, $1e9b, $137f, $03ff
	dw $0000, $0000, $194f, $3e78, $573e, $03ff, $7bde, $7c1f
	dw $0000, $7fdd, $0960, $01a4, $01e8, $022c, $0291, $02f5
	dw $7393, $0000, $0cfb, $2feb, $7393, $0000, $7fdd, $2d7f
	dw $0000, $7fdd, $0000, $0daf, $2e79, $25e0, $2b1c, $0320
	dw $0000, $7fff, $0000, $0320, $0016, $001f, $017f, $029f
	dw $0000, $7fdd, $0000, $2d6b, $3def, $4e73, $6318, $739c
	dw $0000, $7fff, $0000, $0320, $347d, $551e, $65ff, $7b1f

