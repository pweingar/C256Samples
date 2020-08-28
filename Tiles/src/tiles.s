;;;
;;; Display a tileset
;;;
;;; Sets up the pixmap in video memory, points a tileset to it, then loads a tile map using that tileset.
;;; This demo is not active, but the tiles could be changed to animate the display.
;;;
;;; This demo shows the Vicky II tile registers as well as a simple example of a 1D VDMA copy operation
;;; from system memory to video memory.
;;;
;;; History: 
;;; 2020-07-28 -- Updated for VICKY II
;;;

.cpu "65816"

.include "vicky_ii_def.s"
.include "macros.s"

;
; Constants
;

VRAM = $B00000                          ; First byte of video RAM
PIXMAP = VRAM                           ; Address of pixmap data in video RAM
TILEMAP = $B20000                       ; And we'll put the tile map itself right after

* = $FFFC
HRESET          .word START             ; Bootstrapping vector

;
; Global variables
;

* = $002000
SOURCE          .dword ?                ; Starting address for the source data (4 bytes)
DEST            .dword ?                ; Starting address for the destination block (4 bytes)
SIZE            .dword ?                ; Number of bytes to copy (4 bytes)

;
; Code to run
;

* = $003000
START           CLC
                XCE

                setdbr `START

                setal
                ; Switch on tile graphics mode, 640x480 resolution
                LDA #Mstr_Ctrl_Graph_Mode_En | Mstr_Ctrl_TileMap_En
                STA @l MASTER_CTRL_REG_L

                LDA #0
                STA @l MOUSE_PTR_CTRL_REG_L ; And turn off the mouse pointer

                setas
                LDA #0                      ; Turn off the border
                STA @l BORDER_CTRL_REG
                STA @l BORDER_X_SIZE
                STA @l BORDER_Y_SIZE

                JSR INITLUT                 ; Initialize the LUT
                JSR INITPIXMAP              ; Load the pixmap data into video RAM
                JSR INITTILEMAP             ; Initialize the tile map

lock            NOP                         ; And just sit here waiting
                BRA lock

;
; Initialize the color look up tables
;
INITLUT         .proc
                PHB
                PHP

                setaxl
                LDA #LUT_END - LUT_START    ; Copy the palette to Vicky LUT0
                LDX #<>LUT_START
                LDY #<>GRPH_LUT0_PTR
                MVN `START,`GRPH_LUT0_PTR

                PLP
                PLB
                RTS
                .pend

;
; Load the pixel data for the tiles into video memory
; And set it up for tile set 0
;
INITPIXMAP      .proc
                PHB
                PHP

                setaxl
                LDA #$FFFF                  ; Set the size
                STA SIZE
                LDA #0
                STA SIZE+2

                LDA #<>IMG_START            ; Set the source address
                STA SOURCE
                LDA #`IMG_START
                STA SOURCE+2

                LDA #<>(PIXMAP - VRAM)      ; Set the destination address
                STA DEST
                STA @l TILESET0_ADDY_L      ; And set the Vicky register
                LDA #`(PIXMAP - VRAM)
                STA DEST+2
                setas
                STA @l TILESET0_ADDY_H

                setaxl
                PHB                         ; Copy the tile pixmap to VRAM
                LDX #<>IMG_START
                LDY #<>PIXMAP
                LDA #$FFFF
                MVP #`IMG_START, #`PIXMAP
                PLB

                ; Enable the tileset, use 256x256 pixel source data layout and LUT0
                setas
                LDA #%00001000
                STA @l TILESET0_ADDY_CFG

                PLP
                PLB
                RTS
                .pend

;
; Initialize the tile map using an ASCII representation of the map.
;
INITTILEMAP     .proc
                PHB
                PHP

                setdbr `SCREEN

                setxl
                setas
                LDX #0
                LDY #0
charloop        LDA SCREEN,Y                ; Get the character code from the text
                BEQ set_registers           ; If it's NUL, we've read the whole thing

                PHY
                LDY #0
findloop        CMP CODES,Y                 ; Is it the same as the Yth code?
                BEQ found                   ; Yes: we've found the character
                INY                         ; Otherwise, check the next code
                CPY #20
                BLT findloop                ; Unless we're out of codes!

                BRK                         ; We shouldn't get here... the character did not match a code

found           LDA TILE_NUMBERS,Y          ; Get the tile number based on the character's index
                STA @l TILEMAP,X            ; And save it to the tile map
                INX                         ; Note: writes to video RAM need to be 8-bit only
                LDA #0
                STA @l TILEMAP,X
                INX                         ; And move to the next character in the text
                PLY
                INY
                BRA charloop

set_registers   setal
                LDA #<>(TILEMAP - VRAM)     ; Set the pointer to the tile map
                STA @l TL0_START_ADDY_L
                setas
                LDA #`(TILEMAP - VRAM)
                STA @l TL0_START_ADDY_H

                setal
                LDA #50                     ; Set the size of the tile map to 40x30
                STA @l TL0_TOTAL_X_SIZE_L
                LDA #32
                STA @l TL0_TOTAL_Y_SIZE_L

                LDA #$8008                  ; Set the scroll to (-8, -16)
                STA @l TL0_WINDOW_X_POS_L
                LDA #$8010
                STA @l TL0_WINDOW_Y_POS_L

                setas
                LDA #$01                    ; Enable the tileset, LUT0
                STA @l TL0_CONTROL_REG
                PLP
                PLB
                RTS
                .pend

;
; Data
;

CODES           .text ".0<_>{-}][/SOE\"
                .null "GBRYP"
TILE_NUMBERS    .byte $FF, $00, $A0, $A1, $A2, $A3, $A4, $A5, $A6, $A7, $A8, $A9, $AA, $AB, $AC
                .byte $B0, $B1, $B2, $B3, $B4

SCREEN          .text ".................................................."
                .text "RGBRYPGBRYPGBRYPGBRYPGBRYPGBRYPGBRYPGBRYP........."
                .text "R<_/SOE00\__>...........................P........."
                .text "R]..........[...........................P........."
                .text "R]..........[...........................P........."
                .text "R]..........[...........................P........."
                .text "R]..........[...........................P........."
                .text "R]..GG......[...........................P........."
                .text "R]..GG......[...........................P........."
                .text "R]..........[...........................P........."
                .text "R]..........[...........................P........."
                .text "R]..........[...........................P........."
                .text "R]..........[...........................P........."
                .text "R]..........[...........................P........."
                .text "R]..........[...........................P........."
                .text "R]..........[...........................P........."
                .text "R]..........[...........................P........."
                .text "R]..........[...........................P........."
                .text "R]..........[...........................P........."
                .text "R]..........[...........................P........."
                .text "R]..........[...........................P........."
                .text "R]..........[...........................P........."
                .text "R]..........[...........................P........."
                .text "R]..........[...........................P........."
                .text "R]..........[...........................P........."
                .text "R].........R[...........................P........."
                .text "R].B.YB....R[...........................P........."
                .text "R].BYYB..P.R[...........................P........."
                .text "R]BBYBB.PPPR[...........................P........."
                .text "R{----------}...........................P........."
                .text "RBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBP........."
                .text ".................................................."

                .byte 0

;
; Image data for the tileset
;

.include "rsrc/colors.s"
.include "rsrc/pixmap.s"