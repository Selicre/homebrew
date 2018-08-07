; Object manager code - loads and processes all sprite-based objects on screen
; Object data is stored progressively. Object code can access it via direct page.

; Common offsets

define obj_ID		$00		; long
define obj_Mappings	$03		; long
define obj_XPos		$06
define obj_XSubpx	$08
define obj_YPos		$0A
define obj_YSubpx	$0C
define obj_Width	$0E		; byte
define obj_Height	$0F		; byte
define obj_XSpeed	$10
define obj_YSpeed	$12
define obj_Scratch	$14

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
