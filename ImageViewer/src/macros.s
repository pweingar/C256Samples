
;
; Stack parameters and locals utilities
; 

setaxs      .macro
            SEP #$30
            .as
            .xs
            .endm

setas       .macro
            SEP #$20
            .as
            .endm

setxs       .macro
            SEP #$10
            .xs
            .endm

setaxl      .macro
            REP #$30
            .al
            .xl
            .endm

setal       .macro
            REP #$20
            .al
            .endm

setxl       .macro
            REP #$10
            .xl
            .endm

setdp       .macro
            PHP
            setal
            PHA
            LDA #\1
            TCD
            PLA
            PLP
            .dpage \1
            .endm

setdbr      .macro
            PHP
            setas
            PHA
            LDA #\1
            PHA
            PLB
            PLA
            PLP
            .databank \1
            .endm
