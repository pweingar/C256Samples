;;;
;;; Display a tileset
;;;
;;; Sets up the pixmap in video memory, points a tileset to it, then loads a tile map using that tileset.
;;; This demo is not active, but the tiles could be changed to animate the display.
;;;

.cpu "65816"

.include "vicky_def.s"
.include "macros.s"

;
; Constants
;

VRAM = $B00000                          ; First byte of video RAM
PIXMAP = VRAM                           ; Address of pixmap data in video RAM

* = $FFFC

HRESET          .word START             ; Bootstrapping vector

;
; Global variables
;

* = $002000
GLOBALS = *

;
; Code to run
;

* = $003000

START           CLC
                XCE

                setdbr `START
                setdp <>GLOBALS

                setas
                ; Switch on tile graphics mode
                LDA #Mstr_Ctrl_Graph_Mode_En | Mstr_Ctrl_TileMap_En
                STA @lMASTER_CTRL_REG_L

                LDA #0                      ; Turn off the border
                STA @lBORDER_CTRL_REG
                STA @lBORDER_X_SIZE
                STA @lBORDER_Y_SIZE

                setaxl

                LDA #LUT_END - LUT_START    ; Copy the palette to Vicky LUT#0
                LDX #<>LUT_START
                LDY #<>GRPH_LUT0_PTR
                MVN `START,`GRPH_LUT0_PTR

                LDA #$FFFF ;IMG_END - IMG_START    ; Copy the tile pixmap data to video RAM
                LDX #<>IMG_START
                LDY #<>PIXMAP
                MVN `IMG_START,`PIXMAP

;                 setas
;                 LDX #0
; pixloop         LDA IMG_START,X
;                 STA PIXMAP,X
;                 INX
;                 BNE pixloop

                setdbr `START
                setxl

                ; Enable the tileset, use 256x256 pixel source data layout
                setas
                LDA #TILESHEET_256x256_En | TILE_Enable
                STA @lTL0_CONTROL_REG

                setal
                LDA #<>(PIXMAP - VRAM)      ; Set the address of the pixmap for the tileset
                STA @lTL0_START_ADDY_L
                setas
                LDA #`(PIXMAP - VRAM)
                STA @lTL0_START_ADDY_H
               
                JSL SETTILES

lock            NOP                         ; And just sit here waiting
                BRA lock

;
; Set up the tiles given a text screen description
;
; The tile map is specified using text, with each character indicating the tile to use
; "Borrowed" from the Fraggy example by Drone. :-)
;
SETTILES        .proc
                setas
                setxl

                LDX #0
charloop        LDA SCREEN,X                ; Get the character code from the text
                BEQ done                    ; If it's NUL, we've read the whole thing

                LDY #0
findloop        CMP CODES,Y                 ; Is it the same as the Yth code?
                BEQ found                   ; Yes: we've found the character
                INY                         ; Otherwise, check the next code
                CPY #20
                BLT findloop                ; Unless we're out of codes!

                BRK                         ; We shouldn't get here... the character did not match a code

found           LDA TILE_NUMBERS,Y          ; Get the tile number based on the character's index
                STA @lTILE_MAP0,X           ; And save it to the tile map

                INX                         ; And move to the next character in the text
                BRA charloop

done            RTS
                .pend

CODES           .text ".0<_>{-}][/SOE\"
                .null "GBRYP"
TILE_NUMBERS    .byte $FF, $00, $A0, $A1, $A2, $A3, $A4, $A5, $A6, $A7, $A8, $A9, $AA, $AB, $AC
                .byte $B0, $B1, $B2, $B3, $B4

SCREEN          .text "................................................................"
                .text "<_/SOE00\__>...................................................."
                .text "]..........[...................................................."
                .text "]..........[...................................................."
                .text "]..........[...................................................."
                .text "]..........[...................................................."
                .text "]..GG......[...................................................."
                .text "]..GG......[...................................................."
                .text "]..........[...................................................."
                .text "]..........[...................................................."
                .text "]..........[...................................................."
                .text "]..........[...................................................."
                .text "]..........[...................................................."
                .text "]..........[...................................................."
                .text "]..........[...................................................."
                .text "]..........[...................................................."
                .text "]..........[...................................................."
                .text "]..........[...................................................."
                .text "]..........[...................................................."
                .text "]..........[...................................................."
                .text "]..........[...................................................."
                .text "]..........[...................................................."
                .text "]..........[...................................................."
                .text "]..........[...................................................."
                .text "].........R[...................................................."
                .text "].B.YB....R[...................................................."
                .text "].BYYB..P.R[...................................................."
                .text "]BBYBB.PPPR[...................................................."
                .text "{----------}...................................................."
                .text "................................................................"

                .byte 0

;
; Image data for the tileset
;

.include "rsrc/colors.s"
.include "rsrc/pixmap.s"