;;;
;;; An image viewer for the C256
;;;

.cpu "65816"

.include "kernel.s"
.include "vicky_def.s"
.include "macros.s"

VRAM = $B00000

* = $FFFC

HRESET          .word START     ; Bootstrapping vector

* = $001000

SOURCE          .dword ?        ; A pointer to copy from
SOURCE_END      .dword ?        ; The end of the source block
DEST            .dword ?        ; A pointer to copy to

* = $002000

START           CLC
                XCE

                setdp SOURCE

                setxl
                setas

                ; Switch on bitmap graphics mode
                LDA #Mstr_Ctrl_Graph_Mode_En | Mstr_Ctrl_Bitmap_En
                STA @lMASTER_CTRL_REG_L

                ; Turn off the border
                LDA #0
                STA @lBORDER_CTRL_REG

                ; Turn on the bitmap
                LDA #1
                STA @lBM_CONTROL_REG

                ; Set the bitmap's starting address
                LDA #0
                STA @lBM_START_ADDY_L
                STA @lBM_START_ADDY_M
                STA @lBM_START_ADDY_H

                setal
                LDA #640
                STA @lBM_X_SIZE_L
                LDA #480
                STA @lBM_Y_SIZE_L

                ; Copy the LUT
                LDA #<>LUT_START        ; Set the source to the image palette
                STA SOURCE
                LDA #`LUT_START
                STA SOURCE+2

                LDA #<>GRPH_LUT0_PTR    ; Set the destination to LUT #0
                STA DEST
                LDA #`GRPH_LUT0_PTR
                STA DEST+2

                setas
                LDY #0
lut_loop        LDA [SOURCE],Y          ; Get the Xth byte of the palette
                STA [DEST],Y            ; And save it to the LUT
                INY
                CPY #4 * 256
                BNE lut_loop

                setal
                LDA #<>IMG_START        ; Set the source to the image data
                STA SOURCE
                LDA #`IMG_START
                STA SOURCE+2

                LDA #<>VRAM             ; Set the destination to the beginning of VRAM
                STA DEST
                LDA #`VRAM
                STA DEST+2

img_loop        setas
                LDA [SOURCE]
                STA [DEST]

                setal
                INC SOURCE              ; Increment the source pointer
                BNE inc_dest
                INC SOURCE+2

inc_dest        INC DEST                ; Increment the destination pointer
                BNE chk_end
                INC DEST+2

chk_end         LDA SOURCE              ; Is SOURCE == IMG_END?
                CMP #<>IMG_END
                BNE img_loop
                LDA SOURCE+2
                CMP #`IMG_END
                BNE img_loop            ; No: keep looping

lock            NOP                     ; Otherwise pause
                BRA lock

.include "rsrc/colors.s"
.include "rsrc/pixmap.s"
