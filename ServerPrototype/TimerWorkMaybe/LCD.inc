;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           LCD Constants                                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description:       This file holds constants required for the LCD
;
; Revision History:   06/29/24  George Ore      initial revision
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;LCD Constants;;;;;;
;LCD Write Command and RS Constants
;Command            RS  Data Bits
;Function Set       0   0b0011[Number of lines=1(means 2 lines)][Font=0]xx
;Display Off        0   0b00001000
;Clear Display      0   0b00000001
;Entry Mode Set     0   0b000001[Increment Mode][Display Shift]
;Display On         0   0b000011[Cursor En][Blink En]
;SetDDRamAddress    0   0b1[7-bit data address]
;WriteDDRam         1   [8-bit char data]
FSET_2LINES_DFONT   .EQU    0x00003800  ;FunctionSet two lines with default font
FSET_RS     .EQU    0x00000000          ;RS value for function set command

LCD_OFF     .EQU    0x00000800  ;Turn display off
LCD_OFF_RS  .EQU    0x00000000  ;RS value for display off command

CLR_LCD     .EQU    0x00000100  ;Clear display data
CLR_LCD_RS  .EQU    0x00000000  ;RS value for clear display command

FWD_INC     .EQU    0x00000600  ;Entry mode increment forward with no shift
ENTRY_RS    .EQU    0x00000000  ;RS value for entry mode command

CUR_BLINK   .EQU    0x00000F00  ;Turn on display with cursor and blink
LCD_ON_RS   .EQU    0x00000000  ;RS value for display on command

SETDDRAMBIT .EQU    0x00008000  ;DDRAM set command bit to add to address value
SETDDRAM_RS .EQU    0x00000000  ;RS value for SetDDRAMAddress command

WRITEDDRAM_RS .EQU  0x00100000  ;RS value for write DDRAM command

;LCD Test Constants
ERROR   .EQU    0xFEEDFEED  ;Invalid input error test value
MIN_INDEX   .EQU    -1      ;Minimum index
MAX_RINDEX  .EQU    1       ;Maximum row index
MAX_CINDEX  .EQU    15      ;Maximum column index
MIN_CHAR    .EQU    0x20    ;Minimum character value
MAX_CHAR    .EQU    0xFF    ;Maximum character value
LOW_CHARBAND .EQU   0x7F    ;Lower invalid character value bandlimit
HIGH_CHARBAND .EQU  0xA0    ;Upper invalid character value bandlimit
ENABLE_HOLD .EQU    26      ;48(1us)-22(450ns)=26 CPU clock cycles for enable hold time

;Misc LCD Constants
LCD_CMD_CLR     .EQU    0x0010FF00  ;Used to clear bits from a command
LCD_BUSYFLAG    .EQU    0x00008000  ;Maps to LCD busy flag aka LCD Data7 (pin 15)
LCD_ENABLE      .EQU    0x00040000  ;Maps to LCD enable pin in GPIO config (pin 18)
LCD_READ        .EQU    0x00080000  ;Maps to Read (!Write) pin in GPIO config (pin 19)
LCD_DATA_PINS   .EQU    0x0000FF00  ;Used to handle LCD Data pins
NOT_LCD_DATA_PINS .EQU  0x401C0000  ;Used to handle other LCD pins
GPIOSHIFT       .EQU    8   ;Used to shift LCD data to their GPIO pins
ROWADDRESSSHIFT .EQU    6   ;Used to calculate row address
NEXT_CHAR       .EQU    1   ;Used to address next char address
DB_SETUP_TIME   .EQU    14  ;Used as a counter to wait for setup time to pass
DB_HOLD_TIME    .EQU    14  ;Used as a counter to wait for hold time to pass
DISPLAY_LCD_ROW .EQU    0   ;Default row to display on LCD
DISPLAY_LCD_COL .EQU    12   ;Default column to display on LCD


;;;;;;Cursor Variable Constants;;;;;;
;Variable Initial Values
CROW0   .EQU    0   ;initial cursor row index
CCOL0   .EQU    0   ;initial cursor column index

;Function Test Values
CINDEX  .EQU    0xFF          ;Display function cursor input test value

;;;;;;Memory Register Values;;;;;;

;   GPIO Output enable Register DOE31_0
;       Bits    Name                Code    Description
;       0-31    Bit x IO Enable     1/0     1 is yes 0 is no
OUTPUT_ENABLE_LCD .EQU    0x001CFF00  ;Enable bits 24 26 27 and 28

OUTPUT_ENABLE_STEPPER_LCD .EQU  0x1D1CFF00  ;Enable stepper and LCD
