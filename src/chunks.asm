
LoadInitialChunk:
	PHB
	LDX.w #Chunk_0000_0000
	JSR LoadChunkTL
	LDX.w #Chunk_0020_0000
	JSR LoadChunkTR
	PLB
	JMP LoadChunkDownward


LoadChunkDownward:
	PHB
	LDA.w ChunkLoaderY
	BNE +
	INC.w ChunkLoaderY
	LDA.l LevelMeta+MetaDownPtr
	CMP #$FFFF	; Should we load it?
	BEQ ++
	TAX
	JSR LoadChunkBL
++	LDA.l LevelMeta+LevelMetaSize+MetaDownPtr
	CMP #$FFFF
	BEQ ++
	TAX
	JSR LoadChunkBR
++	PLB
	RTL
+
	STZ.w ChunkLoaderY
	LDA.l LevelMeta+LevelMetaSize*2+MetaDownPtr
	CMP #$FFFF
	BEQ ++
	TAX
	JSR LoadChunkTL
++	LDA.l LevelMeta+LevelMetaSize*3+MetaDownPtr
	CMP #$FFFF
	BEQ ++
	TAX
	JSR LoadChunkTR
++	PLB
	RTL

LoadChunkUpward:
	PHB
	LDA.w ChunkLoaderY
	BNE +
	INC.w ChunkLoaderY
	LDA.l LevelMeta+MetaUpPtr
	CMP #$FFFF	; Should we load it?
	BEQ ++
	TAX
	JSR LoadChunkBL
++	LDA.l LevelMeta+LevelMetaSize+MetaUpPtr
	CMP #$FFFF
	BEQ ++
	TAX
	JSR LoadChunkBR
++	PLB
	RTL
+
	STZ.w ChunkLoaderY
	LDA.l LevelMeta+LevelMetaSize*2+MetaUpPtr
	CMP #$FFFF
	BEQ ++
	TAX
	JSR LoadChunkTL
++	LDA.l LevelMeta+LevelMetaSize*3+MetaUpPtr
	CMP #$FFFF
	BEQ ++
	TAX
	JSR LoadChunkTR
++	PLB
	RTL

LoadChunkRightward:
	PHB
	LDA.w ChunkLoaderX
	BEQ +
	INC.w ChunkLoaderX
	LDA.l LevelMeta+MetaRightPtr
	CMP #$FFFF	; Should we load it?
	BEQ ++
	TAX
	JSR LoadChunkBR
++	LDA.l LevelMeta+LevelMetaSize*2+MetaRightPtr
	CMP #$FFFF
	BEQ ++
	TAX
	JSR LoadChunkTR
++	PLB
	RTL
+
	STZ.w ChunkLoaderX
	LDA.l LevelMeta+LevelMetaSize*1+MetaRightPtr
	CMP #$FFFF
	BEQ ++
	TAX
	JSR LoadChunkBL
++	LDA.l LevelMeta+LevelMetaSize*3+MetaRightPtr
	CMP #$FFFF
	BEQ ++
	TAX
	JSR LoadChunkTL
++	PLB
	RTL


LoadChunkTL:
	PHX
	LDA.w #$0012
	LDY.w #LevelMeta
	MVN #$7E,#$05
	PLA
	CLC : ADC.w #18
	TAX
	LDA.w #$0400
	LDY.w #LevelChunks
	MVN #$7E,#$05
	RTS
LoadChunkTR:
	PHX
	LDA.w #$0012
	LDY.w #LevelMeta+LevelMetaSize
	MVN #$7E,#$05
	PLA
	CLC : ADC.w #18
	TAX
	LDA.w #$0400
	LDY.w #LevelChunks+LevelChunkSize
	MVN #$7E,#$05
	RTS
LoadChunkBL:
	PHX
	LDA.w #$0012
	LDY.w #LevelMeta+LevelMetaSize*2
	MVN #$7E,#$05
	PLA
	CLC : ADC.w #18
	TAX
	LDA.w #$0400
	LDY.w #LevelChunks+LevelChunkSize*2
	MVN #$7E,#$05
	RTS
LoadChunkBR:
	PHX
	LDA.w #$0012
	LDY.w #LevelMeta+LevelMetaSize*3
	MVN #$7E,#$05
	PLA
	CLC : ADC.w #18
	TAX
	LDA.w #$0400
	LDY.w #LevelChunks+LevelChunkSize*3
	MVN #$7E,#$05
	RTS
