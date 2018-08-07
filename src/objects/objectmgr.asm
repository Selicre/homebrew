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



; Mappings format is an array of this:
; 00: mode
;	$00: 8x8 tile
;	$01: 16x16 tile
;	$FF: terminator
; 01: signed x offset (byte)
; 02: signed y offset (byte)
; 03-04: tile to use

DrawMappings:
	PHY				; stack +2
	PHX				; stack +2
	LDA.b obj_XPos
	PHA				; stack +2
	LDA.b obj_YPos
	PHA				; stack +2
	
	LDA 3,s
	SEC : SBC.w CamX
	TAX
	LDA 1,s
	SEC : SBC.w CamY
	TAY
	;      yxppccct
	LDA.w #(%00110001 << 8) + $8A
	SEC
	JSL AddSpriteTile

	PLA
	PLA
	PLX
	PLY
	RTL
