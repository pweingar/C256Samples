;;;
;;; An image viewer for the C256... displays a bitmap image converted from BMP.
;;;

.cpu "65816"

.include "kernel.s"
.include "macros.s"
.include "page_00_inc.s"

;
; Structures needed
;

; File Descriptor -- Used as parameter for higher level DOS functions
FILEDESC            .struct
STATUS              .byte ?             ; The status flags of the file descriptor (open, closed, error, EOF, etc.)
DEV                 .byte ?             ; The ID of the device holding the file
PATH                .dword ?            ; Pointer to a NULL terminated path string
CLUSTER             .dword ?            ; The current cluster of the file.
FIRST_CLUSTER       .dword ?            ; The ID of the first cluster in the file
BUFFER              .dword ?            ; Pointer to a cluster-sized buffer
SIZE                .dword ?            ; The size of the file
CREATE_DATE         .word ?             ; The creation date of the file
CREATE_TIME         .word ?             ; The creation time of the file
MODIFIED_DATE       .word ?             ; The modification date of the file
MODIFIED_TIME       .word ?             ; The modification time of the file
RESERVED            .word ?             ; Two reserved bytes to bring the descriptor up to 32 bytes
                    .ends

;
; Constants
;

LOAD_ADDR = $010000                         ; Address to store our data

;
; For loading through the debug port, bootstrap the code through the RESET vector
;
* = $FFFC
HRESET          .word <>START               ; Bootstrapping vector

;
; Code
;

* = $3000
START           CLC
                XCE

                setdbr 0
                setdp SDOS_VARIABLES

                ; Set up the file descriptor... here we will use our own
                ; But you could also allocate a descriptor from the kernel

                setas
                setxl
                LDA #0
                LDX #0
clr_loop        STA MY_FD,X
                INX
                CPX #SIZE(FILEDESC)
                BNE clr_loop

                setaxl
                LDA #<>PATH                 ; Set the pointer to the path
                STA MY_FD.PATH
                LDA #`PATH
                STA MY_FD.PATH+2

                LDA #<>MY_BUFFER            ; Set the pointer to the sector buffer
                STA MY_FD.BUFFER
                LDA #`MY_BUFFER
                STA MY_FD.BUFFER+2

                LDA #<>MY_FD                ; Set the file descriptor pointer to our file descriptor
                STA DOS_FD_PTR
                LDA #`MY_FD
                STA DOS_FD_PTR+2

                LDA #<>LOAD_ADDR            ; Set the load address for the file
                STA DOS_DST_PTR             ; If loading a PGX, set address to $FFFFFFFF
                LDA #`LOAD_ADDR
                STA DOS_DST_PTR+2

                JSL FK_LOAD                 ; Attempt to load the file
                BCC not_loaded
                BRK

no_fd_found     LDX #<>MSG_NO_FD
                JSL FK_PUTS
                BRK

not_loaded      LDX #<>MSG_NO_LOAD
                JSL FK_PUTS
                BRK

;
; Data for the program
;

PATH            .null "@s:sample.txt"       ; Path to the file to load

; Error messages

MSG_NO_FD       .null "Kernel is out of file descriptors."
MSG_NO_LOAD     .null "F_LOAD failed... check DOS_STATUS and BIOS_STATUS."

MY_FD           .dstruct FILEDESC
                .align 512
MY_BUFFER       .fill 512