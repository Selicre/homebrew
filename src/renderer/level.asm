
; Level tilemap renderer.
; The level layout is looped like this:
; 12341234
; 34123412
; 12341234
; This allows for efficient rendering of both horizontal and vertical levels (although a separate vertical mode may be introduced).
; Note that just `1234` is already 25% of the original SMW level size.

define Render_TileXY	$00
define Render_TileX		$00		; Current x tile index
define Render_TileY		$01		; Current y tile index
define Render_DataPtr	$02		; Pointer to level data
define Render_ChunkInd	$04		; Chunk index
define Render_ChunkIndS	$05		; Chunk index to start drawing from after the seam
define Render_BlkPtrM0	$08		; Long pointer to main block mappings
define Render_BlkPtrM2	$0B		; + 3
define Render_BlkPtrM4	$0E		; + 6
define Render_BlkPtrM6	$11		; + 9
define Render_BlkPtrS0	$14		; Same but for sub block mappings
define Render_BlkPtrS2	$17
define Render_BlkPtrS4	$1A
define Render_BlkPtrS6	$1D


; A is the chunk index, from 0 to 3.
; This will only render the tilemap to the VRAM buffer, not actually transfer anything.
; This routine is faster, but it only draws a centered tilemap.
; Use DrawFullTilemap if you want to fully re-render an offcenter one.
; Note: this routine can be called in the decompression context. It also clobbers the entirety of scratch space.

#[bank(03)]
DrawStartingTilemap:
	; Set the DBR to the RAM
	PHB
	PEA $7E00
	PLB #2
	PHP
	REP #$20				; A 16-bit
	STZ.b Render_DataPtr
	JSR Render_UpdatePtrs


;.line_loop
	LDA #$0000
	SEP #$20				; A 8-bit
	REP #$10				; XY 16-bit
	; TODO: rewrite to only use one counter?
	LDX #$2010
	STX.b Render_TileXY		; initialize counters to 32x16 of blocks left to draw
	; init index into chunk
	LDX #$0000
	BRA .loop_entry

.line_loop
	REP #$20				; A 16-bit
	TXA
	EOR #$0840				; switch tilemaps
	BIT #$0800				; what map are we on?
	BNE +
	CLC : ADC #$0080		; go to next row if the second one
+	TAX
	LDA #$0000
	SEP #$20
	DEC.b Render_TileY
	BEQ .end				; if y = 0, we're finished
	LDA #$11				; otherwise, draw 10 blocks again
	STA.b Render_TileX
.tile_loop
	DEC.b Render_TileX
	BEQ .line_loop			; if x = 0, go to next block line
	; MAIN SHIT HAPPENING HERE
	; Get block mappings

.loop_entry
	LDA.b (Render_DataPtr)
	BMI	.use_subtable
	ASL
	TAY
	REP #$20				; A 16-bit
	LDA.b [Render_BlkPtrM0],y
	STA.w VRAMBuffer+$00,x
	LDA.b [Render_BlkPtrM2],y
	STA.w VRAMBuffer+$02,x
	LDA.b [Render_BlkPtrM4],y
	STA.w VRAMBuffer+$40,x
	LDA.b [Render_BlkPtrM6],y
	STA.w VRAMBuffer+$42,x
	INC.b Render_DataPtr
	INX.b #4
	LDA #$0000
	SEP #$20				; A 8-bit
	BRA .tile_loop

.use_subtable
	ASL
	TAY
	REP #$20				; A 16-bit
	LDA.b [Render_BlkPtrS0],y
	STA.w VRAMBuffer+$00,x
	LDA.b [Render_BlkPtrS2],y
	STA.w VRAMBuffer+$02,x
	LDA.b [Render_BlkPtrS4],y
	STA.w VRAMBuffer+$40,x
	LDA.b [Render_BlkPtrS6],y
	STA.w VRAMBuffer+$42,x
	INC.b Render_DataPtr
	INX.b #4
	SEP #$20				; A 8-bit
	BRA .tile_loop
.end
	PLP
	PLB
	RTL

; Updates the long pointers in scratch RAM. A is the chunk ID.
Render_UpdatePtrs:
	PHY
	PHP
	XBA						; << 8
	ASL						; << 1 - Basically, make X go in $200 increments
	PHA
	TAX
	LDA.w LevelMeta+MetaBlockPtr,x		; A now contains the word pointer to main level data
	LDY.w LevelMeta+MetaBlockPtr+2,x		; Y now contains the bank
	CLC
	SEP #$10				; XY 8-bit
	STA.b Render_BlkPtrM0
	STY.b Render_BlkPtrM0+2
	ADC.w #$0100			; Add $100 to each pointer
	STA.b Render_BlkPtrM2
	STY.b Render_BlkPtrM2+2
	ADC.w #$0100
	STA.b Render_BlkPtrM4
	STY.b Render_BlkPtrM4+2
	ADC.w #$0100
	STA.b Render_BlkPtrM6
	STY.b Render_BlkPtrM6+2

	LDA.w LevelMeta+MetaSubBlockPtr,x		; A now contains the word pointer to main level data
	LDY.w LevelMeta+MetaSubBlockPtr+2,x		; Y now contains the bank
	CLC
	SEP #$10				; XY 8-bit
	STA.b Render_BlkPtrS0
	STY.b Render_BlkPtrS0+2
	ADC.w #$0100			; Add $100 to each pointer
	STA.b Render_BlkPtrS2
	STY.b Render_BlkPtrS2+2
	ADC.w #$0100
	STA.b Render_BlkPtrS4
	STY.b Render_BlkPtrS4+2
	ADC.w #$0100
	STA.b Render_BlkPtrS6
	STY.b Render_BlkPtrS6+2
	; TODO: subtable pointers
	PLA
	ASL						; << 2 - $400 increments
	ORA.w #LevelChunks
	ORA.b Render_DataPtr
	STA.b Render_DataPtr
	PLP
	PLY
	RTS

; Vertical scrolling routine
; Put the camera offset to redraw in A (should be divisible by $10) - e.g. $F0 for scrolling downward.
; TODO: optimize it to where it only draws the visible part.

DrawTilemapRow:
	; Set the DBR to the RAM
	PHB
	PEA $7E00
	PLB #2

	PHA					; stack +2
	LDA.w CamX
	; Get the block ID of when to switch drawing to a different chunk
	LSR : LSR : LSR : LSR
	SEC : SBC #$0004	; push it 4 blocks away from the camera
	PHA					; stack +2

	LDA 3,s				; Get the row
	CLC : ADC.w CamY	; get the rendered row camera position
	PHA					; set ScrollBuf data here
	AND #$03F0
	ASL
	STA.w Render_DataPtr	; maybe?
	ASL
	AND #$03C0
	ORA #$4000
	STA.w VScrollBufTarget	; - correct
	LDA #$0080			; for now, only $80 is supported
	STA.w VScrollBufSize

	; Locate the horizontal chunk seam
	LDA.w CamX
	SEP #$20			; A 8-bit
	XBA
	LSR
	STA $00				; save the chunk ID here (maybe put in Y?)
	PLA					; stack -2
	PLA
	;XBA					; get the 512px high index
	LSR

	AND #$02			; get the current chunk index
	ADC $00				; get chunk ID
	AND #$03
	
	REP #$20			; A 16-bit
	LDA #$0000			; for now
	JSR Render_UpdatePtrs

	; TEMP STUFF

	; END TEMP STUFF

	LDX.w VRAMBufferPtr	; Index into VRAMBuffer
	STX.w VScrollBufPtr
	LDA #$0000
	SEP #$20			; A 8-bit
	LDA #$21			; $20 tiles to draw (+1 for initial dec)
	STA.b Render_TileX
.tile_loop
	DEC.b Render_TileX
	BEQ .end			; if x = 0, we are done boys
	LDA.b Render_TileX
	CMP #$10			; if x = 10, switch to the other plane
	BNE +
	REP #$20				; A 16-bit
	TXA
	CLC : ADC #$0040				; switch plane
	TAX
	LDA #$0000
	SEP #$20
+
	; Get block mappings
	LDA.b (Render_DataPtr)
	BMI .use_subtable
	ASL
	TAY
	REP #$20				; A 16-bit
	LDA.b [Render_BlkPtrM0],y
	STA.w $00,x
	LDA.b [Render_BlkPtrM2],y
	STA.w $02,x
	LDA.b [Render_BlkPtrM4],y
	STA.w $40,x
	LDA.b [Render_BlkPtrM6],y
	STA.w $42,x
	INC.b Render_DataPtr
	INX.b #4
	LDA #$0000
	SEP #$20				; A 8-bit
	BRA .tile_loop

.use_subtable
	ASL
	TAY
	REP #$20				; A 16-bit
	LDA.b [Render_BlkPtrS0],y
	STA.w $00,x
	LDA.b [Render_BlkPtrS2],y
	STA.w $02,x
	LDA.b [Render_BlkPtrS4],y
	STA.w $40,x
	LDA.b [Render_BlkPtrS6],y
	STA.w $42,x
	INC.b Render_DataPtr
	INX.b #4
	LDA #$0000
	SEP #$20				; A 8-bit
	BRA .tile_loop
.end
	REP #$30
	STX.w VRAMBufferPtr		; save the VRAM offset
	PLA						; stack -2
	PLA						; stack -2
	PLB
	RTL


UploadBuffer:
	PHP
	REP #$30
	PHB
	PHK
	PLB
	LDX.w #.queue
	JSL LoadDataQueue
	PLB
	PLP
	RTL
.queue
	db $01
	dl VRAMBuffer
	dw $4000, $1000
	db $FF

InitVRAMBuffers:
	; TODO: use VRAMBufferStart instead
	LDA.w #VRAMBuffer
	STA.w VRAMBufferPtr
	LDA.w #$0000
	STA.w VScrollBufPtr
	STA.w HScrollBufPtr
	RTL

; TODO: this will be a general purpose DMA queue
UploadScrollBuffer:
	PHP
	REP #$20
	SEP #$10
	; Put the queue in RAM
	; TODO: maybe reduce copying?
	; abank|mode, a, b, s
	LDA.w VScrollBufPtr
	BEQ +		; if there's nothing in the queue, leave
	STA $01
	;LDA.w #(VRAMBuffer>>16)<<8|$01

	LDY #$01	; VRAM mode
	STY $00
	LDY #$7E	; bank
	STY $03
	LDA.w VScrollBufTarget
	STA $04
	LDA.w VScrollBufSize
	STA $06
	; the second plane
	;LDA.w #(VRAMBuffer>>16)<<8|$01
	LDY #$01	; VRAM mode
	STY $08
	LDY #$7E	; bank
	STY $0B
	LDA.w VScrollBufPtr
	CLC : ADC.w VScrollBufSize
	STA $09
	LDA.w VScrollBufTarget
	ORA #$0400	; second plane
	STA $0C
	LDA.w VScrollBufSize
	STA $0E
	LDA.w #$00FF
	STA $10
	REP #$10
	LDX.w #$0000
	JSL LoadDataQueue
+
	PLP
	RTL


;UploadScrollBuffer:
	PHP
	REP #$30
	PHB
	PHK
	PLB
	LDX.w #.queue
	JSL LoadDataQueue
	PLB
	PLP
	RTL
.queue
	db $01
	dl VRAMBuffer
	dw $4000, $0020
	db $FF
