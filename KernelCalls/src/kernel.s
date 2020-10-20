;;;
;;; Kernel Jump Table for C256 Foenix
;;;

FK_PUTS             = $00101C ; Print a string to the currently selected channel
FK_PUTC             = $001018 ; Print a character to the currently selected channel
FK_LOCATE           = $001084 ; Reposition the cursor to row Y column X
FK_CLRSCREEN        = $0010A8 ; Clear the screen
FK_SETSIZES         = $00112C ; Set the text screen size variables based on the border and screen resolution.
FK_PRINTS           = $001068 ; Print string to screen. Handles terminal commands
FK_LOAD             = $001118 ; load a binary file into memory, supports multiple file formats
FK_ALLOCFD          = $001134 ; Allocate a file descriptor
FK_FREEFD           = $001138 ; Free a file descriptor
