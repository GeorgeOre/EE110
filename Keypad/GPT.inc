;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           GPT Control Constants                              ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description:       This file holds constants to be used in the main file
;
; Revision History:   11/08/23  George Ore      initial revision
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;Memory Register Values;;;;;;

;    GPT Configuration Register CFG *****
;       Bits    Name                Code    Description
;       0-2     Configuration       0x0     32 bit timer
;                                   0x4     16 bit timer
;       3-31    Reserved            0
CFG_32x1       .equ    0x00000000   ;configure as a single 32-bit timer
CFG_16x2       .equ    0x00000004   ;configure as two 16-bit timers

;   Control Register CTL            *****
;       Bits    Name                Code    Description
;       0       Timer A Enable      0x0     Timer A disabled
;                                   0x1     Timer A enabled
;       1       Timer A Stall Enbl  0x0     Continues counting if debug halts
;                                   0x1     Freezes when  debug halts
;       2-3     Timer A Event Mode  0x0     Event when positive edge
;                                   0x1     Event when negative edge
;                                   0x3     Event when both edges
;       4-5     Reserved            0
;       6       Timer A PWM Out Lvl 0x0     Output normal
;                                   0x1     Output inverted
;       7       Reserved            0
;       8       Timer B Enable      0x0     Timer B disabled
;                                   0x1     Timer B enabled
;       9       Timer B Stall Enbl  0x0     Continues counting if debug halts
;                                   0x1     Freezes when  debug halts
;       10-11   Timer B Event Mode  0x0     Event when positive edge
;                                   0x1     Event when negative edge
;                                   0x3     Event when both edges
;       13-12   Timer B PWM Out Lvl 0x0     Output normal
;                                   0x1     Output inverted
;       15-31   Reserved            0
GPT_CTL_TBPWM_INV  .equ    0x00008000   ;invert timer B PWM output
GPT_CTL_TBEV_POS   .equ    0x00000000   ;timer B event on positive edge
GPT_CTL_TBEV_NEG   .equ    0x00000400   ;timer B event on negative edge
GPT_CTL_TBEV_BOTH  .equ    0x00000C00   ;timer B event on both edges
GPT_CTL_TBSTALL    .equ    0x00000200   ;stop timer B during debug halt
GPT_CTL_TBEN       .equ    0x00000100   ;enable timer B
GPT_CTL_TBDIS      .equ    0x00000000   ;disable timer B
GPT_CTL_TAPWM_INV  .equ    0x00000080   ;invert timer A PWM output
GPT_CTL_TAEV_POS   .equ    0x00000000   ;timer A event on positive edge
GPT_CTL_TAEV_NEG   .equ    0x00000004   ;timer A event on negative edge
GPT_CTL_TAEV_BOTH  .equ    0x0000000C   ;timer A event on both edges
GPT_CTL_TASTALL    .equ    0x00000002   ;stop timer A during debug halt
GPT_CTL_TAEN       .equ    0x00000001   ;enable timer A
GPT_CTL_TADIS      .equ    0x00000000   ;disable timer A
CTL_TA_STALL       .EQU    0x00000003  ;enable timer A w/ stall

;   Interrupt Mask Register IMR     ***
;       Bits    Name                Code    Description
;       0       Timer A Timeout Interupt Raw -> Masked
;                                   0/1     Disable/Enable
;       1       Timer A Capture Mode Match Interupt Raw -> Masked
;                                   0/1     Disable/Enable
;       2       Timer A Capture Mode Event Interupt Raw -> Masked
;                                   0/1     Disable/Enable
;       3       Reserved            0
;       4       Timer A Match Interupt Raw -> Masked
;                                   0/1     Disable/Enable
;       5       Timer A Direct Memory Access Done Interupt Raw -> Masked
;                                   0/1     Disable/Enable
;       6-7     Reserved            0
;       8       Timer B Timeout Interupt Raw -> Masked
;                                   0/1     Disable/Enable
;       9       Timer B Capture Mode Match Interupt Raw -> Masked
;                                   0/1     Disable/Enable
;       10      Timer B Capture Mode Event Interupt Raw -> Masked
;                                   0/1     Disable/Enable
;       11      Timer B Match Interupt Raw -> Masked
;                                   0/1     Disable/Enable
;       12      Reserved            0
;       13      Timer B Direct Memory Access Done Interupt Raw -> Masked
;                                   0/1     Disable/Enable
;       14-31   Reserved            0
IMR_TA_TO   .EQU    0x00000001  ;enable timer A timeout interrupt

;   Timer Mode Registers TAMR/TBMR  *****
;       Bits    Name                Code    Description
;       0-1     Mode                0x0     Reserved
;                                   0x1     One Shot Timer Mode
;                                   0x2     Periodic Timer Mode
;                                   0x3     Capture Mode
;       2       Capture Mode        0x0     Edge count mode
;                                   0x1     Edge time mode
;       3       Alternate Mode      0x0     Capture/compare mode enabled
;                                   0x1     PWM mode enabled
;       4       Count Direction     0x0     Down
;                                   0x1     Up (starts at 0)
;       5       Match Interupt Enbl 0x0     Match interupt disabled
;                                   0x1     Match interupt enabled
;       6       Wait On Trigger     0x0     Begins as soon as enabled
;                                   0x1     Used to daisy chain timers
;       7       Snap Shot Mode      0x0     Snap shot mode disabled
;                                   0x1     If periodic, value into TAR
;       8       PWM Interval Write  0x0     Upd8 TAR with TAILR value NX-Cycle
;                                   0x1     Upd8 TAR with TAILR value NX-T-O
;       9       PWM Interrupt Enbl  0x0     Interrupts disabled
;                                   0x1     Interrupts enabled
;       10      Match Reg Upd8 Mode 0x0     TAMATCHR &TAPR if used next cycle
;                                   0x1     TAMATCHR &TAPR if used next timeout
;       11      PWM Legacy Opr8tion 0x0     CCP low when TAILR reloded after T-O
;                                   0x1     CCP output pin set on timeout
;       12      1-Shot Intrpt Dsabl 0x0     Timeout interrupt normal
;                                   0x1     Timeout interrupt disabled
;       13-15   Timer Cmpare Action 0x0     Disable compare operations
;                                   0x1     Toggle state on timeout
;       *CCP = capture compare pin  0x2     Clear CCP on timeout
;                                   0x3     Set CCP on timeout
;                                   0x4     Preset CCP & toggle on timeout
;                                   0x5     Preclear CCP & toggle on timeout
;                                   0x6     Preset CCP & clear on timeout
;                                   0x7     Preclear CCP & clear on timeout
;       16-31   Reserved            0
TAMR_PERIODIC   .EQU    0x00000002  ;periodic timer A

;   Interval Load Register TAILR/TBILR      *****
;       Bits    Name                Code    Description
;       0-31    Interval Load   0xXXXXXXXX  Counter Value
;   ASSUME 48MHz system clock
TIMER32_MAX     .EQU    0xFFFFFFFF   ;maximum value for 32 bit timer
TIMER16_MAX     .EQU    0x0000FFFF   ;maximum value for 16 bit timer
TIMER16_1ms     .EQU    0x0000BB80   ;1ms for a 16 bit timer

;   Prescale Register TAPR/TBPR
;       Bits    Name        Code    Description
;       0-7     Prescale    0xXX    Number that must be counted before updating
;                                   the TAR & TAV registers
;       8-31    Reserved    0

; RIS - raw interrupt status register
; MIS - masked interrupt status register
; ICLR - interrupt clear register




GPT_IRQ_DMAB       .equ    0x00002000   ;timer B DMA interrupt
GPT_IRQ_TBM        .equ    0x00000800   ;timer B match interrupt
GPT_IRQ_CBE        .equ    0x00000400   ;timer B capture event interrupt
GPT_IRQ_CBM        .equ    0x00000200   ;timer B capture mode match interrupt
GPT_IRQ_TBTO       .equ    0x00000100   ;timer B timeout interrupt
GPT_IRQ_DMAA       .equ    0x00000020   ;timer A DMA interrupt
GPT_IRQ_TAM        .equ    0x00000010   ;timer A match interrupt
GPT_IRQ_CAE        .equ    0x00000004   ;timer A capture event interrupt
GPT_IRQ_CAM        .equ    0x00000002   ;timer A capture mode match interrupt
IRQ_TATO           .equ    0x00000001   ;timer A timeout interrupt

; SYNC - timer synchronization register

GPT_SYNC_GPT3_NONE .equ    0x00000000   ;no GPT3 synchronization
GPT_SYNC_GPT3_A    .equ    0x00000040   ;synchronize GPT3A
GPT_SYNC_GPT3_B    .equ    0x00000080   ;synchronize GPT3B
GPT_SYNC_GPT3_AB   .equ    0x000000C0   ;synchronize GPT3A and GPT3B
GPT_SYNC_GPT2_NONE .equ    0x00000000   ;no GPT2 synchronization
GPT_SYNC_GPT2_A    .equ    0x00000010   ;synchronize GPT2A
GPT_SYNC_GPT2_B    .equ    0x00000020   ;synchronize GPT2B
GPT_SYNC_GPT2_AB   .equ    0x00000030   ;synchronize GPT2A and GPT2B
GPT_SYNC_GPT1_NONE .equ    0x00000000   ;no GPT1 synchronization
GPT_SYNC_GPT1_A    .equ    0x00000004   ;synchronize GPT1A
GPT_SYNC_GPT1_B    .equ    0x00000008   ;synchronize GPT1B
GPT_SYNC_GPT1_AB   .equ    0x0000000C   ;synchronize GPT1A and GPT1B
GPT_SYNC_GPT0_NONE .equ    0x00000000   ;no GPT0 synchronization
GPT_SYNC_GPT0_A    .equ    0x00000001   ;synchronize GPT0A
GPT_SYNC_GPT0_B    .equ    0x00000002   ;synchronize GPT0B
GPT_SYNC_GPT0_AB   .equ    0x00000003   ;synchronize GPT0A and GPT0B


; DMAEV - DMA event register

GPT_DMA_TBM        .equ    0x00000800   ;DMA trigger on timer B match
GPT_DMA_CBE        .equ    0x00000400   ;DMA trigger on timer B capture event
GPT_DMA_CBM        .equ    0x00000200   ;DMA trigger on timer B capture match
GPT_DMA_TBTO       .equ    0x00000100   ;DMA trigger on timer B timeout
GPT_DMA_TAM        .equ    0x00000010   ;DMA trigger on timer A match
GPT_DMA_CAE        .equ    0x00000004   ;DMA trigger on timer A capture event
GPT_DMA_CAM        .equ    0x00000002   ;DMA trigger on timer A capture match
GPT_DMA_TATO       .equ    0x00000001   ;DMA trigger on timer A timeout


; ANDCCP - combined CCP output register

GPT_PWM_LOAD       .equ    0x00000000   ;PWM assertion when match load value
GPT_PWM_TO         .equ    0x00000002   ;PWM assertion when timeout
GPT_CCP_IND        .equ    0x00000000   ;timer A and B PWM independent
GPT_CCP_AND        .equ    0x00000001   ;timer A PWM output is AND of timer A and B PWM signals

; NVIC_ISER0 - interupt enable register
EN_INT_TA          .equ    0x00008000   ;

;;;;;;Memory Register Addresses;;;;;;

;Base Addresses
GPT0    .EQU    0x40010000  ;General Purpose Timer 0
SCS     .equ    0xE000E000  ;System Control Space

;GPT Data and Control Register Offsets
CFG        .equ    0x0000       ;configuration register
TAMR       .equ    0x0004       ;timer A mode register
TBMR       .equ    0x0008       ;timer B mode register
CTL        .equ    0x000C       ;control register
IMR        .equ    0x0018       ;interrupt mask register
RIS        .equ    0x001C       ;raw interrupt status register
MIS        .equ    0x0020       ;masked interrupt status register
ICLR       .equ    0x0024       ;interrupt clear register
TAILR      .equ    0x0028       ;timer A interval load register
TBILR      .equ    0x002C       ;timer B interval load register
TAMATCHR   .equ    0x0030       ;timer A match register
TBMATCHR   .equ    0x0034       ;timer B match register
TAPR       .equ    0x0038       ;timer A pre-scale register
TBPR       .equ    0x003C       ;timer B pre-scale register
TAPMR      .equ    0x0040       ;timer A pre-scale match register
TBPMR      .equ    0x0044       ;timer B pre-scale match register
TAR        .equ    0x0048       ;timer A register
TBR        .equ    0x004C       ;timer B register
TAV        .equ    0x0050       ;timer A value
TBV        .equ    0x0054       ;timer B value
TAPS       .equ    0x005C       ;timer A pre-scale snap-shot register
TBPS       .equ    0x0060       ;timer B pre-scale snap-shot register
TAPV       .equ    0x0064       ;timer A pre-scale value
TBPV       .equ    0x0068       ;timer B pre-scale value
DMAEV      .equ    0x006C       ;DMA event register
VERSION    .equ    0x0FB0       ;peripheral version register
ANDCCP     .equ    0x0FB4       ;combined CCP output register

NVIC_ISER0 .equ    0x0100       ;interupt enables
