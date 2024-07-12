;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           LED Constants                                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description:       This file holds constants required for the LED interface
;
; Revision History:   07/06/24  George Ore      initial revision
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;LED Constants;;;;;;
REDLED_IO_BIT   .EQU    6   ;Red LED is bit 6
GREENLED_IO_BIT .EQU    7   ;Green LED is bit 7

;;;;;;Memory Register Values;;;;;;

;   GPIO Output enable Register DOE31_0
;       Bits    Name                Code    Description
;       0-31    Bit x IO Enable     1/0     1 is yes 0 is no
OUTPUT_ENABLE_LED .EQU    0x000000C0  ;Enable bits 6 and 7
