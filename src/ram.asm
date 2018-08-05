; LowRAM

; $00xx: Common
define Scratch			$0000		; Effectively the stack redzone; 32 bytes
define CamX				$0020		; BG0 X
define CamY				$0022		; BG0 Y
define BGX				$0024		; BG1 X
define BGY				$0026		; BG1 Y
define SysLoad			$0030		; last frame's scanline
define SysLoadLo		$0032		; last frame's H position
define Gamemode			$0040		; Gamemode routine ID
define GameRunning		$0042		; Currently processing gamemode flag

define VBlankPtr		$007C		; Note: you might want to set RunFrame_VBlank instead
define IRQPtr			$007E

; $0080-$00FF: gamemode-specific

; $01xx: System stack
define StackEnd			$0100		; for sanity checks

; $02xx: Used by routines in the decompression context
; It uses its own stack and scratch (DP == $0200, SP = $02FF), and saves registers on VBlank.
; After all level processing is done, it resumes execution.
define DecQScratch		$0200
define DecQStack		$02F7		; Decompression queue default stack pointer
define DecQSavedIP		$02FB		; Saved decompression instruction pointer (long)
define DecQVBlank		$02FE		; Pointer to previous VBlank routine
define DecQRunning		$02FF		; Decompressing right now?

; $03xx - $05xx: sprite table
define SprInputMain		$0300		; $200 bytes
define SprInputSub		$0500		; $20 bytes
define SprInputPtr		$0520		; Pointer to LoOAM
define SprInputSubPtr	$0522		; Pointer to HiOAM
define SprInputIndex	$0524		; Index
define SprInputLastPtr	$0526		; Last frame's LoOAM length


; $0Fxx: misc stuff
define Fade_Target		$0F00
define Fade_Source		$0F02		; Fadeout only
define Fade_Timer		$0F04
define RunFrame_VBlank	$0F06		; The _actual_ VBlank routine pointer that must end in a JMP MainLoop

define HScrollSeam		$0F10		; Horizontal scrolling loading seam (CamX - 4 of the previous frame)
define VScrollSeam		$0F12		; Vertical scrolling loading seam (CamY - 1 of the previous frame)
define HScrollBufPtr	$0F14		; Pointer to horizontal scroll buffer data
define HScrollBufSize	$0F16		; Amount of columns
define HScrollBufTarget	$0F18		; The VRAM address to start from
define VScrollBufPtr	$0F1A		; Pointer to vertical scroll buffer data
define VScrollBufSize	$0F1C		; Size of data for each plane, in bytes
define VScrollBufTarget	$0F1E		; The VRAM address to start from

define VRAMBufferPtr	$0F20		; Pointer to free-for-use VRAM buffer data.
define VRAMBufferStart	$0F22		; Pointer to VRAM buffer which it's reset to every frame ($C000 by default).


; $8000+: data
define LevelMeta		$7EA800		; Chunk metadata.
define LevelMetaSize	$200
;define LevelMetaSize	(LevelChunks-LevelMeta)/4	; nifty

define MetaBlockPtr		$00			; Long pointer to $00-$7F block definitions
define MetaSubBlockPtr	$03			; Long pointer to $80-$FF block definitions
define MetaUpPtr		$06			; Long pointer to the compressed ROM chunk data above
define MetaDownPtr		$09			; .. below
define MetaLeftPtr		$0C			; .. to the left
define MetaRightPtr		$0F			; .. to the right
define MetaCustomBlocks	$20			; Custom block table (renderer + collider longptr pairs)

define LevelChunks		$7EB000		; Level buffers. These contain 32x32 chunks of level, which are reloaded dynamically
define LevelChunk0		LevelChunks
define LevelChunk1		LevelChunks + 1*LevelChunkSize
define LevelChunk2		LevelChunks + 2*LevelChunkSize
define LevelChunk3		LevelChunks + 3*LevelChunkSize

define LevelChunkSize	$400

define VRAMBuffer		$7EC000		; A buffer for VRAM operations, length 0x4000
