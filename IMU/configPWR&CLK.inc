;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                 Power & Clock Configuration Constants                        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description:       This file holds constants to be used in the main file
;
; Revision History: 11/08/23    George Ore  Initial revision
;                   02/04/24    George Ore  Revised
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
PER_SER_PWR_ON  .EQU    0x00000006  ;peripheral and serial domain power on


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
GPT1_CLK_ON    .EQU    0x00000002   ;enable GPT1 clock in run mode
GPT01_CLK_ON   .EQU    0x00000003   ;enable GPT0 and GPT1 clocks in run mode
GPT2_CLK_ON    .EQU    0x00000004   ;enable GPT2 clock in run mode
GPT3_CLK_ON    .EQU    0x00000008   ;enable GPT3 clock in run mode
GPT_CLK_AM     .EQU    0x00000F00   ;force all GPT clocks on in all modes
GPT0_CLK_AM    .EQU    0x00000100   ;force GPT0 clock on in all modes
GPT1_CLK_AM    .EQU    0x00000200   ;force GPT1 clock on in all modes
GPT2_CLK_AM    .EQU    0x00000400   ;force GPT2 clock on in all modes
GPT3_CLK_AM    .EQU    0x00000800   ;force GPT3 clock on in all modes

;   Bits of SSI Clock Gate SSICLKGR
;        Bits    Name                Code    Description
;        0-1     Clock Enable        0x0     All clocks disabled
;                                    0x1     Enable SSI0 clock only
;                                    0x2     Enable SSI1 clock only
;                                    0x3     Enable SSI0 and SSI1
;        2-7     Reserved            0
;        8-9     All Modes Enable    0x0     All modes disabled
;                                    0x1     Enable AM SSI0 clock only
;                                    0x2     Enable AM SSI1 clock only
;                                    0x3     Enable AM SSI0 and SSI1
;        10-31   Reserved            0
SSI_CLKS_ON    .EQU    0x00000003   ;enable all SSI clocks in run mode
SSI0_CLK_ON    .EQU    0x00000001   ;enable SSI0 clock in run mode
SSI1_CLK_ON    .EQU    0x00000002   ;enable SSI1 clock in run mode
SSI_CLKS_AM     .EQU   0x00000300   ;force all SSI clocks on in all modes
SSI0_CLK_AM    .EQU    0x00000100   ;force SSI0 clock on in all modes
SSI1_CLK_AM    .EQU    0x00000200   ;force SSI1 clock on in all modes


;    Load Settings to all PCRM Registers Register CLKLOADCTL
;    Bits    Name                Code    Description
;    0       Load                1       Begin loading (Write only)
;    1       Load Done           1       Loading success (Read only)
;    2-31    Reserved            0
LOAD_CLOCKS     .EQU    0x00000001  ;set clock to load
CLOCKS_LOADED   .EQU    0x00000002  ;clock has been loaded

;    ADC Clock Control and Status Register ADCCLKCTL
;    Bits    Name                Code    Description
;    0       Request               0/1   Requests to enable the ADC clock
;    1       Clock Acknowledgement 0/1   Shows the status of the ADC clock
;    2-31    Reserved            0
LOAD_ADCCLK     .EQU    0x00000001  ;Request ADC clock to load
ADCCLK_LOADED   .EQU    0x00000003  ;ADC clock has been loaded


;  Digital Oscillator Status Signal Register STAT0
;  Bits   Name                Code   Description
;   0     PendingSCLKHFSwitch 1/0    Indicates when SCLK_HF clock source is
;                                    ready to be switched
;   1-6   ADC Data            xxxxxx Contains ADC data
;   7     ADC Data Ready      1/0    Indicates that ADC data is ready
;   8     ADC Threshhold      1/0    Indicates ADC threshhold met
;   9     Reserved            0
;   10    XOSC_HF_HP_BUF_EN   1/0    XOSC_HF_HP_BUF_EN
;   11    XOSC_HF_LP_BUF_EN   1/0    XOSC_HF_LP_BUF_EN
;   12    Reserved            0
;   13    XB_48M_CLK_EN       1/0    Indicates that the 48MHz clock from the
;                                    DOUBLER is enabled. It will be enabled if
;                                    24 or 48 MHz crystal is used (enabled in
;                                    doubler bypass for the 48MHz crystal)
;   14    Reserved            0
;   15    XOSC_HF_EN          1/0    Indicates that XOSC_HF is enabled
;   16    SCLK_LF_LOSS        1/0    Indicates if SCLK_LF is lost
;   17    SCLK_HF_LOSS        1/0    Indicates if SCLK_HF is lost
;   18    CLK_DCDC_RDY_ACK    1/0    CLK_DCDC_RDY_ACK
;   19    CLK_DCDC_RDY        1/0    CLK_DCDC_RDY
;   20    XOSC_LF_EN          1/0    XOSC_LF_EN
;   21    RCOSC_LF_EN         1/0    RCOSC_LF_EN
;   22    RCOSC_HF_EN         1/0    RCOSC_HF_EN
;   23-27 Reserved            0
;   28    SCLK_HF_SRC         0       SCLK_HF = High frequency RCOSC clock
;                             1       SCLK_HF = High frequency XOSC clock
;   29-30 SCLK_LF_SRC         0       SCLK_LF = High frequency RCOSC clock
;                             1       SCLK_LF = High frequency XOSC clock
;                             2       SCLK_LF = Low frequency RCOSC clock
;                             3       SCLK_LF = Low frequency XOSC clock
;   31      Reserved          0
ADCDATAREADYMASK  .EQU  0x00000080  ;Used to get the ADC data ready bit
ADCDATAMASK      .EQU   0x0000007E  ;Used to get ADC data

;  Digital Oscillator Status Signal Register STAT1
;  Bits   Name                Code   Description
;   0     CLK_DCDC_GOOD       1/0    Indicates when CLK_DCDC_GOOD
;   1     CLK_CHP_GOOD        1/0    Indicates when CLK_CHP_GOOD
;   2     ACLK_REF_GOOD       1/0    Indicates when ACLK_REF_GOOD
;   3     ACLK_TDC_GOOD       1/0    Indicates when ACLK_TDC_GOOD
;   4     ACLK_ADC_GOOD       1/0    Indicates when ACLK_ADC_GOOD
;   5     SCLK_LF_GOOD        1/0    Indicates when SCLK_LF_GOOD
;   6     SCLK_MF_GOOD        1/0    Indicates when SCLK_MF_GOOD
;   7     SCLK_HF_GOOD        1/0    Indicates when SCLK_HF_GOOD
;   8     CLK_DCDC_EN         1/0    Indicates when CLK_DCDC_EN
;   9     CLK_CHP_EN          1/0    Indicates when CLK_CHP_EN
;   10    ACLK_REF_EN         1/0    Indicates when ACLK_REF_EN
;   11    ACLK_TDC_EN         1/0    Indicates when ACLK_TDC_EN
;   12    ACLK_ADC_EN         1/0    Indicates when ACLK_ADC_EN
;   13    SCLK_MF_EN          1/0    Indicates when SCLK_MF_EN
;   14    SCLK_HF_EN          1/0    Indicates when SCLK_HF_EN
;   15    FORCE_RCOSC_HF      1/0    Indicates when FORCE_RCOSC_HF
;   16-21 LPM_UPDATE_AMP      xxxxxx XOSC_HF amplitude during LPM_UPDATE state
;                                    When amplitude compensation of XOSC_HF is
;                                    enabled in low power mode, this value is
;                                    the amplitude of the crystal oscillations
;                                    measured by the on-chip oscillator ADC,
;                                    divided by 15 mV. For example, a value of
;                                    0x20 would indicate that the amplitude of
;                                    the crystal is approximately 480 mV. To
;                                    enable amplitude compensation, AON_WUC
;                                    OSCCFG must be set to a non-zero value
;   22-27 HPM_UPDATE_AMP      xxxxxx XOSC_HF amplitude during HPM_UPDATE state
;                                    When amplitude compensation of XOSC_HF is
;                                    enabled in high performance mode, this
;                                    value is the amplitude of the crystal
;                                    oscillations measured by the on-chip
;                                    oscillator ADC, divided by 15 mV. For
;                                    example, a value of 0x20 would indicate
;                                    that the amplitude of enable amplitude
;                                    compensation, AON_WUC
;                                    OSCCFG must be set to a non-zero value
;   28-31 RAMPSTATE           0      AMPCOM FSM state = RESET
;                             1      AMPCOM FSM state = INITALIZATION
;                             2      AMPCOM FSM state = HPM_RAMP1
;                             3      AMPCOM FSM state = HPM_RAMP2
;                             4      AMPCOM FSM state = HPM_RAMP3
;                             5      AMPCOM FSM state = HPM_UPDATE
;                             6      AMPCOM FSM state = IDAC_INCREMENT
;                             7      AMPCOM FSM state = IBIAS_CAP_UPDATE
;                             8      AMPCOM FSM state = IBIAS_DECRMNT_W_MEASURE
;                             9      AMPCOM FSM state = LPM_UPDATE
;                             A      AMPCOM FSM state = IBIAS_INCREMENT
;                             B      AMPCOM FSM state = IDAC_DECRMNT_W_MEASURE
;                             C      AMPCOM FSM state = DUMMY_TO_INIT_1
;                             D      AMPCOM FSM state = FAST_START
;                             E      AMPCOM FSM state = FAST_START_SETTLE
ADCCLKENMASK     .EQU   0x00000010  ;Used to check if ADC clock is good
ADCCLKGOODMASK   .EQU   0x00001010  ;Used to check if ADC clock is enabled
ADCCLKENGOODMASK .EQU   0x00001010  ;Used to check if ADC clock is enabled and good




;;;;;;Memory Register Adresses;;;;;;

;Base Addresses
PRCM            .EQU    0x40082000  ;Power, Clocks, Reset managment

;PCRM Address Offsets
PDCTL0      .EQU    0x12C   ;Power
PDSTAT0     .EQU    0x140   ;Power status
GPIOCLKGR   .EQU    0x48    ;GPIO clock power
GPTCLKGR    .EQU    0x54    ;GPT clock power
SSICLKGR    .EQU    0x78    ;SSI clock power
CLKLOADCTL  .EQU    0x28    ;System clock
