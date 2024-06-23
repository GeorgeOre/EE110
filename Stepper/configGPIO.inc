;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                       GPIO Configuration Constants                           ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description:       This file holds constants to be used in the main file
;
; Revision History:   11/08/23  George Ore      initial revision
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;Control Reg Constants;;;;;;
;    Bits of an IO Control Reg  IOCFGx
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

;    Bits of I/O Mode Configuration Reg  IOMODE
;    Bits    Name                Code    Description
;    0-1     IO0                 0xX     Sets AUXIO[8i+0]s mode
;                                0x0     Output Mode
;                                0x1     Analog Input Mode
;                                0x2     Open Drain Mode
;                                0x3     Open Source Mode
;    2-3     IO1                 0xX     Sets AUXIO[8i+1]s mode
;                                0x0     Output Mode
;                                0x1     Analog Input Mode
;                                0x2     Open Drain Mode
;                                0x3     Open Source Mode
;    4-5     IO2                 0xX     Sets AUXIO[8i+2]s mode
;                                0x0     Output Mode
;                                0x1     Analog Input Mode
;                                0x2     Open Drain Mode
;                                0x3     Open Source Mode
;    6-7     IO3                 0xX     Sets AUXIO[8i+3]s mode
;                                0x0     Output Mode
;                                0x1     Analog Input Mode
;                                0x2     Open Drain Mode
;                                0x3     Open Source Mode
;    8-9     IO4                 0xX     Sets AUXIO[8i+4]s mode
;                                0x0     Output Mode
;                                0x1     Analog Input Mode
;                                0x2     Open Drain Mode
;                                0x3     Open Source Mode
;    10-11   IO5                 0xX     Sets AUXIO[8i+5]s mode
;                                0x0     Output Mode
;                                0x1     Analog Input Mode
;                                0x2     Open Drain Mode
;                                0x3     Open Source Mode
;    12-13   IO6                 0xX     Sets AUXIO[8i+6]s mode
;                                0x0     Output Mode
;                                0x1     Analog Input Mode
;                                0x2     Open Drain Mode
;                                0x3     Open Source Mode
;    14-15   IO7                 0xX     Sets AUXIO[8i+7]s mode
;                                0x0     Output Mode
;                                0x1     Analog Input Mode
;                                0x2     Open Drain Mode
;                                0x3     Open Source Mode
;    16-31   Reserved            00
AUXIO8ip2IN .EQU    0x00000008  ;AUXIO[8i+2] input and the rest output
AUXIO8ip7IN .EQU    0x00001000  ;AUXIO[8i+2] input and the rest output

;    Bits of Digital Input Buffer Enable Reg  GPIODIE
;    Bits    Name                Code    Description
;    0-7     IO7_0               0xXX    Enables digital input buffer
;                                        to AUXIO[8i+x] with x being
;                                        the numbered bits of 0-7
;    8-31    Reserved            00
NODIB .EQU    0x00000000  ;Disable all digital input buffers

;    Bits of Peripheral Output Enable Reg  IOPOE
;    Bits    Name                Code    Description
;    0-7     IO7_0               0xXX    If x corresponds to the
;                                        the numbered bits of 0-7
;                                        1 connects AUXIO[8i+x] to IOxPSEL
;                                        0 connects AUXIO[8i+x] to GPIODOUT
;    8-31    Reserved            00
IO2PSEL_EN .EQU    0x00000002  ;Enable AUXIO[8i+2] to connect to IO2PSEL only

;    Bits of Digital Output Reg GPIODOUT
;    Bits    Name                Code    Description
;    0-7     IO7_0               0xXX    If x corresponds to the
;                                        the numbered bits of 0-7
;                                        1 sets AUXIO[8i+x] output
;                                        0 clears AUXIO[8i+x] output
;    8-31    Reserved            00

;    Bits of Digital Input Reg GPIODIN
;    Bits    Name                Code    Description
;    0-7     IO7_0               0xXX    If x corresponds to the
;                                        the numbered bits of 0-7
;                                        contains the input on
;                                        AUXIO[8i+x]
;    8-31    Reserved            00

;    Bits of Digital Output Set Reg GPIODOUTSET
;    Bits    Name                Code    Description
;    0-7     IO7_0               0xXX    If x corresponds to the
;                                        the numbered bits of 0-7
;                                        write 1 to set GPIODOUT bit x
;    8-31    Reserved            00

;    Bits of Digital Output Clear Reg GPIODOUTCLR
;    Bits    Name                Code    Description
;    0-7     IO7_0               0xXX    If x corresponds to the
;                                        the numbered bits of 0-7
;                                        write 1 to clear GPIODOUT bit x
;    8-31    Reserved            00

;    Bits of Digital Output Toggle Reg GPIODOUTTGL
;    Bits    Name                Code    Description
;    0-7     IO7_0               0xXX    If x corresponds to the
;                                        the numbered bits of 0-7
;                                        write 1 to toggle GPIODOUT bit x
;    8-31    Reserved            00

;    Bits of an IO Peripheral Select Reg IOxPSEL
;    Bits    Name                Code    Description
;    0-2     SRC                 0x0     Peripheral output = AUX_EVCTL:EVOBSCFG
;                                0x1     Peripheral output = AUX_SPIM SCLK
;                                0x2     Peripheral output = AUX_SPIM MOSI
;                                0x3     Peripheral output = AUX_EVCTL:EVSTAT3.AUX_TIMER2_EV0
;                                0x4     Peripheral output = AUX_EVCTL:EVSTAT3.AUX_TIMER2_EV1
;                                0x5     Peripheral output = AUX_EVCTL:EVSTAT3.AUX_TIMER2_EV2
;                                0x6     Peripheral output = AUX_EVCTL:EVSTAT3.AUX_TIMER2_EV3
;                                0x7     Peripheral output = AUX_EVCTL:EVSTAT3.AUX_TIMER2_PULSE
;    3-31    Reserved            00


;    Bits of I/O Mode Low Bit Configuration Reg IOMODEL
;    Bits    Name                Code    Description
;    0-1     IO0                 0xX     Sets AUXIO[8i+0]s mode
;                                0x0     Output Mode
;                                0x1     Analog Input Mode
;                                0x2     Open Drain Mode
;                                0x3     Open Source Mode
;    2-3     IO1                 0xX     Sets AUXIO[8i+1]s mode
;                                0x0     Output Mode
;                                0x1     Analog Input Mode
;                                0x2     Open Drain Mode
;                                0x3     Open Source Mode
;    4-5     IO2                 0xX     Sets AUXIO[8i+2]s mode
;                                0x0     Output Mode
;                                0x1     Analog Input Mode
;                                0x2     Open Drain Mode
;                                0x3     Open Source Mode
;    6-7     IO3                 0xX     Sets AUXIO[8i+3]s mode
;                                0x0     Output Mode
;                                0x1     Analog Input Mode
;                                0x2     Open Drain Mode
;                                0x3     Open Source Mode
;    16-31   Reserved            00

;    Bits of I/O Mode High Bit Configuration Reg IOMODEH
;    Bits    Name                Code    Description
;    0-1     IO4                 0xX     Sets AUXIO[8i+4]s mode
;                                0x0     Output Mode
;                                0x1     Analog Input Mode
;                                0x2     Open Drain Mode
;                                0x3     Open Source Mode
;    2-3     IO5                 0xX     Sets AUXIO[8i+5]s mode
;                                0x0     Output Mode
;                                0x1     Analog Input Mode
;                                0x2     Open Drain Mode
;                                0x3     Open Source Mode
;    4-5     IO6                 0xX     Sets AUXIO[8i+6]s mode
;                                0x0     Output Mode
;                                0x1     Analog Input Mode
;                                0x2     Open Drain Mode
;                                0x3     Open Source Mode
;    6-7     IO7                 0xX     Sets AUXIO[8i+7]s mode
;                                0x0     Output Mode
;                                0x1     Analog Input Mode
;                                0x2     Open Drain Mode
;                                0x3     Open Source Mode
;    16-31   Reserved            00



;;;;;;Memory Register Adresses;;;;;;

;Base Addresses
IOC         .EQU    0x40081000  ;IO Controller
AUX_AIODIO3 .EQU    0x400CF000  ;AUX Domain Analog Digital I/O 3

;IO Configuration Register Offsets
IOCFG0             .equ    0x0000       ;I/O configuration for DIO0
IOCFG1             .equ    0x0004       ;I/O configuration for DIO1
IOCFG2             .equ    0x0008       ;I/O configuration for DIO2
IOCFG3             .equ    0x000C       ;I/O configuration for DIO3
IOCFG4             .equ    0x0010       ;I/O configuration for DIO4
IOCFG5             .equ    0x0014       ;I/O configuration for DIO5
IOCFG6             .equ    0x0018       ;I/O configuration for DIO6
IOCFG7             .equ    0x001C       ;I/O configuration for DIO7
IOCFG8             .equ    0x0020       ;I/O configuration for DIO8
IOCFG9             .equ    0x0024       ;I/O configuration for DIO9
IOCFG10            .equ    0x0028       ;I/O configuration for DIO10
IOCFG11            .equ    0x002C       ;I/O configuration for DIO11
IOCFG12            .equ    0x0030       ;I/O configuration for DIO12
IOCFG13            .equ    0x0034       ;I/O configuration for DIO13
IOCFG14            .equ    0x0038       ;I/O configuration for DIO14
IOCFG15            .equ    0x003C       ;I/O configuration for DIO15
IOCFG16            .equ    0x0040       ;I/O configuration for DIO16
IOCFG17            .equ    0x0044       ;I/O configuration for DIO17
IOCFG18            .equ    0x0048       ;I/O configuration for DIO18
IOCFG19            .equ    0x004C       ;I/O configuration for DIO19
IOCFG20            .equ    0x0050       ;I/O configuration for DIO20
IOCFG21            .equ    0x0054       ;I/O configuration for DIO21
IOCFG22            .equ    0x0058       ;I/O configuration for DIO22
IOCFG23            .equ    0x005C       ;I/O configuration for DIO23
IOCFG24            .equ    0x0060       ;I/O configuration for DIO24
IOCFG25            .equ    0x0064       ;I/O configuration for DIO25
IOCFG26            .equ    0x0068       ;I/O configuration for DIO26
IOCFG27            .equ    0x006C       ;I/O configuration for DIO27
IOCFG28            .equ    0x0070       ;I/O configuration for DIO28
IOCFG29            .equ    0x0074       ;I/O configuration for DIO29
IOCFG30            .equ    0x0078       ;I/O configuration for DIO30
IOCFG31            .equ    0x007C       ;I/O configuration for DIO31

;AUX_AIODIO3 Offsets
IOMODE             .equ    0x0000       ;I/O mode configuration
GPIODIE            .equ    0x0004       ;Digital Input Buffer Enable
IOPOE              .equ    0x0008       ;Peripheral Output Enable
GPIODOUT           .equ    0x000C       ;Digital Output
GPIODIN            .equ    0x0010       ;Digital Input
GPIODOUTSET        .equ    0x0014       ;Digital Output Set
GPIODOUTCLR        .equ    0x0018       ;Digital Output Clear
GPIODOUTTGL        .equ    0x001C       ;Digital Output Toggle
IO0PSEL            .equ    0x0020       ;IO 0 Peripheral Select
IO1PSEL            .equ    0x0024       ;IO 1 Peripheral Select
IO2PSEL            .equ    0x0028       ;IO 2 Peripheral Select
IO3PSEL            .equ    0x002C       ;IO 3 Peripheral Select
IO4PSEL            .equ    0x0030       ;IO 4 Peripheral Select
IO5PSEL            .equ    0x0034       ;IO 5 Peripheral Select
IO6PSEL            .equ    0x0038       ;IO 6 Peripheral Select
IO7PSEL            .equ    0x003C       ;IO 7 Peripheral Select
IOMODEL            .equ    0x0040       ;IO Mode Config Low
IOMODEH            .equ    0x0044       ;IO Mode Config High
