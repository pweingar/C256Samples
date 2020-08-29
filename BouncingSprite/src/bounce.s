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

.include "vicky_ii_def.s"
.include "interrupt_def.s"
.include "macros.s"

;
; Constants
;

F_HEX = 0                                   ; FILETYPE value for a HEX file to run through the debug port
F_PGX = 1                                   ; FILETYPE value for a PGX file to run from storage 
VRAM = $B00000                              ; First byte of video RAM
BORDER_WIDTH = 0                            ; Width of the border in pixels
SPRITE_OFFSET = 32
X_LEFT = SPRITE_OFFSET                      ; Minimum X value for sprites
X_RIGHT = 320                               ; Maximum X value for sprites
Y_TOP = 32                                  ; Minimum Y value for sprites
Y_BOTTOM = 240                              ; Maximum Y value for sprites
DEFAULT_TIMER = $02                         ; Number of SOF ticks to wait between sprite updates
HIRQ = $FFEE                                ; IRQ vector

.if FILETYPE = F_HEX
;
; For loading through the debug port, bootstrap the code through the RESET vector
;
* = $FFFC
HRESET          .word <>START               ; Bootstrapping vector
.endif

;
; Global variables
;

* = $002000
GLOBALS = *
JMPHANDLER      .byte ?                 ; JMP opcode for the NEXTHANDLER
NEXTHANDLER     .word ?                 ; Pointer to the next IRQ handler in the chain
DESTPTR         .dword ?                ; Pointer used for writing data
XCOORD          .word ?                 ; The X coordinate (column) for the sprite
YCOORD          .word ?                 ; The Y coordinate (row) for the sprite
DX              .word ?                 ; The change in X for an update (either 1/-1)
DY              .word ?                 ; The change in Y for an update (either 1/-1)
TIMER           .word ?                 ; The timer for controlling speed of motion (decremented on SOF interrupts)
IRQJMP          .fill 4                 ; Code for the IRQ handler vector

.if FILETYPE = F_PGX
;
; Header for the PGX file
;

* = START - 8
                .text "PGX"
                .byte $01
                .dword START
.endif

;
; Code to run
;

* = $003000
START           CLC
                XCE

                setdbr `START
                setdp <>GLOBALS

                JSR SETUPBANK0              ; Copy BANK0 data

                setas
                LDA #0
                STA @l BORDER_CTRL_REG      ; Disable the border
                STA @l MOUSE_PTR_CTRL_REG_L ; Disable the mouse pointer

                setaxl
                ; Switch on sprite graphics mode, 320x200
                LDA #Mstr_Ctrl_Graph_Mode_En | Mstr_Ctrl_Sprite_En | $0200
                STA @l MASTER_CTRL_REG_L

                PHB
                LDA #LUT_END - LUT_START    ; Copy the palette to Vicky LUT#1
                LDX #<>LUT_START
                LDY #<>GRPH_LUT0_PTR
                MVN `START,`GRPH_LUT0_PTR

                LDA #IMG_END - IMG_START    ; Copy the sprite pixmap data to video RAM
                LDX #<>IMG_START
                LDY #<>VRAM
                MVN `IMG_START,`VRAM
                PLB

                MOVEI_L SP00_ADDY_PTR_L, 0  ; Set SPRITE0 to use the pixmap

                setaxl
                LDA XCOORD
                STA @l SP00_X_POS_L
                LDA YCOORD
                STA @l SP00_Y_POS_L

                LDA #%00000001              ; Turn on SPRITE0, layer 0, LUT#0
                STA @lSP00_CONTROL_REG

                SEI

                setal
                LDA HIRQ                    ; Get the current handler
                STA NEXTHANDLER             ; And save it to call it

                LDA #<>IRQJMP               ; Replace it with our handler
                STA HIRQ

                setas
                LDA @l INT_MASK_REG0        ; Enable SOF interrupts
                AND #~FNX0_INT00_SOF
                STA @l INT_MASK_REG0

                CLI                         ; Make sure interrupts are enabled

lock            NOP                         ; And just sit here waiting
                BRA lock

;
; Copy the Bank 0 data down to bank 0
;
SETUPBANK0      .proc
                PHB
                PHP

                setaxl
                LDX #<>BEGIN_BANK0
                LDY #<>GLOBALS
                LDA #(END_BANK0 - BEGIN_BANK0)
                MVN #`BEGIN_BANK0, #`GLOBALS

                PLP
                PLB
                RTS
                .pend

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

                setdbr `START
                setdp GLOBALS

                setas
                LDA @l INT_PENDING_REG0     ; Check to see if we got a SOF interrupt
                AND #FNX0_INT00_SOF
                CMP #FNX0_INT00_SOF
                BNE yield                   ; No: call the next handler in the chain
                STA @l INT_PENDING_REG0     ; Yes: clear the pending interrupt status

update_pos      setal
                LDA XCOORD                  ; Set SPRITE0's position
                STA @l SP00_X_POS_L

                LDA YCOORD
                STA @l SP00_Y_POS_L

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
                JML JMPHANDLER              ; Then transfer control to the next handler

;
; Bank 0 data (to be copied on startup)
;

BEGIN_BANK0 = *
D_JMPHANDLER    JMP 0                   ; JMP and Pointer to the next IRQ handler in the chain
D_DESTPTR       .dword 0                ; Pointer used for writing data
D_XCOORD        .word 100               ; The X coordinate (column) for the sprite
D_YCOORD        .word 100               ; The Y coordinate (row) for the sprite
D_DX            .word 1                 ; The change in X for an update (either 1/-1)
D_DY            .word 1                 ; The change in Y for an update (either 1/-1)
D_TIMER         .word DEFAULT_TIMER     ; The timer for controlling speed of motion (decremented on SOF interrupts)
                JML HANDLEIRQ           ; Code to start the interrupt handler
END_BANK0 = *

;
; Image data for the sprite
;

.include "rsrc/colors.s"
.include "rsrc/pixmap.s"