
LoadInitialChunk:
	PHB
	LDX.w #Chunk_0000_0000
	JSR LoadChunkTL
	LDX.w #Chunk_0020_0000
	JSR LoadChunkTR
	PLB
	INC.w ChunkLoaderY
	JSL LoadChunkDownward
	RTL


LoadChunkDownward:
	PHB
	LDA.w ChunkLoaderY
	BEQ +
	LDA.l LevelMeta+MetaDownPtr
	CMP #$FFFF	; Should we load it?
	BEQ ++
	TAX
	JSR LoadChunkBL
	LDA.l LevelMeta+LevelMetaSize+MetaDownPtr
	CMP #$FFFF
	BEQ ++
	TAX
	JSR LoadChunkBR
	STZ.w ChunkLoaderY
	CLC
	PLB
	RTL
+
	LDA.l LevelMeta+LevelMetaSize*2+MetaDownPtr
	CMP #$FFFF
	BEQ ++
	TAX
	JSR LoadChunkTL
	LDA.l LevelMeta+LevelMetaSize*3+MetaDownPtr
	CMP #$FFFF
	BEQ ++
	TAX
	JSR LoadChunkTR
	INC.w ChunkLoaderY
	CLC
	PLB
	RTL
++
	SEC
	PLB
	RTL

LoadChunkUpward:
	PHB
	LDA.w ChunkLoaderY
	BNE +
	LDA.l LevelMeta+MetaUpPtr
	CMP #$FFFF	; Should we load it?
	BEQ ++
	TAX
	JSR LoadChunkBL
	LDA.l LevelMeta+LevelMetaSize+MetaUpPtr
	CMP #$FFFF
	BEQ ++
	TAX
	JSR LoadChunkBR
	INC.w ChunkLoaderY
	CLC
	PLB
	RTL
+
	LDA.l LevelMeta+LevelMetaSize*2+MetaUpPtr
	CMP #$FFFF
	BEQ ++
	TAX
	JSR LoadChunkTL
	LDA.l LevelMeta+LevelMetaSize*3+MetaUpPtr
	CMP #$FFFF
	BEQ ++
	TAX
	JSR LoadChunkTR
	STZ.w ChunkLoaderY
	CLC
	PLB
	RTL
++
	SEC
	PLB
	RTL

LoadChunkRightward:
	PHB
	LDA.w ChunkLoaderX
	BEQ +
	LDA.l LevelMeta+MetaRightPtr
	CMP #$FFFF	; Should we load it?
	BEQ ++
	TAX
	JSR LoadChunkTR
	LDA.l LevelMeta+LevelMetaSize*2+MetaRightPtr
	CMP #$FFFF
	BEQ ++
	TAX
	JSR LoadChunkBR
	STZ.w ChunkLoaderX
	CLC
	PLB
	RTL
+
	LDA.l LevelMeta+LevelMetaSize*1+MetaRightPtr
	CMP #$FFFF
	BEQ ++
	TAX
	JSR LoadChunkTL
	LDA.l LevelMeta+LevelMetaSize*3+MetaRightPtr
	CMP #$FFFF
	BEQ ++
	TAX
	JSR LoadChunkBL
	INC.w ChunkLoaderX
	CLC
	PLB
	RTL
++
	SEC
	PLB
	RTL

LoadChunkLeftward:
	PHB
	LDA.w ChunkLoaderX
	BNE +
	LDA.l LevelMeta+MetaLeftPtr
	CMP #$FFFF	; Should we load it?
	BEQ ++
	TAX
	JSR LoadChunkTR
	LDA.l LevelMeta+LevelMetaSize*2+MetaLeftPtr
	CMP #$FFFF
	BEQ ++
	TAX
	JSR LoadChunkBR
	INC.w ChunkLoaderX
	CLC
	PLB
	RTL
+
	LDA.l LevelMeta+LevelMetaSize*1+MetaLeftPtr
	CMP #$FFFF
	BEQ ++
	TAX
	JSR LoadChunkTL
	LDA.l LevelMeta+LevelMetaSize*3+MetaLeftPtr
	CMP #$FFFF
	BEQ ++
	TAX
	JSR LoadChunkBL
	STZ.w ChunkLoaderX
	CLC
	PLB
	RTL
++
	SEC
	PLB
	RTL


LoadChunkTL:
	PHX
	LDA.w #$0012
	LDY.w #LevelMeta
	MVN #$7E,#$05
	PLA
	CLC : ADC.w #18
	TAX
	LDA.w #$03FF
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
	LDA.w #$03FF
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
	LDA.w #$03FF
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
	LDA.w #$03FF
	LDY.w #LevelChunks+LevelChunkSize*3
	MVN #$7E,#$05
	RTS
