; main asm source file
; over here will be global attributes, linker data, etc.
incsrc "lib/registers.asm"
incsrc "ram.asm"

#[start]
Start:
	JML RealStart
RealStart:
	SEI				; disable interrupts
	CLC : XCE		; switch to native mode
	SEP #$30		; A and XY 8-bit
	LDA.b #$01
	STA.w MEMSEL	; fast rom access
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

	; Clean memory
	STZ.w WMADDL
	STZ.w WMADDH
	LDA #$8008
.zero
	STA $4300
	LDA.w #.zero+1
	STA $4302
	LDA.w #(.zero+1)>>8
	STA $4303
	STZ $4305
	SEP #$10
	LDY #$01
	STY.w MDMAEN
	STY.w MDMAEN
	REP #$10

	; Set up gamemode
	LDA #$0000
	STA.b Gamemode
	JSR InitSprites
	JSR ResetSprites

	LDA.w #$0040			; RTI
	STA.b NMIVector
	STA.b IRQVector
	LDA.w #$8000			; bank $80
	STA.b NMIVector+2
	STA.b IRQVector+2

	LDA.w #VBlank_DoNothing
	STA.w NMIPtr

	SEP #$30
	LDA #%00001111	; end vblank, setting brightness to 15
	STA.w INIDISP

	LDA #%10100001	; enable NMI, IRQ & joypad
	STA.w NMITIMEN

	JMP RunFrame

; IRQ handler

;#[irq]
;IRQ:
;	CMP $4211	; Dummy read
;	JMP (IRQPtr)

; DMA queue
; Loads a queue from the first bank. Uses the accumulator as the data pointer.
; Format:
; OP AA AA AA BB BB SS SS
; OP: $00 - load into VRAM
;     $01 - load into CGRAM
;     $02 - load into OAM
;     $03 - load into WRAM
;     $FF - quit
; ergh, this would be way easier as a macro
LoadDataQueue:
	PHA
	PHY
	PHP
	SEP #$20	; 8-bit A
.loop:
	LDA $0000,x		; offset $01: command
	BMI .end		; if $FF, end
	LDY $0001,x		; A bus address
	STY $4302
	LDA $0003,x
	STA $4304
	LDY $0006,x		; Write size
	STY $4305
	LDA $0000,x		; read command again
	BEQ .loadCGRAM	; if 0, CGRAM
	CMP #$01
	BEQ .loadVRAM	; if 1, VRAM
	CMP #$02
	BEQ .loadOAM	; if 2, OAM
;	CMP #$03
;	BEQ .loadWRAM
;.loadVRAMColumns:
;	LDY $0004,x	; B bus address
;	STY $2116
;	LDA #$81	; Video port control
;	STA $2115
;	LDA #%00000001	; Word increment mode
;	STA $4300
;	LDA #$18	; Destination: VRAM
;	STA $4301
;	BRA .startDMA
.loadWRAM:			; if 3, WRAM
	LDY $0004,x		; address in WRAM
	STY.w WMADD
	LDA #%00000000
	STA $4300		; 1 byte increment
	LDA.b #WMDATA	; Destination: WRAM
	STA $4301
	BRA .startDMA
.loadCGRAM:
	LDA $0004,x	; B bus address in CGRAM
	STA $2121
	LDA #%00000000
	STA $4300	; 1 byte increment
	LDA #$22	; Destination: CGRAM
	STA $4301
	BRA .startDMA
.loadVRAM:
	LDY $0004,x	; B bus address
	STY $2116
	LDA #$80	; Video port control
	STA $2115
	LDA #%00000001	; Word increment mode
	STA $4300
	LDA #$18	; Destination: VRAM
	STA $4301
	BRA .startDMA
.loadOAM:
	LDY $0004,x		; B bus address in OAM
	STY.w OAMADD
	LDA #%00000000
	STA $4300		; 1 byte increment
	LDA #$04		; Destination: OAM
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
	RTL

; FUCK. Let's just slap a TODO on this garbage.
LoadDataQueueVRAMColumn:
	PHA
	PHY
	PHP
	SEP #$20	; 8-bit A
.loop:
	LDA $0000,x		; offset $01: command
	BMI .end		; if $FF, end
	LDY $0001,x		; A bus address
	STY $4302
	LDA $0003,x
	STA $4304
	LDY $0006,x		; Write size
	STY $4305
	LDA $0000,x		; read command again
.loadVRAM:
	LDY $0004,x	; B bus address
	STY $2116
	LDA #$81	; Video port control
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
	RTL

#[brk]
BRK:
-	BRA -

incsrc "sprites.asm"
incsrc "hdma.asm"

incsrc "chunks.asm"
incsrc "imagedata.asm"

incsrc "runframe.asm"
incsrc "renderer/scrollmgr.asm"
incsrc "renderer/level.asm"

incsrc "objects/objectmgr.asm"
incsrc "objects/bouncy_flower.asm"
incsrc "objects/debug_ctlr.asm"
