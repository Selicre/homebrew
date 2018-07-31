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

; $03xx - $05xx: sprite table
define SprInputMain		$0300		; $200 bytes
define SprInputSub		$0500		; $20 bytes
define SprInputPtr		$0520		; Pointer to LoOAM
define SprInputSubPtr	$0522		; Pointer to HiOAM
define SprInputIndex	$0524		; Index
define SprInputLastPtr	$0526		; Last frame's LoOAM length

define VRAMBuffer		$7EC000		; A buffer for VRAM operations, length 0x4000
