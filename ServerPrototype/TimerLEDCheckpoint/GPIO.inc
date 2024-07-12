;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                          GPIO Control Constants                              ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description:       This file holds constants to be used in the main file
;
; Revision History:   11/08/23  George Ore      initial revision
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;GPIO Constants;;;;;;

;General
ALL_PINS        .EQU    0xFFFFFFFF  ;Represents all pins
NO_PINS         .EQU    0x00000000  ;Represents no pins

;;;;;;Memory Register Values;;;;;;

;   GPIO Output enable Register DOE31_0
;       Bits    Name                Code    Description
;       0-31    Bit x IO Enable     1/0     1 is yes 0 is no
OUTPUT_ENABLE_6n7   .EQU    0x000000C0  ;Enable bits 6 & 7
OUTPUT_ENABLE_0_3   .EQU    0x0000000F  ;Enable bits 0-3
OUTPUT_ENABLE_4_7   .EQU    0x000000F0  ;Enable bits 4-7
OUTPUT_ENABLE_8_17  .EQU    0x0003FF00  ;Enable bits 8-17
OUTPUT_ENABLE_18    .EQU    0x00040000  ;Enable bit 18
OUTPUT_ENABLE_20    .EQU    0x00100000  ;Enable bit 20
OUTPUT_ENABLE_24n26 .EQU    0x05000000  ;Enable bits 24 and 26
OUTPUT_ENABLE_21_22_24_26 .EQU    0x05600000  ;Enable bits 21 22 24 and 26
OUTPUT_ENABLE_24n26_28 .EQU    0x1D000000  ;Enable bits 24 26 27 and 28

OUTPUT_ENABLE_KEYPAD_LCD .EQU    0x0003FF0F  ;Enable outputs for keypad and LCD

;;;;;;Memory Register Addresses;;;;;;

;Base Address
GPIO    .EQU    0x40022000  ;General Purpose IO

;GPIO Data and Control Register Offsets
DOUT3_0     .equ    0x0000       ;data out bits 0 to 3
DOUT7_4     .equ    0x0004       ;data out bits 4 to 7
DOUT11_8    .equ    0x0008       ;data out bits 8 to 11
DOUT15_12   .equ    0x000C       ;data out bits 12 to 15
DOUT19_16   .equ    0x0010       ;data out bits 16 to 19
DOUT23_20   .equ    0x0014       ;data out bits 20 to 23
DOUT27_24   .equ    0x0018       ;data out bits 24 to 27
DOUT31_28   .equ    0x001C       ;data out bits 28 to 31
DOUT31_0    .equ    0x0080       ;data out bits 0 to 31
DSET31_0    .equ    0x0090       ;set data out bits 0 to 31
DCLR31_0    .equ    0x00A0       ;clear data out bits 0 to 31
DTGL31_0    .equ    0x00B0       ;toggle data out bits 0 to 31
DIN31_0     .equ    0x00C0       ;data in bits 0 to 31
DOE31_0     .equ    0x00D0       ;data output enable bits 0 to 31
EVFLG31_0   .equ    0x00E0       ;event flags for data bits 0 to 31

