;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                              ;
;                       EE110a HW5 Initialization Functions                    ;
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
    .include "ADC.inc"            ; contains all ADC constants

    .global angle
    .global pwm_stat
    .global VecTable
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           Required Functions
	.ref	GPT1EventHandler	;	Step one degree in PWM
	.ref	Wait_1ms			; 	Wait in units of 1ms
	.ref	WaitLCDBusy			; 	Wait (blocking) while LCD is busy
	.ref	LowestLevelWrite	;	Write a command to the LCD

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                               Table of Contents
;       Function Name   		|   Purpose
    .def    InitPower    		;   Initialize power
    .def    InitClocks   		;   Initialize clocks
    .def    InitGPIO     		;   Initialize GPIO configurations
    .def    InitGPTs     		;   Initialize GPTs configurations
    .def	InitVariables		;	Initalize variables
    .def	InitRegisters		;	Initalize vectors
    .def	MoveVecTable		;	Initalize custom vector table
    .def	InstallGPT1Handler	;	Install PWM handler
	.def	InitPWM				;	Initalize PWM
    .def	InitADC				;	Intialize ADC
    .def	InitLCD				;	Initalize LCD
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Revision History:   02/04/24 George Ore   Created format
;                     05/30/24 George Ore   Ported to EE110a HW3
;                     06/23/24 George Ore   Refactored and turned in
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;*******************************************************************************
;*                              FUNCTIONS                                      *
;*******************************************************************************
.text                           ; program memory space start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; InitPower:
;
;
; Description:	This function initalizes the peripheral power.
;
; Operation:    Writes to the power control registers and waits until status on
;
; Arguments:         None
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Registers Changed: Power control registers, R0, R1
; Stack Depth:       1 word
;
; Algorithms:        None.
; Data Structures:   None.
;
; Revision History:  12/4/23	George Ore	 added documentation
;
; Pseudo Code
;
;	PDCTL0 is writen to in order to turn power on
;	peripheral power turned on
;
;	Wait until power is on
;	test = poweron		;Load test constant
;
;	Load PDSTAT0 to check if power is on
;	stat = PDSTAT0
;
;	while(test!=stat) 	;Compare test constant with PDSTAT0
;		stat = PDSTAT0	;Keep looping if power is not on
;
;	BX		LR 				;Return
InitPower:
	;PDCTL0 is writen to in order to turn power on
	MOV32	R1, PRCM					;Load base address
	STREG   PERIF_PWR_ON, R1, PDCTL0	;peripheral power turned on

WaitPON:					;Wait until power is on
	MOV32 	R0, PERIF_STAT_ON	;Load test constant

	MOV32	R2, PRCM		;Load PDSTAT0 to check if power is on
	LDR		R1, [R2,#PDSTAT0]

	SUB   	R0, R1 			;Compare test constant with PDSTAT0
	CMP 	R0, #0
	BNE		WaitPON			;Keep looping if power is not on
	BX		LR 				;Return

; InitClocks:
;
; Description:	This function initalizes the required clocks.
;
; Operation:    Writes to the clock control registers.
;
;
; Arguments:         None
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Registers Changed: Clock control registers, R0, R1
; Stack Depth:       1 word
;
; Algorithms:        None.
; Data Structures:   None.
;
; Revision History:  12/4/23	George Ore	 Added documentation
;				     12/30/23	George Ore	 Added ADC clock
;
;
; Pseudo Code
;
;	Write to GPIOCLKGR to turn on the GPIO clock power
;	Write to GPTCLKGR to turn on the GPT clock power
;	Write to CLKLOADCTL to turn on GPIO clock
;
;	;Wait for clock settings to be set
;	test =  CLOCKS_LOADED	;Load success condition
;
;	;Load CLKLOADCTL to check if settings have loaded successfully
;	stat = PDSTAT0
;
;	while(test!=stat) 		;Compare test constant with PDSTAT0
;		stat = CLKLOADCTL	;Keep looping if loading
;
;	Do the same for the AUX domain ADC clock ^
;
;	BX		LR 				;Return
InitClocks:
	MOV32	R1, PRCM					;Load base address
	;Write to GPIOCLKGR to turn on the GPIO clock power
	STREG   GPIO_CLOCK_ON, R1, GPIOCLKGR	;GPIO clock power on
	;Write to GPTCLKGR to turn on the GPT clock power
	STREG   GPT_CLKS_ON, R1, GPTCLKGR	;Turn all GPTs on
	;Write to CLKLOADCTL to turn on GPIO clock
	STREG   LOAD_CLOCKS, R1, CLKLOADCTL		;Load clock settings

	MOV32	R1, AUX_SYSIF					;Load base address
	;Request to ADC clock to turn on
	STREG   LOAD_ADCCLK, R1, ADCCLKCTL		;Load clock settings

WaitCLKPON:						;Wait for clock settings to be set
	MOV32 	R0, CLOCKS_LOADED	;Load success condition

	MOV32	R2, PRCM			;Read CLKLOADCTL to check if settings
	LDR		R1, [R2,#CLKLOADCTL];have loaded successfully

	SUB   	R0, R1 				;Compare test condition with CLKLOADCTL
	CMP 	R0, #0
	BNE		WaitCLKPON			;Keep looping if still loading
	;BEQ 	WaitADCCLKON

WaitADCCLKON:					;Wait for ADC clock request to process
	MOV32 	R0, ADCCLK_LOADED	;Load success condition

	MOV32	R2, AUX_SYSIF		;Read ADCCLKCTL to check if ADC
	LDR		R1, [R2,#ADCCLKCTL];clock request is done

	SUB   	R0, R1 				;Compare test condition with ADCCLKCTL
	CMP 	R0, #0
	BNE		WaitADCCLKON		;Keep looping if still loading
	;BEQ 	ENDInitClocks

ENDInitClocks:
	BX		LR					;Return

; InitGPIO
;
; Description:	This function initalizes the GPIO pins.
;
; Operation:    Writes to the GPIO control registers.
;
;
; Arguments:         None
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             Constants defining GPIO controls
; Output:            Writes to GPIO control registers
;
; Error Handling:    None.
;
; Registers Changed: GPIO control registers, R0, R1
; Stack Depth:       1 word
;
; Algorithms:        None.
; Data Structures:   None.
;
; Revision History:  12/4/23	George Ore	 added documentation
;
; Pseudo Code
;
;	Setup LCD pins
;
;	Setup servo pins
;
;	Output enable pins
;
;	BX		LR			;Return
InitGPIO:
    ; Write to IOCFG8-15 to be databus outputs
    MOV32   R1, IOC                     ; Load base address
    STREG   IO_OUT_CTRL, R1, IOCFG8     ; Set GPIO pin 8 as an output
    STREG   IO_OUT_CTRL, R1, IOCFG9     ; Set GPIO pin 9 as an output
    STREG   IO_OUT_CTRL, R1, IOCFG10    ; Set GPIO pin 10 as an output
    STREG   IO_OUT_CTRL, R1, IOCFG11    ; Set GPIO pin 11 as an output
    STREG   IO_OUT_CTRL, R1, IOCFG12    ; Set GPIO pin 12 as an output
    STREG   IO_OUT_CTRL, R1, IOCFG13    ; Set GPIO pin 13 as an output
    STREG   IO_OUT_CTRL, R1, IOCFG14    ; Set GPIO pin 14 as an output
    STREG   IO_OUT_CTRL, R1, IOCFG15    ; Set GPIO pin 15 as an output

; *** AVOID GPIO 16 and 17 because they are used for debugging

    ; Write to IOCFG18 to be chip enable (E) output
    STREG   IO_OUT_CTRL, R1, IOCFG18    ; Set GPIO pin 18 as an output

    ; Write to IOCFG19 to be register select (RW) output
    STREG   IO_OUT_CTRL, R1, IOCFG19    ; Set GPIO pin 19 as an output

    ; Write to IOCFG20 to be register select (RS) output
    STREG   IO_OUT_CTRL, R1, IOCFG20    ; Set GPIO pin 20 as an output

	;Write to IOCFG30 to be a PWM data output
	STREG   IO_OUT_CTRL, R1, IOCFG30	;Set GPIO pin 30 as an output

    ; Write to DOE31_0 to enable pins 8-15 and 18-19 as outputs
	MOV32	R1, GPIO						;Load base address
	STREG   LCD_SRVO_OUTPUT_EN, R1, DOE31_0	;Enable LCD and servo driving pins as output

	;Write to AUXIO20 to be an ADC input
	MOV32	R1, AUX_AIODIO2				;Load base address
	STREG   AUXIO8ip4IN, R1, IOMODE		;Enable AUXIO[8i+4] as input (20)
	STREG   NODIB, R1, GPIODIE			;Disable digital input buffers
	;AUX pin 20 maps to GPIO pin 29

	BX		LR							;Return

; InitGPTs
;
; Description:	This function initalizes GPT0 in PWM mode
;
; Operation:    Writes to the GPT control registers.
;
;
; Arguments:         None
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Registers Changed: GPT0, GPT1, GPT2, and SCS control registers, R0, R1
; Stack Depth:       1 word
;
; Algorithms:        None.
; Data Structures:   None.
;
; Revision History:  12/04/23	George Ore	 added documentation
; Revision History:  01/02/23	George Ore	 added interrupts
;
; Pseudo Code
;
;	Load GPT0 base address
;	32 bit timer
;	Enable one shot mode
;	Set timer duration to 1ms
;
;	GPT2 is the same as this one but its 1us instead ^^
;
;	Load GPT1 base address
;	CTL  = TimerA enable (No edge events i think) (Invert if necisary)
;	CFG	 = 16Bit
;	TAMR = TimerModeValue (PWM mode count down periodic)
;			bits 0-1 = 10
;			bit 2 = 0
;			bit 3 = 1
;
;	;20ms is 960000 (0xEA600) cycles (20 bits)
;	TAILR = 0x0000A600
;	TAPR  = 0x0000000E	only works as timer extension
;
;	TAMATCHR  = 1940	;Default to 0 degree setting (1.5ms)
;	TAPMR	  = 1
;
;	BX	LR			;Return
InitGPTs:
	;GPT0 will be our 1ms timer
	MOV32	R1, GPT0					;Load base address
	STREG   CFG_32x1, R1, CFG			;32 bit timer
	STREG   TAMR_D_ONE_SHOT, R1, TAMR	;Enable one-shot mode countdown mode
	STREG   TIMER32_1ms, R1, TAILR		;Set timer duration to 1ms
	STREG   IMR_TA_TO, R1, IMR			;Enable timeout interrupt

	;GPT1 will be our PWM timer
	MOV32	R1, GPT1					;Load base address

	STREG   CFG_16x2, R1, CFG			;16 bit timer
	STREG   TAMR_PWM_IE, R1, TAMR		;Set PWM mode with interrupts enabled
	STREG   PRESC16_20ms, R1, TAPR		;Manual says to set prescaling
	STREG   PREGPTMATCH_1p5ms, R1, TAPMR	;here for some reason
	STREG   TIMER16_20ms, R1, TAILR		;Set timer duration to 20 ms
	STREG   GPTMATCH_1p5ms, R1, TAMATCHR	;Set timer match duration to 1.5 ms
	STREG   IMR_TA_CAPEV, R1, IMR		;Enable capture mode event interrupt
	STREG   GPT_PWM_TO, R1, ANDCCP ;Handle PWM assertion bug

    ; GPT2 will be our 1us tCycle timer (for write operation timing)
    MOV32   R1, GPT2                    ; Load base address
    STREG   CFG_16x2, R1, CFG           ; 32 bit timer
    STREG   TAMR_D_ONE_SHOT, R1, TAMR   ; Enable timer one-shot countdown mode
    STREG   TIMER32_1us, R1, TAILR      ; Set timer duration to 1us
    STREG   IMR_TA_TO, R1, IMR          ; Enable timeout interrupt

	MOV32	R1, SCS						;Load base address
	STREG   EN_INT_T1A, R1, NVIC_ISER0	;Interrupt enable

	BX	LR								;Return

; InitVariables:
;
; Description:   This function initializes the variables to the inital state.
;
; Operation:     Writes to the addresses of the variables
;
; Arguments:     None.
; Return Values: None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Registers Changed: Power control registers, R0, R1
; Stack Depth:       1 word
;
; Algorithms:        None.
; Data Structures:   None.
;
; Revision History:  12/4/23    George Ore   added documentation
;
; Pseudo Code
;
;	servoMode = SETMODE
;	angle = 0DEGREES
; 	BX    LR             ; Return
InitVariables:
	MOVA    R1, angle		;Set starting angle at 0
	MOV32   R0, ZERO_START
	STR     R0, [R1]

	MOVA    R1, pwm_stat		;Set PWM status READY
	MOV32   R0, READY
	STR     R0, [R1]
	BX LR

; InitRegisters:
;
; Description:   This function initializes the GPIO registers
;
; Operation:     Sets all pins off initally
;
; Arguments:     None
; Return Values: None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Registers Changed: GPIO control registers, R0, R1
; Stack Depth:       1 word
;
; Algorithms:        None.
; Data Structures:   None.
;
; Revision History:  12/4/23    George Ore   added documentation
;
; Pseudo Code
;	ALL GPIO TURNED OFF
; BX    LR             ; Return
InitRegisters:
	MOV32	R1, GPIO		;Load base address
	STREG   ALL_PINS, R1, DCLR31_0	;Clear all GPIO pins

; MoveVecTable:
;
; Description:       This function moves the interrupt vector table from its
;                    current location to SRAM at the location VecTable.
;
; Operation:         The function reads the current location of the vector
;                    table from the Vector Table Offset Register and copies
;                    the words from that location to VecTable.  It then
;                    updates the Vector Table Offset Register with the new
;                    address of the vector table (VecTable).
;
; Arguments:         None.
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             VTOR.
; Output:            VTOR.
;
; Error Handling:    None.
;
; Registers Changed: flags, R0, R1, R2, R3
; Stack Depth:       0 word
;
; Algorithms:        None.
; Data Structures:   None.
;
; Revision History:  11/03/21   Glen George      initial revision
;		     		 12/4/23	George Ore	 	 added to project
;
; Pseudo Code
;
;	store necessary changed registers
;	start doing the copy
;
;	setup to move the vector table
;       get base for CPU SCS registers
;       get current vector table address
;
;       load address of new location
;       get the number of words to copy
;       now loop copying the table
;
;	loop copying the vector table
;       get value from original table
;       copy it to new table
;
;       update copy count
;
;       if not done, keep copying
;       otherwise done copying
;
;	done copying data, change VTOR
;       load address of new vector table
;       and store it in VTOR
;       and all done
;
;	done moving the vector table
;       restore registers and return
;       BX      LR	;return
MoveVecTable:

        PUSH    {R4}                    ;store necessary changed registers
        ;B      MoveVecTableInit        ;start doing the copy

MoveVecTableInit:                       ;setup to move the vector table
        MOV32   R1, SCS       			;get base for CPU SCS registers
        LDR     R0, [R1, #VTOR]     	;get current vector table address

        MOVA    R2, VecTable            ;load address of new location
        MOV     R3, #VEC_TABLE_SIZE     ;get the number of words to copy
        ;B      MoveVecCopyLoop         ;now loop copying the table

MoveVecCopyLoop:                        ;loop copying the vector table
        LDR     R4, [R0], #BYTES_PER_WORD   ;get value from original table
        STR     R4, [R2], #BYTES_PER_WORD   ;copy it to new table

        SUBS    R3, #1                  ;update copy count

        BNE     MoveVecCopyLoop         ;if not done, keep copying
        ;B      MoveVecCopyDone         ;otherwise done copying

MoveVecCopyDone:                        ;done copying data, change VTOR
        MOVA    R2, VecTable            ;load address of new vector table
        STR     R2, [R1, #VTOR]     	;and store it in VTOR
        ;B      MoveVecTableDone        ;and all done

MoveVecTableDone:                       ;done moving the vector table
        POP     {R4}                    ;restore registers and return
        BX      LR						;return

;InstallGPT1Handler
;
; Description:       Install the event handler for the GPT1 timer interrupt.
;
; Operation:         Writes the address of the timer event handler to the
;                    appropriate interrupt vector.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: R0, R1
; Stack Depth:       0 words
;
; Revision History: 02/16/21   Glen George   initial revision
;		     		12/4/23    George Ore	 added to project
;
; Pseudo Code
;
;   get handler address
;   get address of SCS registers
;   get table relocation address
;   store vector address
;   BX      LR	;all done, return
InstallGPT1Handler:
    MOVA    R0, GPT1EventHandler    ;get handler address
    MOV32   R1, SCS       			;get address of SCS registers
    LDR     R1, [R1, #VTOR]     	;get table relocation address
    STR     R0, [R1, #(4 * GPT1A_EX_NUM)]   ;store vector address
    BX      LR						;all done, return


; InitPWM
;
; Description:       Install the event handler for the GPT1 timer interrupt.
;
; Operation:         Writes the address of the timer event handler to the
;                    appropriate interrupt vector.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: R0, R1
; Stack Depth:       0 words
;
; Revision History: 02/16/21   Glen George   initial revision
;		     		12/4/23    George Ore	 added to project
;
; Pseudo Code
;
;   get handler address
;   get address of SCS registers
;   get table relocation address
;   store vector address
;   BX      LR	;all done, return
InitPWM:
	;GPT1 is our PWM timer
	MOV32	R1, GPT1					;Load base address
	STREG   GPT_CTL_EN_TA_PWM_STALL, R1, CTL ;Enable PWM timer A with debug stall
    BX      LR	;all done, return

; InitADC:
;
; Description:	The function initalizes the settings for the ADC.
;
; Operation:    Writes to the memory mapped registers associated with the ADC
;				with the appropriate values.
;
; Arguments:         None.
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None
; Output:            None
;
; Error Handling:    None.
;
; Registers Changed: R0, R1, R2, R3, R4
; Stack Depth:       1 word
;
; Algorithms:        None.
; Data Structures:   None.
;
; Revision History:  12/6/24	George Ore	 created
;
; Pseudo Code
;
;	Mux the correct pin
;
;	Set the sample rate
;
;	Set the ADC reference
;
;	Enable ADC
;
;	return
InitADC:
	PUSH    {R0, R1, R2, R3}	;Push registers

	MOV32	R1, AUX_ADI4		;Load analog digital interface master base address

;	Mux AUXIO20 (GPIO 29) into the ADC channel
	STREG   MUX_AUXIO20, R1, MUX3	;FIX THIS

;	Enable ADC module in synchronous mode with 2.7us sampling rate
	STREG   ENADC_SYNC_341us, R1, ADC0 ;341microseconds

;	Enable ADC reference even in idle state
	STREG   ADC_REF_EN_4p3_IDLE, R1, ADCREF0	;YYOU NEED THIS

	MOV32	R1, AUX_ANAIF		;Load analog interface base address

	NOP		;Two 48MHz clocks are needed before enabling or
	NOP		;disabling the ADC control interface
	NOP
	NOP
;	Enable ADC control interface with manual trigger
	STREG   ENABLEADC_MANUAL, R1, ADCCTL

ENDInitADC:
	POP    	{R0, R1, R2, R3}	;Pop registers
	BX		LR			;Return

; InitLCD:
;
; Description:	Initalizes the LCD.
;
; Operation:    Sends SPI commands to initalize the LCD. Has
;				delays as specified by the datasheet.
;
; Arguments:         None.
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None
; Output:            None
;
; Error Handling:    None.
;
; Registers Changed: R0, R1, R2, R3, R4
; Stack Depth:       1 word
;
; Algorithms:        None.
; Data Structures:   None.
;
; Revision History:  12/6/24	George Ore	 created
;
; Pseudo Code
;
;	Function commands and delay font and lines
;
;	Turn LCD off
;	Clear LCD command
;	Entry mode set command
;	Write command
;
;	return
InitLCD:    ; The following is LCD function set/startup
    MOV32   R0, WAIT30             ; Wait 30 ms (15 ms min)
    PUSH {LR}
    BL      Wait_1ms
	POP {LR}
    PUSH {LR}
    BL      WaitLCDBusy
	POP {LR}
    MOV32   R0, FSET_2LINES_DFONT  ; Write function set command
    MOV32   R1, FSET_RS
    PUSH {LR}
    BL      LowestLevelWrite
	POP {LR}

    MOV32   R0, WAIT8              ; Wait 8 ms (4.1 ms min)
    PUSH {LR}
    BL      Wait_1ms
	POP {LR}

    MOV32   R0, FSET_2LINES_DFONT  ; Write function set command
    MOV32   R1, FSET_RS
    PUSH {LR}
    BL      LowestLevelWrite
	POP {LR}

    MOV32   R0, WAIT1              ; Wait 1 ms (100 us min)
    PUSH {LR}
    BL      Wait_1ms
	POP {LR}

    MOV32   R0, FSET_2LINES_DFONT  ; Write function set command
    MOV32   R1, FSET_RS
    PUSH {LR}
    BL      LowestLevelWrite
	POP {LR}

; From here we need to wait until the busy flag is reset before executing the next command
    PUSH {LR}
    BL      WaitLCDBusy
   	POP {LR}
    MOV32   R0, FSET_2LINES_DFONT  ; Write function set command
    MOV32   R1, FSET_RS
    PUSH {LR}
    BL      LowestLevelWrite
	POP {LR}

    PUSH {LR}
    BL      WaitLCDBusy
	POP {LR}
    MOV32   R0, LCD_OFF            ; Write display off command
    MOV32   R1, LCD_OFF_RS
    PUSH {LR}
    BL      LowestLevelWrite
	POP {LR}

    PUSH {LR}
    BL      WaitLCDBusy
	POP {LR}
    MOV32   R0, CLR_LCD            ; Write clear display command
    MOV32   R1, CLR_LCD_RS
    PUSH {LR}
    BL      LowestLevelWrite
	POP {LR}

    PUSH {LR}
    BL      WaitLCDBusy
	POP {LR}
    MOV32   R0, FWD_INC            ; Write entry mode set command
    MOV32   R1, ENTRY_RS
    PUSH {LR}
    BL      LowestLevelWrite
	POP {LR}

    PUSH {LR}
    BL      WaitLCDBusy
	POP {LR}
    MOV32   R0, CUR_BLINK          ; Write display on command
    MOV32   R1, LCD_ON_RS
    PUSH {LR}
    BL      LowestLevelWrite
	POP {LR}

	BX	LR	;Return

.end
