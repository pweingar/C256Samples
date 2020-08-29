;;;
;;; An image viewer for the C256... displays a bitmap image converted from BMP.
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
                LDA #Mstr_Ctrl_Graph_Mode_En | Mstr_Ctrl_Bitmap_En
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

                MOVEI_L SIZE, (640*480)     ; Set the size of the data to transfer to VRAM
                MOVEI_L SOURCE, IMG_START   ; Set the source to the image data
                MOVEI_L DEST, 0             ; Set the destination to the beginning of VRAM

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

                setdbr 0
                setdp GLOBALS
                setas

                ; Set SDMA to go from system to video RAM, 1D copy
                LDA #SDMA_CTRL0_SysRAM_Src | SDMA_CTRL0_Enable
                STA @l SDMA_CTRL_REG0

                ; Set VDMA to go from system to video RAM, 1D copy
                LDA #VDMA_CTRL_SysRAM_Src | VDMA_CTRL_Enable
                STA @l VDMA_CONTROL_REG

                MOVE_L SDMA_SRC_ADDY_L, SOURCE      ; Set the source address
                MOVE_L VDMA_DST_ADDY_L, DEST        ; Set the destination address
                MOVE_L SDMA_SIZE_L, SIZE            ; Set the size of the block
                MOVE_L VDMA_SIZE_L, SIZE          

                setas
                LDA @l VDMA_CONTROL_REG             ; Start the VDMA
                ORA #VDMA_CTRL_Start_TRF
                STA @l VDMA_CONTROL_REG

                LDA @l SDMA_CTRL_REG0               ; Start the SDMA
                ORA #SDMA_CTRL0_Start_TRF
                STA @l SDMA_CTRL_REG0

                NOP                                 ; VDMA involving system RAM will stop the processor
                NOP                                 ; These NOPs give Vicky time to initiate the transfer and pause the processor
                NOP                                 ; Note: even interrupt handling will be stopped during the DMA
                NOP

wait_vdma       LDA @l VDMA_STATUS_REG              ; Get the VDMA status
                BIT #VDMA_STAT_Size_Err | VDMA_STAT_Dst_Add_Err | VDMA_STAT_Src_Add_Err
                BNE vdma_err                        ; Go to monitor if there is a VDMA error
                BIT #VDMA_STAT_VDMA_IPS             ; Is it still in process?
                BNE wait_vdma                       ; Yes: keep waiting

                LDA #0                              ; Make sure DMA registers are cleared
                STA @l SDMA_CTRL_REG0
                STA @l VDMA_CONTROL_REG

                PLP
                PLD
                RTS

vdma_err        BRK
                .pend

;
; Initialize the color look up tables
;
INITLUT         .proc
                PHB
                PHP

                setdbr 0
                setdp GLOBALS

                setas
                LDA #0                      ; Make sure default color is 0,0,0
                STA @l GRPH_LUT0_PTR
                STA @l GRPH_LUT0_PTR+1
                STA @l GRPH_LUT0_PTR+2
                STA @l GRPH_LUT0_PTR+3

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
