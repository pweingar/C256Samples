;;;
;;; Example to demonstrate using VDMA to fill video RAM
;;;

.cpu "65816"

.include "kernel.s"
.include "vicky_ii_def.s"
.include "macros.s"
.include "page_00_inc.s"

F_HEX = 0                                   ; FILETYPE value for a HEX file to run through the debug port
F_PGX = 1                                   ; FILETYPE value for a PGX file to run from storage
VRAM = $B00000                              ; Base address for video RAM

.if FILETYPE = F_HEX
;
; For loading through the debug port, bootstrap the code through the RESET vector
;
* = $FFFC
HRESET          .word <>START               ; Bootstrapping vector
.endif

* = $002000
GLOBALS = *
SOURCE          .dword ?                    ; A pointer to copy from
DEST            .dword ?                    ; A pointer to copy to
SIZE            .dword ?                    ; The number of bytes to copy

.if FILETYPE = F_PGX
;
; Header for the PGX file
;

* = START - 8
                .text "PGX"
                .byte $01
                .dword START
.endif

.if FILETYPE = F_HEX
* = $003000
.elsif FILETYPE = F_PGX
* = $010000
.endif
START           CLC
                XCE

                setdbr 0
                setdp GLOBALS
                setaxl

                ; Switch on bitmap graphics mode
                LDA #Mstr_Ctrl_Graph_Mode_En | Mstr_Ctrl_Bitmap_En ; Mstr_Ctrl_Text_Mode_En | Mstr_Ctrl_Text_Overlay
                STA @l MASTER_CTRL_REG_L

                setas
                LDA #0
                STA @l BORDER_CTRL_REG      ; Turn off the border
                STA @l MOUSE_PTR_CTRL_REG_L ; And turn off the mouse pointer

                JSL FK_SETSIZES             ; Recalculate the screen size information

                ; Turn on bitmap #0, LUT#1
                LDA #%00000011
                STA @l BM0_CONTROL_REG

                ; Set the bitmap's starting address
                MOVEI_L BM0_START_ADDY_L, 0

                LDA #0                      ; Set the bitmap scrolling offset to (0, 0)
                STA @l BM0_X_OFFSET
                STA @l BM0_Y_OFFSET

                JSR INITLUT                 ; Initiliaze the LUT

                JSR CLR_BITMAP              ; Zero out the bitmap

                PEA #32                     ; X
                PEA #32                     ; Y
                PEA #400                    ; Width
                PEA #200                    ; Height
                JSR NESTRECT                ; nestrect(x, y, width, height)

                setal
                TSC
                CLC
                ADC #5*2
                TCS

lock            NOP
                BRA lock

;
; Initialize the LUT to something we will use
;
INITLUT         .proc
                PHP
                PHD

locals          .virtual 1,D
L_COLOR1        .byte ?
L_COLOR0        .byte ?
                .endv

                setas
                LDA #255                ; color0 := 255
                PHA
                LDA #0                  ; color1 := 0
                PHA

                setaxl
                TSC
                TCD

                setas

                LDX #4
                LDY #255

loop            LDA L_COLOR0
                STA @l GRPH_LUT1_PTR,X
                INX

                LDA #64
                STA @l GRPH_LUT1_PTR,X
                INX

                LDA L_COLOR1
                STA @l GRPH_LUT1_PTR,X
                INX
                INX

                DEC L_COLOR0
                DEC L_COLOR0
                INC L_COLOR1
                INC L_COLOR1
                DEY
                BNE loop

                setal
                PLA
                PLD
                PLP
                RTS
                .pend

;
; 1D Fill fill the bitmap with the transparent color using VDMA
;
CLR_BITMAP      .proc
                PHP

                setas
                LDA #VDMA_CTRL_Enable | VDMA_CTRL_TRF_Fill
                STA @l VDMA_CONTROL_REG     ; Set to 1D fill

                LDA #0
                STA @l VDMA_BYTE_2_WRITE    ; Set the byte to fill with

                LDA #0                      ; Set the VDMA destination address
                STA @l VDMA_DST_ADDY_L
                STA @l VDMA_DST_ADDY_M
                STA @l VDMA_DST_ADDY_H

                LDA #<(640*480)             ; Set the number of bytes to write
                STA @l VDMA_SIZE_L
                LDA #>(640*480)
                STA @l VDMA_SIZE_M
                LDA #`(640*480)
                STA @l VDMA_SIZE_H

                LDA @l VDMA_CONTROL_REG     ; Trigger the transfer
                ORA #VDMA_CTRL_Start_TRF
                STA @l VDMA_CONTROL_REG

                NOP
                NOP
                NOP

wait            LDA @l VDMA_STATUS_REG      ; Wait for the transfer to complete
                AND #VDMA_STAT_VDMA_IPS
                CMP #VDMA_STAT_VDMA_IPS
                BEQ wait

                LDA #0
                STA @l VDMA_CONTROL_REG     ; Clear the control bits

                PLP
                RTS
                .pend

;
; Draw a nested rect at (x,y) with size (width, height)
;
NESTRECT        .proc
                PHP
                PHD

locals          .virtual 1,D
L_COLOR         .word ?
L_DP            .word ?
L_STATUS        .byte ?
L_RETURNPC      .word ?
P_HEIGHT        .word ?
P_WIDTH         .word ?
P_Y             .word ?
P_X             .word ?
                .endv

                setaxl
                PEA #1                      ; Set initial color

                TSC
                TCD

draw_rect       LDA P_X
                PHA
                LDA P_Y
                PHA
                LDA P_WIDTH
                PHA
                LDA P_HEIGHT
                PHA
                LDA L_COLOR
                PHA
                JSR FILLRECT                ; fillrect(x, y, width, height, color)

                TSC                         ; Remove the parameters from the stack
                CLC
                ADC #5*2
                TCS

                INC L_COLOR                 ; if (++color > 255) return
                LDA L_COLOR
                CMP #256
                BGE done

                DEC P_WIDTH                 ; if (--width == 0) return
                DEC P_WIDTH
                BEQ done
                BMI done

                DEC P_HEIGHT                ; if (--height == 0) return
                DEC P_HEIGHT
                BEQ done
                BMI done

                INC P_X                     ; x++
                INC P_Y                     ; y++

                BRA draw_rect               ; And draw this new rectangle

done            setal
                PLA                         ; Remove the local from the stack
                PLD
                PLP
                RTS
                .pend

;
; 2D fill an area of the screen using VDMA
;
FILLRECT        .proc
                PHP
                PHD

locals          .virtual 1,S
L_DP            .word ?
L_STATUS        .byte ?
L_RETURNPC      .word ?
P_COLOR         .word ?         ; The color to draw
P_HEIGHT        .word ?         ; The height of the rectangle to draw
P_WIDTH         .word ?         ; The width of the rectangle to draw
P_Y             .word ?         ; The Y coordinate of the upper left corner
P_X             .word ?         ; The X coordinate of the upper left corner
                .endv

                setas
                LDA #VDMA_CTRL_Enable | VDMA_CTRL_TRF_Fill | VDMA_CTRL_1D_2D
                STA @l VDMA_CONTROL_REG     ; Set to 2D fill

                LDA P_COLOR
                STA @l VDMA_BYTE_2_WRITE    ; Set the byte to fill with

                setal
                LDA P_Y
                STA @l M0_OPERAND_A
                LDA #640
                STA @l M0_OPERAND_B

                CLC
                LDA P_X
                ADC @l M0_RESULT
                STA @l VDMA_DST_ADDY_L
                setas
                LDA @l M0_RESULT+2
                ADC #0
                STA @l VDMA_DST_ADDY_H

                setal
                LDA P_WIDTH                 ; Set the width and height
                STA @l VDMA_X_SIZE_L
                LDA P_HEIGHT
                STA @L VDMA_Y_SIZE_L

                LDA #640                    ; Set the destination stride
                STA @l VDMA_DST_STRIDE_L

                setas
                LDA @l VDMA_CONTROL_REG     ; Trigger the transfer
                ORA #VDMA_CTRL_Start_TRF
                STA @l VDMA_CONTROL_REG

                NOP
                NOP
                NOP

wait            LDA @l VDMA_STATUS_REG      ; Wait for the transfer to complete
                AND #VDMA_STAT_VDMA_IPS
                CMP #VDMA_STAT_VDMA_IPS
                BEQ wait

                LDA #0
                STA @l VDMA_CONTROL_REG     ; Clear the control bits

                PLD
                PLP
                RTS
                .pend