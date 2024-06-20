;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           Other Constants                                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description:       This file holds constants to be used in the main file
;
; Revision History:   10/27/23  George Ore      initial revision
;                     10/31/23  George Ore      fixed constant value bugs
;                     11/01/23  George Ore      made control registers more
;                                               general, modded to fit HW2
;                     11/08/23  George Ore      repurposed file, removed all
;                                               configuration contants to other
;                                               files, added system control
;                                               space registers.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;General Constants;;;;;;

;Ubiquitous Values
ZERO_START      .EQU    0           ;Zero used for starting counts
COUNT_DONE      .EQU    0           ;Zero used for ending decrementing counts
FALSE           .EQU    0           ;False
EMPTY           .EQU    0           ;Empty
TRUE            .EQU    1           ;True aka non-zero
BYTES_PER_WORD  .EQU    4           ;4 bytes in each word
ONE             .EQU    1           ;The number one
NEXT_BYTE       .EQU    1           ;Used for addressing to the next byte
NEXT_WORD       .EQU    4           ;Used for addressing to the next word
BYTEMASK        .EQU    0x000000FF  ;Used to filter for first byte
LNIBBLE         .EQU    0x0000FFFF  ;Used to filter for lower nibble
ASCII_ZERO      .EQU    48          ;Represents a zero in ascii
ASCII_NEGATIVE  .EQU    45          ;Represents a '-' in ascii
BASE10          .EQU    10          ;Contains base 10

;;;;;;PWM Constants;;;;;;
READY           .EQU    0   ;Status of PWM is ready
SET             .EQU    1   ;Status of PWM is set
PWM_SHIFT_OFFSET    .EQU    2   ;Used to multiply the offset by 4 for address indexing
PWM_PRESCALE_SHIFT  .EQU    16  ;Used to prepare prescale value

;;;;;;Waiting Constants;;;;;;
WAIT1           .EQU    1   ;Constant for waiting 1 units of time
WAIT8           .EQU    8   ;Constant for waiting 8 units of time
WAIT30          .EQU    30  ;Constant for waiting 30 units of time
WAIT1000        .EQU    1000  ;Constant for waiting 1000 units of time
WAIT5000        .EQU    5000  ;Constant for waiting 5000 units of time
WAIT10000       .EQU   10000  ;Constant for waiting 10000 units of time
WAIT30000       .EQU   30000  ;Constant for waiting 30000 units of time

;;;;;;Servo Constants;;;;;;
;Error Correction Values
MAXINPUT                .EQU    90  ;Maxiumum input to SetServo function
MININPUT                .EQU   -90  ;Miniumum input to SetServo function (must be only one byte)
ANGLE_INPUT_OFFSET      .EQU    0x5A ;Used to turn signed angle input to unsigned
ErrorCorrectionTableOffset .EQU 0   ;Value to get from a lookup table address to the desired result
ADCSCALINGFACTOR        .EQU    0   ;ADC measurement correction gain
ADCOFFSET               .EQU    0   ;ADC measurement correction offset

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
STRING_END  .EQU    0xA0    ;Represents end of string condition
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
DISPLAY_LCD_COL .EQU    3   ;Default column to display on LCD


;;;;;;Cursor Variable Constants;;;;;;
;Variable Initial Values
CROW0   .EQU    0   ;initial cursor row index
CCOL0   .EQU    0   ;initial cursor column index

;Function Test Values
CINDEX  .EQU    0xFF          ;Display function cursor input test value

;;;;;;Interrupt Setup Constants;;;;;;

HANDLER_STACK_SIZE  .EQU    128     ;interrupt handler stack size

VEC_TABLE_SIZE      .EQU    54      ;number of interrupts in table

GPT0A_EX_NUM        .EQU    31      ;exception number for GPT0 Timer A
GPT0A_IRQ_NUM       .EQU    GPT0A_EX_NUM - 16 ;interrupt # for GPT0 Timer A
GPT1A_EX_NUM        .EQU    33      ;exception number for GPT1 Timer A
GPT1A_IRQ_NUM       .EQU    GPT1A_EX_NUM - 16 ;interrupt # for GPT1 Timer A

;;;;;;Stack Definition Constants;;;;;;

PROCESS_STACK_SIZE .equ    256          ;main loop stack size
TOTAL_STACK_SIZE   .equ    PROCESS_STACK_SIZE + HANDLER_STACK_SIZE

;;;;;;System Control Space;;;;;;

; CCR - configuration control register

STACK_ALIGN_4      .equ    0x00000000   ;keep stack on 4 byte alignment
STACK_ALIGN_8      .equ    0x00000100   ;keep stack on 8 byte alignment

;;;;;;System Control Space Register Addresses;;;;;;

; Base addresses
SCS         .EQU    0xE000E000   ;core system control space registers

; Register offsets

NVIC_ISER0  .EQU    0x0100       ;interrupt set enable (irq 0-31)
NVIC_ISER1  .EQU    0x0104       ;interrupt set enable (irq 32-63)
VTOR        .EQU    0x0D08       ;vector table offset register
CCR         .EQU    0x0D14       ;configuration control register
