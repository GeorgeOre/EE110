;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                 Constants                                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description:       This file holds constant to be used in the main file
;
; Revision History:   10/27/23  George Ore      initial revision
;                     10/31/23  George Ore      fixed constant value bugs
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    .global variable

;;;;;;Control Reg Constants;;;;;;
;    Bits of an IO control reg  IOCFGx
;    Bits    Name                Code    Description
;    0-5     Port ID             000000  General purpose
;    6       Edge MCUW Event     0       No
;    7       Edge RTC Event2     0       No
;    8-9     Drive Strength      00      Automatically set
;    10-11   Current Mode        00      Low current
;    12      Slew Rate           0       No slew
;    13-14   Pulldowns           11      No pulling
;                                01      Pull down
;                                10      Pull up
;    15      Reserved            0
;    16-17   Edge Detection      0       No
;    18      Edge Interrupt      0       No
;    19-20   Reserved            00
;    21      Prog0 Edge Event    0       No
;    22      Prog1 Edge Event    0       No
;    23      Prog2 Edge Event    0       No
;    24-26   IO Mode             0       Normal
;    27-28   Wake Up Config      0       Dont wake up
;    29      Input               0       No
;                                1       Yes
;    30      Hysteresis          0       No
;    31      Reserved            0

IO_OUT_CTRL .EQU    00000000000000000110000000000000b  ;output
IO_IN_CTRL  .EQU    00100000000000000100000000000000b  ;input

;    Bits of an IO clock control reg    GPIOCLKGR
;    Bits    Name                Code    Description
;    0       Clock Enable        1       Clock enabled
;    1-7     Reserved            0000000
;    8       All Modes Enable    0       Dont enable all clocks
;    9-31    Reserved            0

CLOCK_ON    .EQU    0x00000001  ;clock on

;    Bits of an peripheral power control reg    PDCTL0
;    Bits    Name                Code    Description
;    0       RFC Power           0       Off
;    1       Serial Power        0       Off
;    2       Peripheral Power    1       On
;    3-31    Reserved            0

GPIO_ON    .EQU    0x00000004  ;peripheral power on

;    Bits of clock loading control reg   CLKLOADCTL
;    Bits    Name                Code    Description
;    0       Load (W)            1       Set clock to load
;    1       Load Done (R)       1       On
;    2-31    Reserved            0

LOAD_CLOCK      .EQU    0x00000001  ;set clock to load
CLOCK_LOADED    .EQU    0x00000002  ;clock has been loaded

;    Bits of GPIO output enable reg     DOE31_0
;    Bits    Name                Code    Description
;    0-31    Bit x IO Enable     1/0     1 is yes 0 is no

OUTPUT_ENABLE   .EQU    0x000000C0  ;Enable bits 6 & 7

;;;;;;General Constants;;;;;;
;    LED Output Constants
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
BOTH_OFF        .EQU    0x00000000  ;Output when both LEDs should be off
RED_ON          .EQU    0x00000040  ;Output when only red LED should be on
GREEN_ON        .EQU    0x00000080  ;Output when only green LED should be on
BOTH_ON         .EQU    0x000000C0  ;Output when bot LEDs should be on

;    Button Input Constants

NOT_PRESSED     .EQU    0x00006000  ;Input when no buttons pressed
RED_PRESSED     .EQU    0x00004000  ;Input when only red button pressed
GREEN_PRESSED   .EQU    0x00002000  ;Input when only green button pressed
BOTH_PRESSED    .EQU    0x00000000  ;Input when both buttons pressed

;    Mask Constants

INPUT_MASK     .EQU    0x00006000  ;input IO bits mask
OUTPUT_MASK    .EQU    0x000000C0  ;output IO bits mask

;;;;;;Memory Register Adresses;;;;;;
;Base Addresses
IOC     .EQU    0x40081000  ;IO Controller
GPIO    .EQU    0x40022000  ;General Purpose IO
PRCM    .EQU    0x40082000  ;Power, Clocks, Reset managment

;Offset Addresses
PDCTL0      .EQU    0x12C   ;Power
PDSTAT0     .EQU    0x140   ;Power status
GPIOCLKGR   .EQU    0x48    ;GPIO clock
CLKLOADCTL  .EQU    0x28    ;System clock
IOCFG6      .EQU    0x18    ;IO pin 6 config
IOCFG7      .EQU    0x1C    ;IO pin 7 config
IOCFG13     .EQU    0x34    ;IO pin 13 config
IOCFG14     .EQU    0x38    ;IO pin 14 config
DIN31_0     .EQU    0xC0    ;IO input bus
DOUT31_0    .EQU    0x80    ;IO output bus
DOE31_0     .EQU    0xD0    ;IO bit out enable
