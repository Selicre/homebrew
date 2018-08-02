
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
; Use DrawFullTilemap if you want to re-render an offcenter one.
; Note: this routine can be called in the decompression context. It also clobbers the entirety of scratch space.

#[bank(03)]
DrawStartingTilemap:
	; Set the DBR to the RAM
	PHB
	PEA $7E00
	PLB #2
	PHP
	REP #$20				; A 16-bit
	JSR Render_UpdatePtrs



.line_loop
	LDA #$0000
	SEP #$20				; A 8-bit
	REP #$10				; XY 16-bit
	LDX #$1010
	STX.b Render_TileXY		; initialize both to 16 blocks left to draw
	; init loop counters
	LDX #$0000
	BRA .loop_entry

.line_loop
	REP #$20				; A 16-bit
	TXA						; advance the pointer to the next line
	CLC : ADC.w #$40
	TAX
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
	SEP #$20				; A 8-bit
	BRA .tile_loop

.use_subtable
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

Render_UpdatePtrs:
	PHY
	PHP
	XBA						; << 8
	ASL						; << 1 - Basically, make X go in $200 increments
	PHA
	TAX
	LDA.w LevelMeta+MetaBlockPtr,x		; A now contains the word pointer to main level data
	LDY.w LevelMeta+MetaBlockPtr+2,x		; Y now contains the bank
	SEP #$10				; XY 8-bit
	STA.b Render_BlkPtrM0
	STY.b Render_BlkPtrM0+2
	ADC.w #$0200			; Add $200 to each pointer
	STA.b Render_BlkPtrM2
	STY.b Render_BlkPtrM2+2
	ADC.w #$0400
	STA.b Render_BlkPtrM4
	STY.b Render_BlkPtrM4+2
	ADC.w #$0200
	STA.b Render_BlkPtrM6
	STY.b Render_BlkPtrM6+2
	; TODO: subtable pointers
	PLA
	ASL						; << 2 - $400 increments
	ORA.w #LevelChunks
	STA.b Render_DataPtr
	PLP
	PLY
	RTS


UploadTilemap:
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
	dw $8000, $1000
	db $FF
