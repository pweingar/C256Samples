;;;
;;; A sample PGX file to demonstrate how to build one.
;;;

; Kernel defines

PUTS = $00101C              ; Print a string to the currently selected channel

DOS_RUN_PARAM = $000360     ; 4 bytes - Pointer to the ASCIIZ string for arguments in loading a program


; Preamble

* = START - 8

                .text "PGX"
                .byte $01
                .dword START

; Main code

* = $020000

START           PHB
                PHP

                .virtual 1,S
OLD_P           .byte ?                 ; Old processor status we saved
OLD_B           .byte ?                 ; Old DBR we saved
RETURN_PC       .long ?                 ; Return address
PARAMS          .long ?                 ; Pointer on the stack to the path and parameters string
                .endv


                REP #$30                ; A, X, and Y are 16-bit
                .al
                .xl

                SEP #$20                ; A is 8-bit
                .as
                REP #$10                ;X, and Y are 16-bit
                .xl

                LDX #<>GREETING         ; Point to GREETING
                LDA #`GREETING
                PHA
                PLB
                JSL PUTS                ; And print it

                LDA PARAMS+2            ; Set DBR to the bank of the parameters pointer
                PHA
                PLB
                REP #$20                ; A is 16-bit
                .al
                LDA PARAMS              ; Set X to the 16-bits of the parameters pointer
                TAX
                JSL PUTS

                LDA #$1234              ; Set a return value of $1234

                PLP
                PLB
                RTL                     ; Go back to the caller

GREETING        .null "Hello, world!", 13, 13, "Parameters: "
