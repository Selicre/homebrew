
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
define Render_SOffset	$05		; Seam offset
define Render_BlkPtrM0	$08		; Long pointer to main block mappings
define Render_BlkPtrM2	$0B		; + 3
define Render_BlkPtrM4	$0E		; + 6
define Render_BlkPtrM6	$11		; + 9
define Render_BlkPtrS0	$14		; Same but for sub block mappings
define Render_BlkPtrS2	$17
define Render_BlkPtrS4	$1A
define Render_BlkPtrS6	$1D

define Render_SeamChg	$0F20	; This location will be invalidated by the routine, so it's fine to reuse it


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
	PHX
	PHP
	AND #$00FF
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
	PLA
	ASL						; << 2 - $400 increments
	ORA.w #LevelChunks
	PHA
	LDA.b Render_DataPtr
	ORA 1,s
	STA.b Render_DataPtr
	PLA
	PLP
	PLX
	PLY
	RTS

; Horizontal scrolling routine
; A is the column offset
; TODO: pull seams from elsewhere

DrawTilemapColumn:
	; Set the DBR to the RAM
	PHB
	PEA $7E00
	PLB #2
	
	;CLC : ADC.w CamX		; get the rendered column camera position
	;AND.w #$7F0				; clamp and coarse
	AND.w #$7F0
	PHA						; stack +2

	; WE NEED: DataPtr, Render_SOffset
	LSR						; get tilemap VRAM address
	LSR
	LSR
	AND #$003E
	BIT #$0020				; Second plane?
	BEQ +
	EOR #$0420				; Put onto the actual second plane
+
	ORA.w #$4000
	STA.w HScrollBufTarget	; Put as VRAM target
	LDA.w #$0001			; 1 block column only for now
	STA.w HScrollBufSize

	LDA 1,s
	LSR : LSR : LSR : LSR
	AND.w #$001F			; get block position
	STA.w Render_DataPtr
	

	LDA.w VScrollSeam
	SEC : SBC.w #$0100
	AND.w #$7F0				; clamp and coarse
	;SEC : SBC #$0010		; push it 1 block away from the camera
	PHA						; stack +2
	LSR : LSR : LSR : LSR
	SEP #$20				; A 8-bit
	EOR #$0F				; negate
	INC
	AND #$0F				; clamp
	STA.b Render_SOffset	; store
	STA.b $52
	
	LDA 2,s
	AND #$02				; get the current chunk index
	STA $00					; save the chunk ID here
	
	LDA 4,s					; get the 512px high index
	AND #$07
	LSR
	EOR $00			; get chunk ID
	STA.b Render_ChunkInd


	LDY.w #.changeChunk
	LDA 2,s				; high byte of rendered row
	BIT #$01
	BNE +
	REP #$20
	LDA.w Render_DataPtr
	CLC : ADC.w #$0200					; start from bottom row
	STA.w Render_DataPtr
	STA.b $54
	SEP #$20
	LDY.w #.keepChunk
	BRA ++
+
	;REP #$20
	;LDA.b Render_DataPtr
	;AND.w #$01FF
	;STA.b Render_DataPtr
	;SEP #$20
	LDA.b Render_ChunkInd
	EOR #$02
	STA.b Render_ChunkInd
++	STY.w Render_SeamChg

	LDA.b #$00
	XBA
	LDA.b Render_ChunkInd
	REP #$30
	JSR Render_UpdatePtrs
	LDA.w #$0000
	LDX.w VRAMBufferPtr		; Index into VRAMBuffer
	STX.w HScrollBufPtr
	SEP #$20				; A 8-bit
	LDA #$11				; $10 tiles to draw (+1 for initial dec)
	STA.b Render_TileY

	; Test if we need to change the seam right now

	LDA.b Render_SOffset
	BNE +
	PEA.w ..end-1			; DIY JSR
	JMP (Render_SeamChg)
..end
+

.tile_loop
	DEC.b Render_TileY
	BEQ .end				; if x = 0, we are done boys
	LDA.b Render_TileY
	CMP.b Render_SOffset	; if x = chunk seam..
	BNE ..end
	PEA.w ..end-1			; DIY JSR
	JMP (Render_SeamChg)
..end
	; Get block mappings
	LDA.b (Render_DataPtr)
	BMI .use_subtable
	ASL
	TAY
	REP #$20				; A 16-bit
	LDA.b [Render_BlkPtrM0],y	; the buffer is transposed
	STA.w $00,x
	LDA.b [Render_BlkPtrM2],y
	STA.w $40,x
	LDA.b [Render_BlkPtrM4],y
	STA.w $02,x
	LDA.b [Render_BlkPtrM6],y
	STA.w $42,x
	LDA.b Render_DataPtr
	CLC : ADC.w #$0020
	STA.b Render_DataPtr
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
	STA.w $40,x
	LDA.b [Render_BlkPtrS4],y
	STA.w $02,x
	LDA.b [Render_BlkPtrS6],y
	STA.w $42,x
	LDA.b Render_DataPtr
	CLC : ADC.w #$0010
	STA.b Render_DataPtr
	INX.b #4
	LDA #$0000
	SEP #$20				; A 8-bit
	BRA .tile_loop
.end
	REP #$30
	TXA
	ADC.w #$0040			; Seek to end of buffer
	STA.w VRAMBufferPtr		; save the VRAM offset
	PLA						; stack -2
	PLA						; stack -2
	PLB
	RTL
.changeChunk:
	REP #$20
	LDA.w Render_DataPtr
	AND #$01FF					; clamp
	STA.w Render_DataPtr
	SEP #$20
	LDA.b Render_ChunkInd
	EOR #$02
	REP #$20

	;AND #$00FF
	JSR Render_UpdatePtrs
	LDA.w Render_DataPtr
	CLC : ADC.w #$0200					; start from bottom row
	STA.w Render_DataPtr
	LDA #$0000
	SEP #$20
	RTS

.keepChunk:
	REP #$20
	LDA.w Render_DataPtr
	SEC : SBC.w #$0200					; start from bottom row
	STA.w Render_DataPtr
	LDA #$0000
	SEP #$20
	RTS


; Vertical scrolling routine
; Put the camera offset to redraw in A (should be divisible by $10) - e.g. $F0 for scrolling downward.
; TODO: optimize it to where it only draws the visible part.
; TODO: fetch the seams from elsewhere

DrawTilemapRow:
	; Set the DBR to the RAM
	PHB
	PEA $7E00
	PLB #2

;	CLC : ADC.w CamY		; get the rendered row camera position
;	AND.w #$7FF				; clamp
	AND.w #$7F0
	PHA						; stack +2

	;LDA 1,s				; Get the row
	AND #$01F0
	ASL
	STA.w Render_DataPtr	; get chunk
	ASL
	AND #$03C0
	ORA #$4000
	STA.w VScrollBufTarget
	LDA #$0080				; for now, only $80 (one row) is supported
	STA.w VScrollBufSize

	LDA.w HScrollSeam
	AND.w #$7F0				; clamp
	; Locate the horizontal chunk seam
	; Get the block ID of when to switch drawing to a different chunk
	LSR : LSR : LSR : LSR
	SEP #$30				; AXY 8-bit
	;SEC : SBC #$08			; push it 8 blocks away from the camera
	EOR #$1F				; negate
	INC
	AND #$1F				; clamp
	STA.b Render_SOffset	; store
	STA.b $50

	LDA 2,s					; high byte of rendered row
	AND #$02				; get the current chunk index
	STA $00					; save the chunk ID here
	
	REP #$20
	LDA.w HScrollSeam				; get the 512px high index
	XBA
	SEP #$20
;	DEC
	AND #$07
	LSR
	EOR $00			; get chunk ID
	LDY.b Render_SOffset
	CPY #$08
	BMI +
;	INC						; start drawing with a previous chunk?
+	AND #$03
	STA.b Render_ChunkInd
	REP #$30				; AXY 16-bit
	JSR Render_UpdatePtrs

	LDX.w VRAMBufferPtr		; Index into VRAMBuffer
	STX.w VScrollBufPtr
	LDA #$0000
	SEP #$20				; A 8-bit
	LDA #$21				; $20 tiles to draw (+1 for initial dec)
	STA.b Render_TileX

	; if chunk seam is at 0
	LDA.b Render_SOffset
	BNE +
	LDA.b Render_ChunkInd
	DEC
	AND #$03
	STA.b Render_ChunkInd
	REP #$20
	PHA
	LDA.b Render_DataPtr
	AND #$03FF
	STA.b Render_DataPtr
	PLA
	JSR Render_UpdatePtrs
	LDA #$0000
	SEP #$20
+


.tile_loop
	DEC.b Render_TileX
	BNE .notend				; if x = 0, we are done boys
	JMP .end
.notend
	LDA.b Render_TileX
	CMP #$10				; if x = 10, switch to the other plane
	BNE +
	REP #$20				; A 16-bit
	TXA
	CLC : ADC #$0040		; switch plane
	TAX
	LDA #$0000
	SEP #$20
	LDA.b Render_TileX
+
	CMP.b Render_SOffset	; if x = chunk seam..
	BNE +
	LDA.b Render_ChunkInd
	DEC
	AND #$03
	STA.b Render_ChunkInd
	REP #$20
	PHA
	LDA.b Render_DataPtr
	AND #$03FF
	STA.b Render_DataPtr
	PLA
	JSR Render_UpdatePtrs
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
	TAX
	ADC.w #$0040			; seek to end of buffer
	STA.w VRAMBufferPtr		; save the VRAM offset
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
	SEP #$10
+
	LDA.w HScrollBufPtr
	BEQ +		; if there's nothing in the queue, leave
	STA $01
	LDY #$04	; VRAM columns mode
	STY $00
	LDY #$7E	; bank
	STY $03
	LDA.w HScrollBufTarget
	STA $04
	LDA.w HScrollBufSize
	LDA.w #$0040
	STA $06
	; the second plane
	;LDA.w #(VRAMBuffer>>16)<<8|$01
	LDY #$04	; VRAM columns mode
	STY $08
	LDY #$7E	; bank
	STY $0B
	LDA.w HScrollBufPtr
	CLC : ADC #$0040	; second plane
	STA $09
	LDA.w HScrollBufTarget
	INC			; next column in 1 word
	STA $0C
	LDA.w HScrollBufSize
	LDA.w #$0040
	STA $0E
	LDA.w #$00FF
	STA $10

	REP #$10
	LDX.w #$0000
	JSL LoadDataQueueVRAMColumn
	SEP #$10
+
	PLP
	RTL


; X/Y as pixel params, output: block ID in A, block collision in B

GetBlockAt:
	PHX
	PHY
	SEP #$20				; A 8-bit
	LDA 2,s					; high byte of row
	LSR
	AND #$02				; get the current chunk index
	STA.w $00				; save the chunk ID here
	
	LDA 4,s					; high byte of column
	LSR
	EOR.w $00				; get chunk ID
	REP #$20
	AND #$03
	XBA
	ASL : ASL
	PHA
	LDA 3,s					; row
	AND #$FFF0
	ASL						; get Y block offset
	STA 3,s
	LDA 5,s					; column
	LSR : LSR : LSR : LSR
	AND #$001F				; clamp to chunk
	CLC : ADC 3,s
	ORA 1,s					; add chunk coords
	TAX
	LDA.l LevelChunks,x
	AND #$00FF
	PLX
	PLX
	PLY
	RTL
