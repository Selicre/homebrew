
; Level tilemap renderer.
; The level layout is looped like this:
; 12341234
; 34123412
; 12341234
; This allows for efficient rendering of both horizontal and vertical levels (although a separate vertical mode may be introduced).
; Note that just `1234` is already 25% of the original SMW level size.

define Render_Tile		$00		; Current tile index (16-bit)
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
	STX.b Render_Tile		; initialize counters to 32x16 of blocks left to draw
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
; A is the column offset.

; Costs 19666 cycles when changing chunks, 18138 when not.

DrawTilemapColumn:
	; Set the DBR to the RAM
	PHB
	PEA $7E00
	PLB #2
	
	AND.w #$7F0
	PHA						; stack +2

	; GET VRAM TARGET

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

	; GET SCROLL SEAM POSITIONING

	LDA.w VScrollSeam
	SEC : SBC.w #$0100		; TODO: make the scroll seam itself save like this
	AND.w #$7F0				; clamp
	PHA						; save
	LSR : LSR : LSR : LSR
	SEP #$20				; A 8-bit
	EOR #$0F				; negate
	AND #$0F				; clamp to 1..10
	INC
	STA.b Render_SOffset	; store

	; GET CURRENT CHUNK

	LDA 2,s
	AND #$02				; get the current chunk index
	STA $00					; save the chunk ID here
	
	LDA 4,s					; get the 512px high index
	AND #$07
	LSR
	EOR $00			; get chunk ID
	STA.b Render_ChunkInd

	; GET WHETHER TO CHANGE THE CHUNK

	LDY.w #.changeChunk
	LDA 2,s					; high byte of rendered row
	BIT #$01
	BNE +
	; Keep the chunk
	REP #$20
	LDA.w Render_DataPtr
	CLC : ADC.w #$0200		; start from bottom row
	STA.w Render_DataPtr
	SEP #$20
	LDY.w #.keepChunk
	BRA ++
+
	; Change the chunk
	LDA.b Render_ChunkInd
	EOR #$02
	STA.b Render_ChunkInd
++	STY.w Render_SeamChg

	REP #$30
	LDA.b Render_ChunkInd
	AND.w #$00FF
	JSR Render_UpdatePtrs
	
	LDX.w VRAMBufferPtr		; Index into VRAMBuffer
	STX.w HScrollBufPtr

	LDA.w Render_SOffset	; TODO: move this onto the stack to begin with
	AND.w #$00FF
	PHA

	LDA.w #$0010			; $10 tiles to draw
	STA.b Render_Tile

.tile_loop
	BEQ .end				; Jumped to with flags from DEC.b Render_Tile
	LDA.b Render_Tile
	CMP.b 1,s				; if x = chunk seam..
	BEQ .seamchg
.after_seamchg
	; Get block mappings
	SEP #$20				; A 8-bit
	LDA.b (Render_DataPtr)
	REP #$20				; A 16-bit
	BMI .use_subtable
	ASL
	TAY
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
	DEC.b Render_Tile
	BRA .tile_loop

.use_subtable
	ASL
	TAY
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
	DEC.b Render_Tile
	BRA .tile_loop
.seamchg
	JMP (Render_SeamChg)
.end
	REP #$30
	TXA
	ADC.w #$0040			; Seek to end of buffer
	STA.w VRAMBufferPtr		; save the VRAM offset
	PLA						; stack -2
	PLA						; stack -2
	PLA						; stack -2
	PLB
	RTL
.changeChunk:
	LDA.w Render_DataPtr
	AND #$01FF					; clamp
	STA.w Render_DataPtr
	LDA.b Render_ChunkInd
	EOR #$0002

	AND #$00FF
	JSR Render_UpdatePtrs
	LDA.w Render_DataPtr
	CLC : ADC.w #$0200					; start from bottom row
	STA.w Render_DataPtr
	LDA #$0000
	JMP .after_seamchg

.keepChunk:
	LDA.w Render_DataPtr
	SEC : SBC.w #$0200					; start from bottom row
	STA.w Render_DataPtr
	LDA #$0000
	JMP .after_seamchg


; Vertical scrolling routine
; Put the camera offset to redraw in A (should be divisible by $10) - e.g. $F0 for scrolling downward.
; TODO: optimize it to where it only draws the visible part.

; Costs 33470 cycles.

DrawTilemapRow:
	; Set the DBR to the RAM
	PHB
	PEA $7E00
	PLB #2

	AND.w #$7F0
	PHA						; stack +2

	; GET VRAM TARGET

	AND #$01F0
	ASL
	STA.w Render_DataPtr	; get chunk
	ASL
	AND #$03C0
	ORA #$4000
	STA.w VScrollBufTarget
	LDA #$0080				; for now, only $80 (one row) is supported
	STA.w VScrollBufSize

	; GET SEAM POSITION

	LDA.w HScrollSeam
	AND.w #$7F0				; clamp
	; Locate the horizontal chunk seam
	LSR : LSR : LSR : LSR	; this cleans top of A
	SEP #$30				; AXY 8-bit
	EOR #$1F				; negate
	AND #$1F				; clamp	to 1..20
	INC
	STA.b Render_SOffset	; store

	; GET CHUNK INDEX

	LDA 2,s					; high byte of rendered row
	AND #$02				; get the current chunk index
	STA $00					; save the chunk ID here
	
	LDA.w HScrollSeam+1		; get the chunk index
	AND #$07
	LSR
	EOR $00			; get chunk ID
	STA.b Render_ChunkInd

	REP #$30				; AXY 16-bit, top of A clear
	JSR Render_UpdatePtrs

	LDA.w Render_SOffset	; TODO: move this onto the stack to begin with
	AND.w #$00FF
	PHA

	LDX.w VRAMBufferPtr		; Index into VRAMBuffer
	STX.w VScrollBufPtr
	LDA #$0020				; $20 tiles to draw
	STA.b Render_Tile

.tile_loop
	BEQ .end				; jumped to from DEC.b Render_Tile
	LDA.b Render_Tile
	CMP #$0010				; if x = 10, switch to the other plane
	BNE +
	TXA
	CLC : ADC #$0040		; switch plane
	TAX
	LDA.b Render_Tile
+
	CMP 1,s					; if x = chunk seam..
	BEQ .seam				; optimize for branch not taken - saves 20 - 3 = 17 cycles
.seam_ret
	; Get block mappings
	SEP #$20
	LDA.b (Render_DataPtr)
	REP #$20
	BMI .use_subtable
	ASL
	TAY
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
	DEC.b Render_Tile
	BRA .tile_loop
.use_subtable
	ASL
	TAY
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
	DEC.b Render_Tile
	BRA .tile_loop
.seam
	SEP #$20
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
	BRA .seam_ret
.end
	REP #$30
	TAX
	ADC.w #$0040			; seek to end of buffer
	STA.w VRAMBufferPtr		; save the VRAM offset
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


; X/Y as pixel params, output: block ID in A, collision in B

GetBlockAt:
	PHY
	PHX
	PHY
	LDA #$0000				; clear top of A
	SEP #$20				; A 8-bit
	LDA 2,s					; high byte of row
	AND #$02				; get the current chunk index
	PEA $0000
	STA 2,s					; save the partial chunk ID here

	LDA 6,s					; high byte of column
	LSR
	AND #$03
	EOR 2,s				; get chunk ID
	
	STA $005A
	
	ASL : ASL
	STA 2,s
	REP #$20

	LDA 3,s					; row
	AND #$1F0
	ASL						; get Y block offset
	STA 3,s					; todo: maybe try to do it without this?

	LDA 5,s					; column
	LSR : LSR : LSR : LSR
	AND #$001F				; clamp to chunk
	CLC : ADC 3,s
	ORA 1,s					; add chunk coords
	TAX
	STX $0058
	LDA.l LevelChunks,x
	AND #$00FF
	PLX
	PLY
	PLX
	PLY
	RTL
