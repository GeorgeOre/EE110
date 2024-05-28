;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                   MACRCOS                                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description:       This file holds macros to be used in the main file
;
; Revision History:   10/27/23  George Ore      initial revision

;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MOV32   .macro reg, value           ;Puts a 32 bit value into a Register
        MOVW reg, #(value & 0xFFFF)
        MOVT reg, #((value >> 16) & 0xFFFF)
        .endm
