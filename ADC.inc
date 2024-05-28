;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                 ADC Configuration and Usage Constants                        ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description:       This file holds constants to be used in the main file
;
; Revision History:   12/08/23  George Ore      initial revision
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;    Bits of ADC Control Register ADCCTL
;    Bits    Name                Code    Description
;    0-1     Command             0x0     Disable ADC
;                                0x1     Enable ADC
;                                0x3     Flush ADC FIFO
;    2-7     Reserved            0
;    8-13    ADC Start Source    0x00    AUX_EVCTL:EVSTAT0.AUXIO0
;                                0x01    AUX_EVCTL:EVSTAT0.AUXIO1
;                                0x02    AUX_EVCTL:EVSTAT0.AUXIO2
;                                0x03    AUX_EVCTL:EVSTAT0.AUXIO3
;                                0x04    AUX_EVCTL:EVSTAT0.AUXIO4
;                                0x05    AUX_EVCTL:EVSTAT0.AUXIO5
;                                0x06    AUX_EVCTL:EVSTAT0.AUXIO6
;                                0x07    AUX_EVCTL:EVSTAT0.AUXIO7
;                                0x08    AUX_EVCTL:EVSTAT0.AUXIO8
;                                0x09    AUX_EVCTL:EVSTAT0.AUXIO9
;                                0x0A    AUX_EVCTL:EVSTAT0.AUXIO10
;                                0x0B    AUX_EVCTL:EVSTAT0.AUXIO11
;                                0x0C    AUX_EVCTL:EVSTAT0.AUXIO12
;                                0x0D    AUX_EVCTL:EVSTAT0.AUXIO13
;                                0x0E    AUX_EVCTL:EVSTAT0.AUXIO14
;                                0x0F    AUX_EVCTL:EVSTAT0.AUXIO15
;                                0x10    AUX_EVCTL:EVSTAT1.AUXIO16
;                                0x11    AUX_EVCTL:EVSTAT1.AUXIO17
;                                0x12    AUX_EVCTL:EVSTAT1.AUXIO18
;                                0x13    AUX_EVCTL:EVSTAT1.AUXIO19
;                                0x14    AUX_EVCTL:EVSTAT1.AUXIO20
;                                0x15    AUX_EVCTL:EVSTAT1.AUXIO21
;                                0x16    AUX_EVCTL:EVSTAT1.AUXIO22
;                                0x17    AUX_EVCTL:EVSTAT1.AUXIO23
;                                0x18    AUX_EVCTL:EVSTAT1.AUXIO24
;                                0x19    AUX_EVCTL:EVSTAT1.AUXIO25
;                                0x1A    AUX_EVCTL:EVSTAT1.AUXIO26
;                                0x1B    AUX_EVCTL:EVSTAT1.AUXIO27
;                                0x1C    AUX_EVCTL:EVSTAT1.AUXIO28
;                                0x1D    AUX_EVCTL:EVSTAT1.AUXIO29
;                                0x1E    AUX_EVCTL:EVSTAT1.AUXIO30
;                                0x1F    AUX_EVCTL:EVSTAT1.AUXIO31
;                                0x20    AUX_EVCTL:EVSTAT2.MANUAL_EV
;                                0x21    AUX_EVCTL:EVSTAT2.AON_RTC_CH2
;                                0x22    AUX_EVCTL:EVSTAT2.AON_RTC_DLY
;                                0x23    AUX_EVCTL:EVSTAT2.AON_RTC_4KHZ
;                                0x24    AUX_EVCTL:EVSTAT2.AON_BATMON_BAT_UPD
;                                0x25    AUX_EVCTL:EVSTAT2.AON_BATMON_TEMP_UPD
;                                0x26    AUX_EVCTL:EVSTAT2.SCLK_LF
;                                0x27    AUX_EVCTL:EVSTAT2.PWN_DWN
;                                0x28    AUX_EVCTL:EVSTAT2.MCU_ACTIVE
;                                0x29    AUX_EVCTL:EVSTAT2.ADDR_RECHARGE
;                                0x2A    AUX_EVCTL:EVSTAT2.ACLK_REF
;                                0x2B    AUX_EVCTL:EVSTAT2.MCU_EV
;                                0x2E    AUX_EVCTL:EVSTAT2.AUX_COMPA
;                                0x2F    AUX_EVCTL:EVSTAT2.AUX_COMPB
;                                0x30    AUX_EVCTL:EVSTAT2.AUX_TIMER2_EV0
;                                0x31    AUX_EVCTL:EVSTAT2.AUX_TIMER2_EV1
;                                0x32    AUX_EVCTL:EVSTAT3.AUX_TIMER2_EV2
;                                0x33    AUX_EVCTL:EVSTAT3.AUX_TIMER2_EV3
;                                0x34    AUX_EVCTL:EVSTAT3.AUX_TIMER2_PULSE
;                                0x35    AUX_EVCTL:EVSTAT3.AUX_TIMER1_EV
;                                0x36    AUX_EVCTL:EVSTAT3.AUX_TIMER0_EV
;                                0x37    AUX_EVCTL:EVSTAT3.AUX_TDC_DONE
;                                0x38    AUX_EVCTL:EVSTAT3.AUX_ISRC_RESET_N
;                                0x3D    AUX_EVCTL:EVSTAT3.AUX_SMPH_AUTOTAKE_DONE
;                                0x3F    No Event
;    14      Start Polarity      0x0     Set ADC trigger on rising edge of source
;                                0x1     Set ADC trigger on falling edge of source
;    15-31   Reserved            0
;   ***You must set CMD to EN or DIS after flush.
;   ***System CPU must wait two clock cycles before it sets CMD to EN or DIS.
ENABLEADC_MANUAL   .EQU    0x3F01  ;Must wait 2 clocks before setting this
DISABLEADC_MANUAL  .EQU    0x3F00  ;Must wait 2 clocks before setting this
FLUSHADC_MANUAL    .EQU    0x3F03  ;Must set enable or disable after

;    Bits of ADC FIFO Status Register ADCFIFOSTAT
;    Bits    Name                Code    Description
;    0       Empty               0/1     FIFO is empty
;                                        reading returns previous entry
;                                        and sets underflow
;    1       Almost Full         0/1     There are 3 samples in the FIFO
;    2       Full                0/1     There are 4 samples in the FIFO
;                                        adding samples sets overflow
;    3       Underflow           0/1     FIFO has underflowed
;                                        Remains sticky until you flush
;                                        Readinf FIFO gives previous entry
;    4       Overflow            0/1     FIFO has overflowed
;                                        Remains sticky until you flush
;                                        Blocks FIFO from more entries
;    5-31    Reserved            0
ADCISEMPTY  .EQU        0x0 ;Status when ADC is empty

;    Bits of ADC FIFO Register ADCFIFO
;    Bits    Name                Code    Description
;    0-11    Empty               0x000   FIFO data
;                                        Reading gets oldest sample
;                                        Writing places dummy sample in FIFO
;    5-31    Reserved            0
ADC_DATAMASK  .EQU          0xFFF   ;Used to only receive relevant data bits

;    Bits of ADC Trigger Register ADCTRIG
;    Bits    Name                Code    Description
;    0       Start               1       Writing 1 manually triggers ADC
;    1-31    Reserved            0
TRIGGER_ADC  .EQU          0x1  ;Manually triggers ADC

;    Bits of AUX Analog MUX Gating Register MUX0
;    Bits    Name                Code    Description
;    0-3     COMPA_REF Gate      0xX     Controls gate
;                                        DOUPL/VSS/VDDS/ADCVREFP to COMPA REF bus
;    4-5     Reserved            0
;    6       ADCCOMPB_IN Gate    0/1     Controls gate VDDR to the ADC/COMPB bus
;    7       Reserved            0
NO_VDDR  .EQU          0x0  ;UNSURE: Blocks VDDR from ADC/COMPB bus

;    Bits of AUX Analog MUX Gating Register MUX2
;    Bits    Name                Code    Description
;    0-2     DAC_VREF_SEL        0xX     Controls gate
;                                        DCOUPL/VDDS/ADCREF to VREF bus
;    3-7     ADCCOMPB_IN         0xX     Controls gate
;                                        DCOUPL/VSS/VDDS to ADC/COMPB bus
NO_SOURCES  .EQU       0x0  ;UNSURE: Blocks all voltage sources from ADC/COMPB bus

;    Bits of AUX Analog MUX Gating Register MUX3
;    Bits    Name                Code    Description
;    0-7     ADCCOMPB_IN Gate    0xXX    Controls gate
;                                        AUXIO19-26 to the ADC/COMPB bus
MUX_AUXIO26  .EQU      0x80  ;UNSURE: Connects AUXIO26 to the ADC/COMPB bus

;    Bits of ADC Block Control Register ADC0
;    Bits    Name                Code    Description
;    0       ADC Enable          0/1     Controls if ADC is enabled
;    1       !Reset (Active Low) 0/1     Controls ADC reset (1 to reset)
;    2       Reserved            0
;    3-6     Sample Cycle Exp()  0x0     Sampling duration = ???333ns
;            *Only works in      0x1     Sampling duration = ???667ns
;            synchronous mode    0x2     Sampling duration = ???1.3us
;                                0x3     Sampling duration = 2.7us
;                                0x4     Sampling duration = 5.3us
;                                0x5     Sampling duration = 10.6us
;                                0x6     Sampling duration = 21.3us
;                                0x7     Sampling duration = 42.6us
;                                0x8     Sampling duration = 85.3us
;                                0x9     Sampling duration = 170us
;                                0xA     Sampling duration = 341us
;                                0xB     Sampling duration = 682us
;                                0xC     Sampling duration = 1.37ms
;                                0xD     Sampling duration = 2.73ms
;                                0xE     Sampling duration = 5.46ms
;                                0xF     Sampling duration = 10.9ms
;    7       Sample Mode         0       Synchronous mode
;                                1       Asynchronous mode
;
;The ADC does a sample-and-hold before conversion. In synchronous mode,
;the sampling starts when the ADC clock detects a rising edge on the
;trigger signal. Jitter/uncertainty will be inferred in the detection
;if the trigger signal originates from a domain that is asynchronous
;to the ADC clock. SMPL_CYCLE_EXP determines the the duration ofsampling.
;
;Conversion starts immediately after sampling ends.
;
;In asynchronous mode the sampling is continuous when enabled. Sampling
;ends and conversion starts immediately with the rising edge of the
;trigger signal. Sampling restarts when the conversion has finished.
;Asynchronous mode is useful when it is important to avoid jitter in
;the sampling instant of an externally driven signal
ENADC_SYNC_FASTEST  .EQU    0x01    ;Enables ADC in synchronous mode with UNSURE: 333ns sample time
ENADC_SYNC_2p7us    .EQU    0x01    ;Enables ADC in synchronous mode with 2.7us sample time

;    Bits of ADC Comparator/Input Sample and Scaling Control Register ADC1
;    Bits    Name                Code    Description
;    0       Scale Diable        0/1     Disables the 1408/4095 (.3438) scaling
;    1-7     Reserved            0
ADC_PRESCALE  .EQU          0x0  ;UNSURE: Keep the 1408/4095 (.3438) scaling

;    Bits of ADC Ref Control Register ADCREF0
;    Bits    Name                Code    Description
;    0       Ref Enable          0/1     Enables ADC ref
;    1-2     Reserved            0
;    3       Ref Source          0       4.3V fixed reference
;                                1       Relative reference to VDDS
;    4       EXT                 ?
;    5       IOMUX               ?
;    6       Ref Idle Enable     0/1     Enables ref in idle state
;    7       Reserved            0
ADC_REF_EN_4p3_IDLE   .EQU    0x41    ;Enable ADC reference 4.3 V even in idle
ADC_REF_4p3   .EQU    0x01    ;reference 4.3 V

;    Bits of ADC Ref Control Register ADCREF1
;    Bits    Name                Code    Description
;    0-5     VTRIM               0xXX    Trims output voltage of ADC ref
;                                        64 steps in 2s complement
;                                        Only if ref source is 4.3V ref
;                    Examples:   0x00    Nominal 1.43V
;                                0x01    Nominal+.4% = 1.435V
;                                0x3F    Nominal-.4% = 1.425V
;                                0x1F    Max 1.6V
;                                0x20    Min 1.3V
;    6-7     Reserved            0
NOMINAL_ADCREF  .EQU    0x00    ;Nominal 1.43V

;;;;;;Memory Register Adresses;;;;;;

;Base Addresses
AUX_ANAIF   .EQU  0x400C9000  ;AUX domain analog interface
AUX_ADI4    .EQU  0x400CB000  ;AUX domain digital interface master

;AUX_ANAIF Offsets
ADCCTL              .EQU    0x10    ;ADC control
ADCFIFOSTAT         .EQU    0x14    ;ADC FIFO Status
ADCFIFO             .EQU    0x18    ;ADC FIFO Data
ADCTRIG             .EQU    0x1C    ;ADC Trigger

;AUX_ADI4 Offsets
MUX0    .EQU    0x00    ;VDDR Input Gating to ORANGETOCOMPB/ADC Bus
MUX2    .EQU    0x02    ;DCOUPL/VSS/VDDS Gating to ORANGETOCOMPB/ADC
MUX3    .EQU    0x03    ;AUXIO19-26 Gating to ORANGETOCOMPB/ADC
ADC0    .EQU    0x08    ;ADC Block Control
ADC1    .EQU    0x09    ;ADC Comparator/Input Sample and Scaling Control
ADCREF0 .EQU    0xA     ;ADC Ref Control
ADCREF1 .EQU    0xB     ;ADC Ref Control
