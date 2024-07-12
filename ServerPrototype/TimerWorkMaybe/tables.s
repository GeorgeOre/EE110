;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                              ;
;                              EE110a HW3 Tables                               ;
;                                 George Ore                                   ;
;                                                                              ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description: This file contains all tables needed to run the LCD program.
; Goal: The goal of these functions is to simplify LCD displaying structures.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           Required Constant Files
    .include "configPWR&CLK.inc"  ; contains power config constants
    .include "configGPIO.inc"     ; contains GPIO config constants
    .include "GPIO.inc"           ; contains GPIO control constants
    .include "GPT.inc"            ; contains GPT control constants
    .include "general.inc"        ; contains misc. constants
    .include "macros.inc"         ; contains all macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           Required Functions
;   None
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                               Table of Contents
;       Function Name           |   Purpose
    .def    TestStringTable     ;   Contains data for a test strings
    .def    EndTestStringTable
    .def    TStringAddressingTable  ;   Contains addressing data for test strings
    .def    EndTStringAddressingTable

    .def    MenuDataTable   ;   Contains data for the Main Menu
    .def    EndMenuDataTable
    .def    MenuAddressingTable     ;   Contains addressing data for the Main Menu
    .def    EndMenuAddressingTable

    .def    ButtonDataTable     ;   Contains data for Button Press Events
    .def    EndButtonDataTable
    .def    ButtonDataAddressingTable   ;   Contains addressing data for Button Press Events
    .def    EndButtonDataAddressingTable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Revision History:   02/04/24 George Ore   Created format
;                     05/30/24 George Ore   Ported to EE110a HW3
;                     07/09/24 George Ore   Ported to EE110b HW5
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;*******************************************************************************
;*                              FUNCTIONS                                      *
;*******************************************************************************
.text                           ; program memory space start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Testing Tables ;;;;;;


    .align 1
TestStringTable:
;   MAX CHARS:   1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16
    .byte       'W', 'E', 'L', 'C', 'O', 'M', 'E', ' ', 'T', 'O', STRING_END
    .byte       'G', 'O', 'R', 'E', '_', 'O', 'S', STRING_END

    .byte       'P', 'L', 'E', 'A', 'S', 'E', ' ', 'S', 'E', 'L', 'E', 'C', 'T', ' ', 'A', STRING_END
    .byte       'B', 'U', 'T', 'T', 'O', 'N', ' ', '(', 'K', 'E', 'Y', 'P', 'A', 'D', ')', STRING_END
EndTestStringTable:

    .align 1
TStringAddressingTable:    ;Row Col Offset  Row Col Offset
    .byte                   0,  0,  10,     1,  3,  7
    .byte                   0,  0,  15,     1,  0,  15
EndTStringAddressingTable:



    .align 1
MenuDataTable:
;   MAX CHARS:   1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16
    .byte       'S', 'N', 'A', 'K', 'E', STRING_END
    .byte       'M', 'U', 'S', 'I', 'C', 'A', 'L', ' ', 'S', 'N', 'A', 'K', 'E', STRING_END
    .byte       'S', 'N', 'A', 'K', 'E', '2', STRING_END
    .byte       'W', 'R', 'I', 'T', 'E', ' ', 'M', 'E', 'M', 'O', 'R', 'Y', STRING_END
EndMenuDataTable:

    .align 1
MenuAddressingTable:    ; Row Col Offset Row Col Offset Row Col Offset
    .byte                  0,  0,  5,     1,  0,  13,    0,  0,  6
    .byte                  1,  0,  6,     0,  0,  12
EndMenuAddressingTable:




    .align 1
;This data table contains all the stings that will be displayed when each
;button is pressed. Each string corresponds to a singular button.
ButtonDataTable:
;   MAX CHARS:   1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16
    .byte       'B', 'U', 'T', 'T', 'O', 'N', ' ', '0', '-', '0', STRING_END
    .byte       'B', 'U', 'T', 'T', 'O', 'N', ' ', '0', '-', '1', STRING_END
    .byte       'B', 'U', 'T', 'T', 'O', 'N', ' ', '0', '-', '2', STRING_END
    .byte       'B', 'U', 'T', 'T', 'O', 'N', ' ', '0', '-', '3', STRING_END
    .byte       'B', 'U', 'T', 'T', 'O', 'N', ' ', '1', '-', '0', STRING_END
    .byte       'B', 'U', 'T', 'T', 'O', 'N', ' ', '1', '-', '1', STRING_END
    .byte       'B', 'U', 'T', 'T', 'O', 'N', ' ', '1', '-', '2', STRING_END
    .byte       'B', 'U', 'T', 'T', 'O', 'N', ' ', '1', '-', '3', STRING_END
    .byte       'B', 'U', 'T', 'T', 'O', 'N', ' ', '2', '-', '0', STRING_END
    .byte       'B', 'U', 'T', 'T', 'O', 'N', ' ', '2', '-', '1', STRING_END
    .byte       'B', 'U', 'T', 'T', 'O', 'N', ' ', '2', '-', '2', STRING_END
    .byte       'B', 'U', 'T', 'T', 'O', 'N', ' ', '2', '-', '3', STRING_END
    .byte       'B', 'U', 'T', 'T', 'O', 'N', ' ', '3', '-', '0', STRING_END
    .byte       'B', 'U', 'T', 'T', 'O', 'N', ' ', '3', '-', '1', STRING_END
    .byte       'B', 'U', 'T', 'T', 'O', 'N', ' ', '3', '-', '2', STRING_END
    .byte       'B', 'U', 'T', 'T', 'O', 'N', ' ', '3', '-', '3', STRING_END
EndButtonDataTable:

;This addressing table represents the offset in bytes to index to
;   different parts of the button data table.
    .align 4
ButtonDataAddressingTable:
;   String:      1    2    3    4    5    6    7    8    9   10
    .word        0,   11,  22,  33,  44,  55,  66,  77,  88, 99
;   String:      11   12   13   14   15   16
    .word        110, 121, 132, 143, 154, 165

EndButtonDataAddressingTable:

.end
