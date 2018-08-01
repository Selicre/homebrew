
; This fadein routine will jump to your usercode once it finishes.
; Jump here from GMInit code.
FadeinInit:
	LDA.b Gamemode
	STA.w Fade_Target
	LDA.w #$0000
	STA.w Fade_Timer
	LDA.w #GMID_Fadein-GamemodePtrs
	STA.w Gamemode
	RTS
GM_Fadein:
	LDA.w Fade_Timer
	INC.w Fade_Timer
	SEP #$20
	STA.w INIDISP
	REP #$20
	CMP.w #$000F
	BNE +
	LDA.w Fade_Target
	STA.b Gamemode
+
	LDX.w Fade_Target
	JMP (GamemodePtrs,x)

; Expects the target gamemode to be in A.

FadeoutInit:
	STA.w Fade_Target
	LDA.b Gamemode
	STA.w Fade_Source
	LDA.w #$000F
	STA.w Fade_Timer
	LDA.w #GMID_Fadeout-GamemodePtrs
	STA.w Gamemode
	RTS

GM_Fadeout:
	LDA.w Fade_Timer
	DEC.w Fade_Timer
	SEP #$20
	STA.w INIDISP
	REP #$20
	CMP.w #$0000
	BNE +
	LDA.w Fade_Target
	STA.b Gamemode
+
	LDX.w Fade_Source
	JMP (GamemodePtrs,x)
