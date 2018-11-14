; Defines for registers, etc.

define INIDISP     $2100       ; w
define OBSEL       $2101       ; w
define OAMADD      $2102       ; w, 16-bit
define OAMADDL     OAMADD      ; w
define OAMADDH     $2103       ; w (sprite table select)
define OAMDATA     $2104       ; w, 2x (also see OAMDATAREAD)
define BGMODE      $2105       ; w
define MOSAIC      $2106       ; w
define BG1SC       $2107       ; w
define BG2SC       $2108       ; w
define BG3SC       $2109       ; w
define BG4SC       $210A       ; w
define BG12NBA     $210B       ; w
define BG34NBA     $210C       ; w
define BG1HOFS     $210D       ; w, 2x
define M7HOFS      BG1HOFS     ; w, 2x
define BG1VOFS     $210E       ; w, 2x
define M7VOFS      BG1VOFS     ; w, 2x
define BG2HOFS     $210F       ; w, 2x
define BG2VOFS     $2110       ; w, 2x
define BG3HOFS     $2111       ; w, 2x
define BG3VOFS     $2112       ; w, 2x
define BG4HOFS     $2113       ; w, 2x
define BG4VOFS     $2114       ; w, 2x
define VMAINC      $2115       ; w
define VMADD       $2116       ; w, 16-bit
define VMADDL      $2116       ; w
define VMADDH      $2117       ; w
define VMDATA      $2118       ; w, 16-bit (also see VMDATAREAD)
define VMDATAL     VMDATA      ; w
define VMDATAH     $2119       ; w
define M7SEL       $211A       ; w
define M7A         $211B       ; w, 2x
define M7B         $211C       ; w, 2x
define M7C         $211D       ; w, 2x
define M7D         $211E       ; w, 2x
define M7X         $211F       ; w, 2x
define M7Y         $2120       ; w, 2x
define CGADD       $2121       ; w
define CGDATA      $2122       ; w, 2x (also see CGDATAREAD)
define W12SEL      $2123       ; w
define W34SEL      $2124       ; w
define WOBJSEL     $2125       ; w
define WH0         $2126       ; w
define WIN1L       WH0         ; w
define WH1         $2127       ; w
define WIN1R       WH1         ; w
define WH2         $2128       ; w
define WIN2L       WH2         ; w
define WH3         $2129       ; w
define WIN2R       WH3         ; w
define WBGLOG      $212A       ; w
define WOBJLOG     $212B       ; w
define TM          $212C       ; w
define TS          $212D       ; w
define TMW         $212E       ; w
define TSW         $212F       ; w
define CGWSEL      $2130       ; w
define CGADSUB     $2131       ; w
define COLDATA     $2132       ; w
define SETINI      $2133       ; w
define MPY         $2134       ; r, 24-bit
define MPYL        MPY         ; r
define MPYM        $2135       ; r
define MPYH        $2136       ; r
define SLHV        $2137       ; r
define OAMDATAREAD $2138       ; r, 2x (also see OAMADD and OAMDATA)
define VMDATAREAD  $2139       ; r, 16-bit (also see VMADD and VMDATA)
define VMDATALREAD VMDATAREAD  ; r
define VMDATAHREAD $213A       ; r
define CGDATAREAD  $213B       ; r, 2x (also see CGADD and CGDATA)
define OPHCT       $213C       ; r
define OPVCT       $213D       ; r
define STAT77      $213E       ; r
define STAT78      $213F       ; r

; APU registers

define APUI00      $2140 ; rw
define APUI01      $2141 ; rw
define APUI02      $2142 ; rw
define APUI03      $2143 ; rw

; WRAM registers

define WMDATA      $2180 ; rw
define WMADD       $2181 ; w, 24-bit
define WMADDL      $2181 ; w
define WMADDH      $2182 ; w
define WMADDB      $2183 ; w

; Serial joypad registers

define JOYSER0     $4016 ; rw
define JOYSER1     $4017 ; rw

; CPU registers

define NMITIMEN    $4200 ; w
define WRIO        $4201 ; w
define WRMPYA      $4202 ; w
define WRMPYB      $4203 ; w
define WRDIV       $4204 ; w, 16-bit
define WRDIVL      WRDIV ; w
define WRDIVH      $4205 ; w
define WRDIVB      $4206 ; w
define HTIME       $4207 ; w, 16-bit
define HTIMEL      HTIME ; w
define HTIMEH      $4208 ; w
define VTIME       $4209 ; w, 16-bit
define VTIMEL      $4209 ; w
define VTIMEH      $420A ; w
define MDMAEN      $420B ; w
define HDMAEN      $420C ; w
define MEMSEL      $420D ; w
define RDNMI       $4210 ; r
define TIMEUP      $4211 ; r
define HVBJOY      $4212 ; r
define RDIO        $4213 ; r
define RDDIV       $4214 ; r, 16-bit
define RDDIVL      RDDIV ; r
define RDDIVH      $4215 ; r
define RDMPY       $4216 ; r, 16-bit
define RDMPYL      RDMPY ; r
define RDMPYH      $4217 ; r
define JOY1        $4218 ; r, 16-bit
define JOY1L       JOY1  ; r
define JOY1H       $4219 ; r
define JOY2        $421A ; r, 16-bit
define JOY2L       JOY2  ; r
define JOY2H       $421B ; r
define JOY3        $421C ; r, 16-bit
define JOY3L       JOY3  ; r
define JOY3H       $421D ; r
define JOY4        $421E ; r, 16-bit
define JOY4L       JOY4  ; r
define JOY4H       $421F ; r

define JOY_B       $8000
define JOY_Y       $4000
define JOY_Select  $2000
define JOY_Start   $1000
define JOY_Up      $0800
define JOY_Down    $0400
define JOY_Left    $0200
define JOY_Right   $0100

define JOY_A       $0080
define JOY_X       $0040
define JOY_L       $0020
define JOY_R       $0010
