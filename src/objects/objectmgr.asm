; Object manager code - loads and processes all sprite-based objects on screen
; Object data is stored progressively. Object code can access it via direct page.
; A simple object's X/Y position is the top left of its collision box.

; Common offsets

define obj_ID		$00		; long
define obj_Mappings	$03		; long
define obj_XSubpx	$06
define obj_XPos		$07
; unused byte
define obj_YSubpx	$0A		; overlapping words
define obj_YPos		$0B
; unused byte
define obj_Size		$0E
define obj_Width	$0E		; byte
define obj_Height	$0F		; byte
define obj_XSpeed	$10
define obj_YSpeed	$12
define obj_GSpeed	$14
define obj_OnGround	$16
define obj_Angle	$18
define obj_RenderF	$1A		; render flags
define obj_Anim		$1C		; animation frame

; Call this to process objects.


#[bank(04)]
ObjectMgr:
	LDX.w #ObjectTable
.iterate_obj
	LDA $00,x
	BEQ .next_slot
	STA $00

	LDA $01,x		; use long pointer
	STA $01
	
	PHX
	TXA
	TCD
	; stack: 56 34 12 00
	PEA.w #(ObjectMgr>>16)
	PEA.w #.+-1
	JMP [$0000]
+
	PLB
	PLX
.next_slot
	LDA #$0000
	TCD
	TXA
	CLC : ADC.w #ObjectSize
	TAX
	CPX.w #ObjectTable+ObjectSize*ObjectTableLen
	BMI .iterate_obj
	RTL


InitObjMgr:
	LDX.w #ObjectTable
	CLC
-	TAX
	STZ.w $0000,x
	ADC.w #ObjectSize
	CMP.w #ObjectTable+ObjectSize*ObjectTableLen
	BNE -
	RTL


; This is a trampoline. Call it to pause object execution for a frame.
; Note: could be a macro of `LDA.w #+ : STA.b obj_ID : RTL : +`
ObjYield:
	PLA
	DEC
	STA.b obj_ID
	SEP #$20
	PLA
	REP #$20
	RTL

CameraFollow:
	PHD
	LDA 1,s
	TAX
	LDA.w #$0000
	TCD
	LDA.w obj_XPos,x
	SEC : SBC #$0080
	STA.b CamX
	LDA.w obj_YPos,x
	SEC : SBC #$0080
	STA.b CamY
	; Add camera borders
	LDA.b CamX
	CMP.b Level_CamXStart
	BPL +
	STZ.b CamX
+
	LDA.b CamY
	CMP.b Level_CamYStart
	BPL +
	STZ.b CamY
+
	LDA.b Level_CamXEnd
	CMP.b CamX
	BPL +
	STA.b CamX
+
	LDA.b Level_CamYEnd
	CMP.b CamY
	BPL +
	STA.b CamY
+
	PLD
	RTL

; Puts position after speed processing in X/Y.
ProcessSpeed:
	LDA.b obj_YSpeed
	CLC : ADC.b obj_YSubpx
	STA.w $00
	LDA.b obj_YSpeed
	BMI +
	SEP #$20
	LDA.b obj_YPos+1
	ADC #$00
	BRA ++
+
	SEP #$20
	LDA.b obj_YPos+1
	SBC #$00
++
	STA.w $02
	LDA.w $00
	STA.b obj_YSubpx
	REP #$20
	LDY.w $01

	LDA.b obj_XSpeed
	CLC : ADC.b obj_XSubpx
	STA.w $00
	LDA.b obj_XSpeed
	BMI +
	SEP #$20
	LDA.b obj_XPos+1
	ADC #$00
	BRA ++
+
	SEP #$20
	LDA.b obj_XPos+1
	SBC #$00
++
	STA.w $02
	LDA.w $00
	STA.b obj_XSubpx
	REP #$20
	LDX.w $01
	RTL

; Gets collision data for 4 points that surround the sprite.
; Output in scratch:
; $00 $02
; $04 $06
; TODO: optimize 4 calls to one
GetSimpleBoundingBox:
	LDX.b obj_XPos
	LDY.b obj_YPos
	JSL GetBlockAt
	STA.w $00
	LDA.b obj_Width
	AND.w #$00FF
	CLC : ADC.b obj_XPos
	TAX
	JSL GetBlockAt
	STA.w $02
	LDA.b obj_Height
	AND.w #$00FF
	CLC : ADC.b obj_YPos
	TAY
	JSL GetBlockAt
	STA.w $06
	LDX.b obj_XPos
	JSL GetBlockAt
	STA.w $04
	RTL


; Applies speed. Uses simple box collision.
; Uses callbacks to process custom blocks.
; TODO: maybe set DP and use indexed?
; PHD : LDX 1,s : LDA #$0000 : TCD : .. : PLD
; Return value: a bitfield of udlr
SimpleLayerCollision:
	; Sideways
	JSL ProcessSpeed
	STX.w $10
	STY.w $12
	LDA.w #$0000
	STA.w $1E	; Processing X
	LDA.b obj_Size
	AND.w #$FF00
	XBA
	STA.w $16	; width
	LDA.b obj_Size
	AND.w #$00FF
	STA.w $18	; height
	STZ.w $1A
	LDA.b obj_XSpeed
	BEQ .move_vertical
	BMI .move_left
	; Moving right
	LDA.w $10
	CLC : ADC.w $16
	TAX
	LDY.b obj_YPos
	JSR .collideWith
	STA.w $14
	TYA
	CLC : ADC.w $18
	TAY
	JSR .collideWith
	ORA.w $14
	BEQ .sync_xspeed
	; collision happened, clamp velocity
	TXA				; target block coords
	AND.w #$FFF0
	SEC : SBC.w $16
	DEC
	STA.b obj_XPos
	STZ.b obj_XSpeed
	LDA.w #%0001
	TSB.w $1A
	BRA .move_vertical
.move_left
	; Moving left
	LDX.w $10
	LDY.b obj_YPos
	JSR .collideWith
	STA.w $14
	TYA
	CLC : ADC.w $18
	TAY
	JSR .collideWith
	ORA.w $14
	BEQ .sync_xspeed
	; collision happened, clamp velocity
	TXA				; target block coords
	AND.w #$FFF0
	CLC : ADC #$0010
	STA.b obj_XPos
	STZ.b obj_XSpeed
	LDA.w #%0010
	TSB.w $1A
	BRA .move_vertical
.sync_xspeed
	LDA.w $10
	STA.b obj_XPos


.move_vertical
	LDA.w #$0001
	STA.w $1E	; Processing Y
	LDA.b obj_YSpeed
	BEQ .end
	BMI .move_up
	; Moving down
	LDA.w $12
	CLC : ADC.w $18
	TAY
	LDX.b obj_XPos
	JSR .collideWith
	STA.w $14
	TXA
	CLC : ADC.w $16
	TAX
	JSR .collideWith
	ORA.w $14
	BEQ .sync_yspeed
	; collision happened, clamp velocity
	TYA				; target block coords
	AND.w #$FFF0
	SEC : SBC.w $18
	DEC
	STA.b obj_YPos
	STZ.b obj_YSpeed
	LDA.w #%0100
	TSB.w $1A
	BRA .end
.move_up
	; Moving up
	LDX.b obj_XPos
	LDY.w $12
	JSR .collideWith
	STA.w $14
	TXA
	CLC : ADC.w $16
	TAX
	JSR .collideWith
	ORA.w $14
	BEQ .sync_yspeed
	; collision happened, clamp velocity
	TYA				; target block coords
	AND.w #$FFF0
	CLC : ADC.w #$0010
	STA.b obj_YPos
	STZ.b obj_YSpeed
	LDA.w #%1000
	TSB.w $1A
	BRA .end
.sync_yspeed
	; TODO
	LDA.w $12
	STA.b obj_YPos
.end
	LDA.w $1A
	RTL

.collideWith
	PHX
	JSL GetSolidityAt
	CMP #$0003
	BMI +
	LDA #$0000
+
	ASL
	TAX
	JMP (.colliders,x)
.colliders
	dw .collide00
	dw .collide01
	dw .collide02
.collide00		; Always air
	PLX
	LDA #$0000
	RTS
.collide01		; Always solid
	PLX
	LDA #$0001
	RTS
.collide02		; Ledge
	PLX
	LDA.w $1E			; Is the Y movement tested?
	BEQ +
	LDA.b obj_YSpeed	; Is the downward momentum tested?
	BMI +
	STA.w $50
	TYA
	AND.w #$FFF0
	STA.w $00
	LDA.b obj_YPos
	CLC : ADC.w $18		; height
	AND.w #$FFF0
	SEC : SBC.w $00
	STA.w $50
	BPL +
	LDA #$0001
	BRA ++
+
	LDA #$0000
++
	RTS


; Mappings format is an array of this, 5 bytes each:
; 00: signed x offset (byte)
; 01: signed y offset (byte)
; 02-03: tile to use
; 04: mode
;	$00: 8x8 tile
;	$01: 16x16 tile
;	If MSB set, then this is the last tile

; This writes directly to the OAM buffer instead of calling AddSpriteTile.
; Also, for simpler sprites you may as well just call the above function manually.

; Also, this is broken and doesn't write to hioam yet.

DrawMappings:
	PHY
	PHX
	PHB

	PEI obj_Mappings+1	; get the DB register
	PLB #2

	LDA.b obj_XPos
	SEC : SBC.w CamX
	PHA				; stack +2
	LDA.b obj_YPos
	SEC : SBC.w CamY
	PHA				; stack +2
	
	LDX.b obj_Mappings	; mappings offset

	LDY.w SprInputPtr		; Test if the OAM table is full
	CPY.w #SprInputSub-4
	BPL .end
	
	BRA .entry
.get_next_mapping
	TXA
	CLC : ADC.w #$0005
	TAX
.entry
	; make sure that top of A is clear here
	; TODO: only 8-bit addition?
	LDA #$0000
	; get X position
	SEP #$20
	LDA.w $0000,x
	REP #$20
	; sign-extend
	BPL +
	ORA #$FF00
+
	CLC : ADC 1,s
	CMP #$FFF0
	BMI .get_next_mapping
	CMP #$0100
	BPL .get_next_mapping

	SEP #$20
	STA $0000,y
	REP #$20


	; make sure that top of A is clear here
	LDA #$0000
	SEP #$20
	LDA.b $0001,x
	REP #$20
	; sign-extend
	BPL +
	ORA #$FF00
+
	CLC : ADC 3,s
	CMP #$FFF0
	BMI .get_next_mapping
	CMP #$00E0
	BPL .get_next_mapping

	SEP #$20
	STA $0001,y
	REP #$20

	LDA.b $0002,x
	STA $0002,y
	CLC
	; mappings mode
	LDA.b $0004,x
	PHP
	BNE +
	SEC
+
	JSL AddSpriteTile

.end
	PLA
	PLA

	PLB
	PLX
	PLY
	RTL
