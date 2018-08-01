; Decompression routines

#[bank(00)]
Decompression_VBlank:
	STA.b DecQSavedA
	STX.b DecQSavedX
	STY.b DecQSavedY
	SEP #$20			; A 8-bit
	PLA
	STA.b DecQSavedP
	; TODO: right?
	PLA
	STA.b DecQSavedIP
	PLX
	STX.b DecQSavedIP+1
	LDX #0000
	TCD				; reset direct page
	JMP (DecQVBlank)
