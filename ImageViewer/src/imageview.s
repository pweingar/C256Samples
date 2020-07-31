;;;
;;; An image viewer for the C256... displays a bitmap image converted from BMP.
;;;

.cpu "65816"

.include "kernel.s"
.include "vicky_ii_def.s"
.include "macros.s"

VRAM = $B00000

* = $FFFC

HRESET          .word START     ; Bootstrapping vector

* = $002000

SOURCE          .dword ?        ; A pointer to copy from
DEST            .dword ?        ; A pointer to copy to
SIZE            .dword ?        ; The number of bytes to copy

* = $003000

START           CLC
                XCE

                setdp SOURCE

                setaxl

                ; Switch on bitmap graphics mode
                LDA #Mstr_Ctrl_Graph_Mode_En | Mstr_Ctrl_Bitmap_En
                STA @l MASTER_CTRL_REG_L

                setas
                LDA #0
                STA @l BORDER_CTRL_REG      ; Turn off the border
                STA @l MOUSE_PTR_CTRL_REG_L ; And turn off the mouse pointer

                ; Turn on bitmap #0, LUT#1
                LDA #%00000011
                STA @l BM0_CONTROL_REG

                ; Set the bitmap's starting address
                LDA #0
                STA @l BM0_START_ADDY_L
                STA @l BM0_START_ADDY_M
                STA @l BM0_START_ADDY_H

                LDA #0                      ; Set the bitmap scrolling offset to (0, 0)
                STA @l BM0_X_OFFSET
                STA @l BM0_X_OFFSET

                JSR INITLUT                 ; Initiliaze the LUT

                setal
                LDA #<>(640*480)            ; Set the size of the data to transfer to VRAM
                STA SIZE
                LDA #`(640*480)
                STA SIZE+2

                LDA #<>IMG_START            ; Set the source to the image data
                STA SOURCE
                LDA #`IMG_START
                STA SOURCE+2

                LDA #0                      ; Set the destination to the beginning of VRAM
                STA DEST
                STA DEST+2

                JSR COPYS2V                 ; Request the DMA to copy the image data

lock            NOP                         ; Otherwise pause
                BRA lock

;
; Start copying data from system RAM to VRAM
;
; Inputs (pushed to stack, listed top down)
;   SOURCE = address of source data (should be system RAM)
;   DEST = address of destination (should be in video RAM)
;   SIZE = number of bytes to transfer
;
; Outputs:
;   None
COPYS2V         .proc
                PHD
                PHP

                setdp SOURCE

                ; Set VDMA to go from system to video RAM, 1D copy
                setas
                LDA #VDMA_CTRL_SysRAM_Src | VDMA_CTRL_Enable
                STA @l VDMA_CONTROL_REG

                setal
                LDA SOURCE                  ; Set the source address
                STA @l VDMA_SRC_ADDY_L

                LDA DEST                    ; Set the destination address
                STA @l VDMA_DST_ADDY_L

                LDA SIZE                    ; Set the size
                STA @l VDMA_SIZE_L

                setas
                LDA SOURCE+2                ; Set the source address bank
                STA @l VDMA_SRC_ADDY_L+2

                LDA DEST+2                  ; Set the destination address bank
                STA @l VDMA_DST_ADDY_L+2

                LDA SIZE+2                  ; Set the size bank
                STA @l VDMA_SIZE_L+2

                LDA @l VDMA_CONTROL_REG     ; Start the VDMA
                ORA #VDMA_CTRL_Start_TRF
                STA @l VDMA_CONTROL_REG

                NOP                         ; VDMA involving system RAM will stop the processor
                NOP                         ; These NOPs give Vicky time to initiate the transfer and pause the processor
                NOP                         ; Note: even interrupt handling will be stopped during the DMA
                NOP

                PLP
                PLD
                RTS
                .pend

;
; Initialize the color look up tables
;
INITLUT         .proc
                PHB
                PHP

                setaxl
                LDA #LUT_END - LUT_START    ; Copy the palette to Vicky LUT0
                LDX #<>LUT_START
                LDY #<>GRPH_LUT1_PTR
                MVN `START,`GRPH_LUT1_PTR

                PLP
                PLB
                RTS
                .pend

.include "rsrc/colors.s"
.include "rsrc/pixmap.s"
