;;;
;;; A sample PGX file to demonstrate how to build one.
;;;

; Kernel defines

PUTS = $00101C              ; Print a string to the currently selected channel

; Preamble

* = START - 8

                .text "PGX"
                .byte $01
                .dword START

; Main code

* = $020000

START           PHB
                PHP
                SEP #$20                ; A is 8-bit
                REP #$10                ; X, Y are 16-bit
                .as
                .xl

                LDX #<>GREETING         ; Point to GREETING
                LDA #`GREETING
                PHA
                PLB
                JSL PUTS                ; And print it

                PLP
                PLB
                RTL                     ; Go back to the caller

GREETING        .null "Hello, world!", 13
