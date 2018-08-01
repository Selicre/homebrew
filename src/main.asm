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

	; Clean memory
	LDX #$0000
-	INX
	STZ $00,x
	CPX #$05FF
	BNE -
	; Set up gamemode
	LDA #$0000
	STA.b Gamemode
	JSR InitSprites
	JSR ResetSprites

	LDA.w #VBlank_DoNothingRTI
	STA.b VBlankPtr
	STA.b IRQPtr

	LDA.w #VBlank_DoNothing
	STA.w RunFrame_VBlank

	SEP #$30
	LDA #%00001111	; end vblank, setting brightness to 15
	STA.w INIDISP

	LDA #%10100001	; enable NMI, IRQ & joypad
	STA.w NMITIMEN

MainLoop:
	REP #$30
	JSR RunFrame

; loop infinitely
-	WAI
	BRA -

VBlank_DoNothingRTI:
	RTI


VBlank:
	JMP (VBlankPtr)


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
	LDA $0000,x	; offset $01: command
	BMI .end	; if $FF, end
	LDY $0001,x	; A bus address
	STY $4302
	LDA $0003,x
	STA $4304
	LDY $0006,x	; Write size
	STY $4305
	LDA $0000,x	; read command again
	BEQ .loadCGRAM	; if 0, branch
	CMP #$01
	BEQ .loadVRAM	; if 1, branch
.loadOAM:
	; Note: fix pls
	LDA $0004,x	; B bus address in OAM
	STA.w OAMADD
	LDA #%00000000
	STA $4300	; 1 byte increment
	LDA #$04	; Destination: OAM
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


BRK:
-	BRA -

incsrc "sprites.asm"
incsrc "hdma.asm"

#[bank(01)]
Graphics01:
	incbin "gfx_level.bin"

BGTilemap01:
	incbin "map_level.bin"
	incbin "map_bg.bin"

GFXLogo:
	incbin "gfx_logo.bin"
GFXLogoEnd:
	define GFXLogoSize GFXLogoEnd-GFXLogo
GFXLogoPal:
	incbin "logo0.pal"
	incbin "logo1.pal"
GFXLogoPalEnd:
	define GFXLogoPalSize GFXLogoPalEnd-GFXLogoPal


GFXLogoMap:
	incbin "map_logo.bin"
GFXLogoMapEnd:
	define GFXLogoMapSize GFXLogoMapEnd-GFXLogoMap

Palette:
	incbin "../build/palette.pal"
	dw $7eee, $7fdd, $0000, $0d71, $13ff, $1e9b, $137f, $03ff
	dw $0000, $0000, $194f, $3e78, $573e, $03ff, $7bde, $7c1f
	dw $0000, $7fdd, $0960, $01a4, $01e8, $022c, $0291, $02f5
	dw $7393, $0000, $0cfb, $2feb, $7393, $0000, $7fdd, $2d7f
	dw $0000, $7fdd, $0000, $0daf, $2e79, $25e0, $2b1c, $0320
	dw $0000, $7fff, $0000, $0320, $0016, $001f, $017f, $029f
	dw $0000, $7fdd, $0000, $2d6b, $3def, $4e73, $6318, $739c
	dw $0000, $7fff, $0000, $0320, $347d, $551e, $65ff, $7b1f

incsrc "runframe.asm"
