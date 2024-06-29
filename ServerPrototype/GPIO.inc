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

;    Mask Constants
INPUT_MASK     .EQU    0x000000F0  ;input IO bits mask
OUTPUT_MASK    .EQU    0x0000000F  ;output IO bits mask

;Button Input Constants
NOT_PRESSED     .EQU    0x000000F0  ;Input when no buttons pressed
C0_PRESSED      .EQU    0x000000E0  ;Input when column 0 pressed
C1_PRESSED      .EQU    0x000000D0  ;Input when column 1 pressed
C2_PRESSED      .EQU    0x000000B0  ;Input when column 2 pressed
C3_PRESSED      .EQU    0x00000070  ;Input when column 3 pressed

;Button Output Constants
NO_TEST         .EQU    0x0000000F  ;Output when not testing
R0_TEST         .EQU    0x0000000E  ;Output when testing row 0
R1_TEST         .EQU    0x0000000D  ;Output when testing row 1
R2_TEST         .EQU    0x0000000B  ;Output when testing row 2
R3_TEST         .EQU    0x00000007  ;Output when testing row 3

;Key Identifier Values
R0_C0           .EQU    0x000000EE  ;Row 0, Column 0
R0_C1           .EQU    0x000000DE  ;Row 0, Column 1
R0_C2           .EQU    0x000000BE  ;Row 0, Column 2
R0_C3           .EQU    0x0000007E  ;Row 0, Column 3

R1_C0           .EQU    0x000000ED  ;Row 1, Column 0
R1_C1           .EQU    0x000000DD  ;Row 1, Column 1
R1_C2           .EQU    0x000000BD  ;Row 1, Column 2
R1_C3           .EQU    0x0000007D  ;Row 1, Column 3

R2_C0           .EQU    0x000000EB  ;Row 2, Column 0
R2_C1           .EQU    0x000000DB  ;Row 2, Column 1
R2_C2           .EQU    0x000000BB  ;Row 2, Column 2
R2_C3           .EQU    0x0000007B  ;Row 2, Column 3

R3_C0           .EQU    0x000000E7  ;Row 3, Column 0
R3_C1           .EQU    0x000000D7  ;Row 3, Column 1
R3_C2           .EQU    0x000000B7  ;Row 3, Column 2
R3_C3           .EQU    0x00000077  ;Row 3, Column 3

;;;;;;Memory Register Values;;;;;;

;   GPIO Output enable Register DOE31_0
;       Bits    Name                Code    Description
;       0-31    Bit x IO Enable     1/0     1 is yes 0 is no
OUTPUT_ENABLE_6n7   .EQU    0x000000C0  ;Enable bits 6 & 7
OUTPUT_ENABLE_0_3   .EQU    0x0000000F  ;Enable bits 0-3
OUTPUT_ENABLE_4_7   .EQU    0x000000F0  ;Enable bits 4-7

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

