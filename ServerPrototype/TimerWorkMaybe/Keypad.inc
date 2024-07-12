;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                          Keypad Control Constants                              ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description:       This file holds constants to interface with the keypad
;
; Revision History:   06/29/24  George Ore      initial revision
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;GPIO Constants;;;;;;

;    Mask Constants
INPUT_MASK      .EQU    0x000000F0  ;input IO bits mask
OUTPUT_MASK     .EQU    0x0000000F  ;output IO bits mask

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

;;;;;;Variable Constants;;;;;;
;Variable Initial Values
;DBNCE_CNTR_RESET   .EQU    0x0000BB80  ;dbnceCntr initial value maxed at 65535
;DBNCE_FLAG_RESET   .EQU    0           ;dbnceFlag initial value is reset
;NOT_PRESSED        .EQU    0x000000F0  ;prev initial value is not pressed

;Debounce Flag Values
DBNCE_FLAG_SET      .EQU    1       ;dbnceFlag value set
DBNCE_FLAG_RESET    .EQU    0       ;dbnceFlag value reset

;Debounce Counter Values
DBNCE_CNTR_RESET   .EQU    20  ;Debounce counter lasts 20ms

;Buffer Constants
BOFFSET             .EQU    8     ;offset between every buffer address value

;;;;;;4x4 Keypad Constants;;;;;;

;Grid indexing constants
ROW_4x4_OFFSET      .EQU    16  ;The addressing is in words a row is 4 words
COLUMN_4x4_OFFSET   .EQU    4   ;The addressing is in words a column is 1 word

;;;;;;Memory Register Values;;;;;;

;   GPIO Output enable Register DOE31_0
;       Bits    Name                Code    Description
;       0-31    Bit x IO Enable     1/0     1 is yes 0 is no
OUTPUT_ENABLE_KEYPAD_OUTPUTS   .EQU    0x0000000F  ;Enable bits 0-3
OUTPUT_ENABLE_KEYPAD_INPUTS   .EQU    0x000000F0  ;Enable bits 4-7
