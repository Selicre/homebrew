; LowRAM

; $00xx: Common
define Scratch			$0000		; Effectively the stack redzone; 16 bytes
define Gamemode			$0010		; Gamemode routine ID
define GameRunning		$0012		; Currently processing gamemode flag
define CamX				$0020		; BG0 X
define CamY				$0022		; BG0 Y
define BGX				$0024		; BG1 X
define BGY				$0026		; BG1 Y
define SysLoad			$0030		; last frame's scanline
define SysLoadLo		$0032		; last frame's H position

define VBlankPtr		$007C		; Note: you might want to set RunFrame_VBlank instead
define IRQPtr			$007E

; $0080-$00FF: gamemode-specific

; $01xx: System stack
define StackEnd			$0100		; for sanity checks

; $02xx: Used by decompression queue
define DecQRunning		$0200		; Decompressing right now?
define DecQSavedIP		$0201		; Saved decompression instruction pointer
define DecQSavedA		$0204		;
define DecQSavedX		$0206		;
define DecQSavedY		$0208		;
define DecQSavedP		$020A		;
define DecQVBlank		$020C		; Pointer to previous VBlank routine

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

define LevelData1		$7EB000		; Level buffers. These contain 32x32 chunks of level, which are reloaded dynamically
define LevelData2		$7EB400
define LevelData3		$7EB800
define LevelData4		$7EBC00
define VRAMBuffer		$7EC000		; A buffer for VRAM operations, length 0x4000
