;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                              ;
;                 GOREPCB Keypad Demo Initialization Functions                 ;
;                                 George Ore                                   ;
;                                                                              ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description: This file contains functions that initialize the power, GPT,
;              GPIO, and clocks.
; Goal: The goal of these functions is to facilitate startup and modularize
;       the codebase.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           Required Constant Files
    .include "configPWR&CLK.inc"  ; contains power config constants
    .include "configGPIO.inc"     ; contains GPIO config constants
    .include "GPIO.inc"           ; contains GPIO control constants
    .include "GPT.inc"            ; contains GPT control constants
    .include "constants.inc"      ; contains misc. constants
    .include "macros.inc"         ; contains all macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           Required Functions
;   None
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                               Table of Contents
;       Function Name   |   Purpose
    .def    InitPower    ;   Initialize power
    .def    InitClocks   ;   Initialize clocks
    .def    InitGPIO     ;   Initialize GPIO configurations
    .def    InitGPT0     ;   Initialize GPT0 configurations
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Revision History:   02/04/24 George Ore   Created format
;                     05/28/24 George Ore   Ported to EE110a HW2
;                     06/20/25 George Ore   Modified for GOREPCB and github
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;*******************************************************************************
;*                              FUNCTIONS                                      *
;*******************************************************************************
.text                           ; program memory space start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; InitPower:
; Description: This function initializes the peripheral power.
; Operation: Writes to the power control registers and waits until status on.
; Arguments: None
; Return Values: None
; Local Variables: None
; Shared Variables: None
; Global Variables: None
; Input: None
; Output: None
; Error Handling: None
; Registers Changed: Power control registers, R0, R1
; Stack Depth: 1 word
; Algorithms: None
; Data Structures: None
; Revision History: 12/4/23 George Ore added documentation
; Pseudo Code:
;   PDCTL0 is written to in order to turn power on
;   peripheral power turned on
;   Wait until power is on
;   test = poweron  ;Load test constant
;   Load PDSTAT0 to check if power is on
;   stat = PDSTAT0
;   while(test!=stat)   ;Compare test constant with PDSTAT0
;       stat = PDSTAT0  ;Keep looping if power is not on
;   BX LR   ;Return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
InitPower:
    ; PDCTL0 is written to in order to turn power on
    MOV32   R1, PRCM                    ; Load base address
    STREG   PERIF_PWR_ON, R1, PDCTL0    ; Peripheral power turned on

WaitPON:                                ; Wait until power is on
    MOV32   R0, PERIF_STAT_ON           ; Load test constant

    MOV32   R2, PRCM                    ; Load PDSTAT0 to check if power is on
    LDR     R1, [R2, #PDSTAT0]

    SUB     R0, R1                      ; Compare test constant with PDSTAT0
    CMP     R0, #0
    BNE     WaitPON                     ; Keep looping if power is not on
    BX      LR                          ; Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; InitClocks:
; Description: This function initializes the required clocks.
; Operation: Writes to the clock control registers.
; Arguments: None
; Return Values: None
; Local Variables: None
; Shared Variables: None
; Global Variables: None
; Input: None
; Output: None
; Error Handling: None
; Registers Changed: Clock control registers, R0, R1
; Stack Depth: 1 word
; Algorithms: None
; Data Structures: None
; Revision History: 12/4/23 George Ore added documentation
; Pseudo Code:
;   Write to GPIOCLKGR to turn on the GPIO clock power
;   Write to GPTCLKGR to turn on the GPT clock power
;   Write to CLKLOADCTL to turn on GPIO clock
;   Wait for clock settings to be set
;   test =  CLOCKS_LOADED  ;Load success condition
;   Load CLKLOADCTL to check if settings have loaded successfully
;   stat = PDSTAT0
;   while(test!=stat)   ;Compare test constant with PDSTAT0
;       stat = CLKLOADCTL  ;Keep looping if loading
;   BX LR   ;Return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
InitClocks:
    MOV32   R1, PRCM                    ; Load base address
    ; Write to GPIOCLKGR to turn on the GPIO clock power
    STREG   GPIO_CLOCK_ON, R1, GPIOCLKGR    ; GPIO clock power on
    ; Write to GPTCLKGR to turn on the GPT clock power
    STREG   GPT0_CLK_ON, R1, GPTCLKGR      ; GPT clock power on
    ; Write to CLKLOADCTL to turn on GPIO clock
    STREG   LOAD_CLOCKS, R1, CLKLOADCTL     ; Load clock settings

WaitCLKPON:                             ; Wait for clock settings to be set
    MOV32   R0, CLOCKS_LOADED           ; Load success condition

    MOV32   R2, PRCM                    ; Read CLKLOADCTL to check if settings
    LDR     R1, [R2, #CLKLOADCTL]       ; have loaded successfully

    SUB     R0, R1                      ; Compare test condition with CLKLOADCTL
    CMP     R0, #0
    BNE     WaitCLKPON                  ; Keep looping if still loading

    BX      LR                          ; Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; InitGPIO:
; Description: This function initializes the GPIO pins.
; Operation: Writes to the GPIO control registers.
; Arguments: None
; Return Values: None
; Local Variables: None
; Shared Variables: None
; Global Variables: None
; Input: Constants defining GPIO controls
; Output: Writes to GPIO control registers
; Error Handling: None
; Registers Changed: GPIO control registers, R0, R1
; Stack Depth: 1 word
; Algorithms: None
; Data Structures: None
; Revision History: 12/4/23 George Ore added documentation
; Pseudo Code:
;   Write to IOCFG0-3 to be row testing outputs
;   Load base address
;   Set GPIO pin 0 as an output
;   Set GPIO pin 1 as an output
;   Set GPIO pin 2 as an output
;   Set GPIO pin 3 as an output
;   Write to IOCFG4-7 to be column testing inputs
;   Set GPIO pin 4 as an input with pull-up resistor
;   Set GPIO pin 5 as an input with pull-up resistor
;   Set GPIO pin 6 as an input with pull-up resistor
;   Set GPIO pin 7 as an input with pull-up resistor
;   Write to DOE31_0 to enable the LED outputs
;   Load base address
;   Enable pins 0-3 as outputs
;   BX LR  ;Return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
InitGPIO:
    ; Write to IOCFG11-14 to be row testing outputs
    MOV32   R1, IOC                    ; Load base address
    STREG   IO_OUT_CTRL, R1, IOCFG11
    STREG   IO_OUT_CTRL, R1, IOCFG12
    STREG   IO_OUT_CTRL, R1, IOCFG13
    STREG   IO_OUT_CTRL, R1, IOCFG14

    ; Write to IOCFG15 and IOCFG18-20 to be column testing inputs
    STREG   IO_IN_CTRL, R1, IOCFG15
    STREG   IO_IN_CTRL, R1, IOCFG18
    STREG   IO_IN_CTRL, R1, IOCFG19
    STREG   IO_IN_CTRL, R1, IOCFG20

    ; Write to DOE31_0 to enable the keypad outputs
    MOV32   R1, GPIO                   ; Load base address
    STREG   KEYOUT_ENABLE, R1, DOE31_0 ; Enable keypad output pins
    BX      LR                         ; Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; InitGPT0:
; Description: This function initializes the GPT0 and its interrupts.
; Operation: Writes to the GPT0 and SCS control registers.
; Arguments: None
; Return Values: None
; Local Variables: None
; Shared Variables: None
; Global Variables: None
; Input: Constants defining GPT0 controls
; Output: Writes to GPT0 control registers
; Error Handling: None
; Registers Changed: GPT0 and SCS control registers, R0, R1
; Stack Depth: 1 word
; Algorithms: None
; Data Structures: None
; Revision History: 12/4/23 George Ore added documentation
; Pseudo Code:
;   Load base address
;   32-bit timer
;   Enable timer with debug stall
;   Enable timeout interrupt
;   Enable periodic mode
;   Set timer duration to 1ms
;   BX LR  ;Return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
InitGPT0:
    MOV32   R1, GPT0                   ; Load base address
    STREG   CFG_32x1, R1, CFG          ; 32-bit timer
    STREG   CTL_TA_STALL, R1, CTL      ; Enable timer with debug stall
    STREG   IMR_TA_TO, R1, IMR         ; Enable timeout interrupt
    STREG   TAMR_PERIODIC, R1, TAMR    ; Enable periodic mode
    STREG   TIMER16_1ms, R1, TAILR     ; Set timer duration to 1ms

    MOV32   R1, SCS                    ; Load base address
    STREG   EN_INT_TA, R1, NVIC_ISER0  ; Interrupt enable

    BX      LR                         ; Return

.end
