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


;;;;;;Memory Register Adresses;;;;;;

;Base Addresses
IOC     .EQU    0x40081000  ;IO Controller

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

