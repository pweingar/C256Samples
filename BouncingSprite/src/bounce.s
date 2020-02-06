;;;
;;; Make a sprite bounce around the screen
;;;
;;; This sample demonstrates sprites, working with an interrupt,
;;; and the use of the MVN instruction.
;;;
;;; Moving the sprite is not done in the main loop of the code but
;;; instead is handled in the start of frame (SOF) interrupt which
;;; is triggered once for each video frame. There isn't a huge amount
;;; of time in that interrupt, so it is important that the handler be
;;; brief, but not updating the sprite until the SOF interrupt has
;;; been triggered allows us to avoid screen tearing.
;;;
;;; NOTE: on my RevB board, there seems to be a bug in the sprites
;;; where a sprite will use LUT#1 when LUT#0 is specified in its
;;; control register.
;;;

.cpu "65816"

.include "vicky_def.s"
.include "interrupt_def.s"
.include "macros.s"

;
; Constants
;

VRAM = $B00000                          ; First byte of video RAM
BORDER_WIDTH = 32                       ; Width of the border in pixels
X_LEFT = BORDER_WIDTH                   ; Minimum X value for sprites
X_RIGHT = 640 - BORDER_WIDTH - 32       ; Maximum X value for sprites
Y_TOP = BORDER_WIDTH                    ; Minimum Y value for sprites
Y_BOTTOM = 480 - BORDER_WIDTH - 32      ; Maximum Y value for sprites
DEFAULT_TIMER = $02                     ; Number of SOF ticks to wait between sprite updates
HIRQ = $FFEE                            ; IRQ vector

* = $FFFC

HRESET          .word START             ; Bootstrapping vector

;
; Global variables
;

* = $002000
GLOBALS = *

NEXTHANDLER     .word 0                 ; Pointer to the next IRQ handler in the chain
DESTPTR         .dword 0                ; Pointer used for writing data
XCOORD          .word 32                ; The X coordinate (column) for the sprite
YCOORD          .word 32                ; The Y coordinate (row) for the sprite
DX              .word 1                 ; The change in X for an update (either 1/-1)
DY              .word 1                 ; The change in Y for an update (either 1/-1)
TIMER           .word DEFAULT_TIMER     ; The timer for controlling speed of motion (decremented on SOF interrupts)

;
; Code to run
;

* = $003000

START           CLC
                XCE

                setdbr `START
                setdp <>GLOBALS

                setas
                ; Switch on sprite graphics mode
                LDA #Mstr_Ctrl_Graph_Mode_En | Mstr_Ctrl_Sprite_En
                STA @lMASTER_CTRL_REG_L

                setaxl

                LDA #LUT_END - LUT_START    ; Copy the palette to Vicky LUT#1
                LDX #<>LUT_START
                LDY #<>GRPH_LUT1_PTR
                MVN `START,`GRPH_LUT1_PTR

                LDA #IMG_END - IMG_START    ; Copy the sprite pixmap data to video RAM
                LDX #<>IMG_START
                LDY #<>VRAM
                MVN `IMG_START,`VRAM

                setdbr `START
                setaxl

                LDA #<>VRAM                 ; Set SPRITE0 to use the pixmap
                STA @lSP00_ADDY_PTR_L
                setas
                LDA #0
                STA @lSP00_ADDY_PTR_H

                LDA #%00000001              ; Turn on SPRITE0, layer 0, LUT#0 (1)
                STA @lSP00_CONTROL_REG

                setal
                LDA @wHIRQ                  ; Get the current handler
                STA NEXTHANDLER             ; And save it to call it

                LDA #<>HANDLEIRQ            ; Replace it with our handler
                STA @wHIRQ

                setas
                LDA @lINT_MASK_REG0         ; Enable SOF interrupts
                AND #~FNX0_INT00_SOF
                STA @lINT_MASK_REG0

                CLI                         ; Make sure interrupts are enabled

lock            NOP                         ; And just sit here waiting
                BRA lock

;
; Handle IRQs
;
; If there is a pending SOF interrupt, decrement the sprite counter and move
; the sprite if the counter has reached 0.
;
; Regardless, transfer control back to the previous IRQ handler to let the OS
; do anything that otherwise needs doing.
; 
HANDLEIRQ       PHP
                PHD

                setas
                LDA @lINT_PENDING_REG0      ; Check to see if we got a SOF interrupt
                AND #FNX0_INT00_SOF
                CMP #FNX0_INT00_SOF
                BNE yield                   ; No: call the next handler in the chain
                STA @lINT_PENDING_REG0      ; Yes: clear the pending interrupt status

                setdp GLOBALS

update_pos      setal
                LDA XCOORD                  ; Set SPRITE0's position
                STA @lSP00_X_POS_L

                LDA YCOORD
                STA @lSP00_Y_POS_L

                DEC TIMER                   ; Decrement the timer
                BNE yield                   ; If not zero, skip the update

                LDA #<>DEFAULT_TIMER        ; Reset the timer
                STA TIMER

                CLC                         ; XCOORD += DX
                LDA XCOORD
                ADC DX
                STA XCOORD

                CMP #X_LEFT                 ; if XCOORD == X_LEFT or XCOORD == X_RIGHT
                BEQ invert_dx
                CMP #X_RIGHT
                BNE calc_Y

invert_dx       LDA DX                      ; THEN DX = -DX
                EOR #$FFFF
                INC A
                STA DX

calc_Y          CLC                         ; YCOORD += DY
                LDA YCOORD
                ADC DY
                STA YCOORD

                CMP #Y_TOP                  ; if YCOORD == T_TOP or YCOORD == Y_BOTTOM
                BEQ invert_dy
                CMP #Y_BOTTOM
                BNE yield

invert_dy       LDA DY                      ; THEN DY = -DY
                EOR #$FFFF
                INC A
                STA DY

yield           PLD                         ; Restore DP and status
                PLP
                JMP (NEXTHANDLER)           ; Then transfer control to the next handler

;
; Image data for the sprite
;

.include "rsrc/colors.s"
.include "rsrc/pixmap.s"