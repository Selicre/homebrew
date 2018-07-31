; TODO:
; load necessary graphics, fade in
GMInit_Logo:
	RTS
GM_Logo:
	SEP #$30
	LDA.b #$80|(GMID_Movecam-GamemodePtrs)
	STA.b Gamemode
	REP #$30
	RTS
