;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                 Power & Clock Configuration Constants                        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description:       This file holds constants to be used in the main file
;
; Revision History:   11/08/23  George Ore      initial revision
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;Register Values & Definitions;;;;;;

;   Power Domain Control Register PDCTL0
;        Bits    Name                Code    Description
;        0       RFC Power           0       Off
;        1       Serial Power        0       Off
;        2       Peripheral Power    1       On
;        3-31    Reserved            0
PERIF_PWR_ON    .EQU    0x00000004  ;peripheral domain power on
SERIAL_PWR_ON   .EQU    0x00000002  ;serial domain power on
RFC_PWR_ON      .EQU    0x00000001  ;RF core domain power on

;   Power Domain Status Register PDSTAT0
;        Bits    Name                Code    Description
;        0       RFC Status          0       Off
;        1       Serial Status       0       Off
;        2       Peripheral Status   1       On
;        3-31    Reserved            0
PERIF_STAT_ON    .EQU    0x00000004  ;peripheral domain power status on
SERIAL_PWR_ON   .EQU    0x00000002  ;serial domain power status on
RFC_PWR_ON      .EQU    0x00000001  ;RF core domain power status on

;   GPIO Clock Gate Register GPIOCLKGR
;        Bits    Name                Code    Description
;        0       Clock Enable        1       GPIO Clock enabled
;        1-7     Reserved            0000000
;        8       All Modes Enable    0       Dont enable clocks on all modes
;        9-31    Reserved            0
GPIO_CLOCK_ON    .EQU    0x00000001  ;clock on

;   Bits of GPT Clock Gate GPTCLKGR
;        Bits    Name                Code    Description
;        0-3     Clock Enable        0x0     All clocks disabled
;                                    0x1     GPT0 Clock enabled only
;                                    0x2     GPT1 Clock enabled only
;                                    0x4     GPT2 Clock enabled only
;                                    0x8     GPT3 Clock enabled only
;        4-7     Reserved            0
;        8-11    All Modes Enable    0x0     All modes disabled
;                                    0x1     GPT0 enabled on all modes
;                                    0x2     GPT1 enabled on all modes
;                                    0x4     GPT2 enabled on all modes
;                                    0x8     GPT3 enabled on all modes
;        12-31   Reserved            0
GPT_CLKS_ON    .EQU    0x0000000F   ;enable all GPT clocks in run mode
GPT0_CLK_ON    .EQU    0x00000001   ;enable GPT0 clock in run mode
GPT1_CLK_ON    .EQU    0x00000001   ;enable GPT1 clock in run mode
GPT2_CLK_ON    .EQU    0x00000001   ;enable GPT2 clock in run mode
GPT3_CLK_ON    .EQU    0x00000001   ;enable GPT3 clock in run mode
GPT_CLK_AM     .EQU    0x00000F00   ;force all GPT clocks on in all modes
GPT0_CLK_AM    .EQU    0x00000100   ;force GPT0 clock on in all modes
GPT1_CLK_AM    .EQU    0x00000200   ;force GPT1 clock on in all modes
GPT2_CLK_AM    .EQU    0x00000400   ;force GPT2 clock on in all modes
GPT3_CLK_AM    .EQU    0x00000800   ;force GPT3 clock on in all modes

;    Load Settings to all PCRM Registers Register CLKLOADCTL
;    Bits    Name                Code    Description
;    0       Load                1       Begin loading (Write only)
;    1       Load Done           1       Loading success (Read only)
;    2-31    Reserved            0
LOAD_CLOCKS     .EQU    0x00000001  ;set clock to load
CLOCKS_LOADED   .EQU    0x00000002  ;clock has been loaded

; GPTCLKDIV - GPT clock divisor register

GPTCLKDIV_1     .EQU    0x00000000   ;divide GPT incoming clock by 1
GPTCLKDIV_2     .EQU    0x00000001   ;divide GPT incoming clock by 2
GPTCLKDIV_4     .EQU    0x00000002   ;divide GPT incoming clock by 4
GPTCLKDIV_8     .EQU    0x00000003   ;divide GPT incoming clock by 8
GPTCLKDIV_16    .EQU    0x00000004   ;divide GPT incoming clock by 16
GPTCLKDIV_32    .EQU    0x00000005   ;divide GPT incoming clock by 32
GPTCLKDIV_64    .EQU    0x00000006   ;divide GPT incoming clock by 64
GPTCLKDIV_128   .EQU    0x00000007   ;divide GPT incoming clock by 128
GPTCLKDIV_256   .EQU    0x00000008   ;divide GPT incoming clock by 256


;;;;;;Memory Register Adresses;;;;;;

;Base Addresses
PRCM    .EQU    0x40082000  ;Power, Clocks, Reset managment

;Address Offsets
PDCTL0      .EQU    0x12C   ;Power
PDSTAT0     .EQU    0x140   ;Power status
GPIOCLKGR   .EQU    0x48    ;GPIO clock power
GPTCLKGR   .EQU     0x54     ;GPT clock power
CLKLOADCTL  .EQU    0x28    ;System clock
