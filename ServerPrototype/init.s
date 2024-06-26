;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																			   ;
;						EE110b HW5 Initialization Functions					   ;
;								George Ore									   ;
;																			   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description:	This file includes all the initalization functions for HW5.
;
; Goal:			The goal of these functions is to facilitate initilization
;				by dedicating specific functions to initialize the power
;				domains, clocks, and modules of the CC2652R microcontroller
;				and also for the keypad interface and LCD interface.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;							Required Constant Files
	.include "constants.inc"	;contains misc. constants
	.include "macros.inc"		;contains all macros
	.include "configPWR&CLK.inc";contains power config constants
	.include "configGPIO.inc"	;contains GPIO config constants
	.include "GPIO.inc"			;contains GPIO control constants
	.include "GPT.inc"			;contains GPT control constants
	.include "timer.inc"		;contains timer constants
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;							Required Functions
	.ref	GPT1EventHandler	;	Periodic 30 ms step handling timer

	.ref	Wait_1ms			; 	Wait in units of 1ms
	.ref	WaitLCDBusy			; 	Wait (blocking) while LCD is busy
	.ref	LowestLevelWrite	;	Write a command to the LCD

	;Relevant variables
	.global VecTable
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;								Table of Contents
;		Function Name	|	Purpose
	.def	InitPower	;	Initialize power domains
	.def	InitClocks	;	Initialize module clocks
	.def	InitGPIO	;	Initialize GPIO
	.def	InitGPTs	;	Initialize GPTs
	.def	MoveVecTable		;	Init custom vector table
	.def	InstallGPTHandlers	;	Install GPT handler functions
	.def	InitLCD		;	Initalize LCD
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Revision History:	02/04/24	George Ore	Created format
;  				    06/25/24	George Ore		touched up and turned in
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;*******************************************************************************
;*								FUNCTIONS									   *
;*******************************************************************************

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
;	BX		LR 				;Return
InitClocks:
	MOV32	R1, PRCM					;Load base address
	;Write to GPIOCLKGR to turn on the GPIO clock power
	STREG   GPIO_CLOCK_ON, R1, GPIOCLKGR	;GPIO clock power on
	;Write to GPTCLKGR to turn on the GPT clock power
	STREG   GPT_CLKS_ON, R1, GPTCLKGR	;GPT0-3 clocks power on
	;Write to CLKLOADCTL to turn on GPIO clock
	STREG   LOAD_CLOCKS, R1, CLKLOADCTL		;Load clock settings

WaitCLKPON:						;Wait for clock settings to be set
	MOV32 	R0, CLOCKS_LOADED	;Load success condition

	MOV32	R2, PRCM			;Read CLKLOADCTL to check if settings
	LDR		R1, [R2,#CLKLOADCTL];have loaded successfully

	SUB   	R0, R1 				;Compare test condition with CLKLOADCTL
	CMP 	R0, #0
	BNE		WaitCLKPON			;Keep looping if still loading

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
;	Write LCD associated pins as outputs
;
;	Write stepper controlling pins as outputs
;
;	Output enable all of the above
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


	;Write to IOCFG24, 26-28 to be the four stepping data outputs
	MOV32	R1, IOC						;Load base address
	STREG   IO_OUT_CTRL, R1, IOCFG24	;Set GPIO pin 24 as an output
	STREG   IO_OUT_CTRL, R1, IOCFG26	;Set GPIO pin 26 as an output
	STREG   IO_OUT_CTRL, R1, IOCFG27	;Set GPIO pin 27 as an output
	STREG   IO_OUT_CTRL, R1, IOCFG28	;Set GPIO pin 28 as an output

	MOV32	R1, GPIO					;Load base address
	STREG   OUTPUT_ENABLE_STEPPER_LCD, R1, DOE31_0	;Enable pins 24 and 26-28 as output

	BX		LR							;Return

; InitGPTs
;
; Description:	This function initalizes all GPT modules
;
; Operation:    Writes to the GPT0-3 control registers.
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
; Registers Changed: GPT0, GPT1, GPT2, GPT3, and SCS control registers, R0, R1
; Stack Depth:       1 word
;
; Algorithms:        None.
; Data Structures:   None.
;
; Revision History:  12/4/23	George Ore	 added documentation
;					 06/25/24	George Ore	touched up and turned in
;
; Pseudo Code
;
;	Start GPT0 as two 16 bit oneshot timers (1ms and 1us)
;
;	Start GPT1 as a 30ms periodic step update timer
;
;	Start GPT2-3 and the two PWM timers for the two motor phases
;
;	BX	LR			;Return
InitGPTs:
	;GPT0A will be our 16 bit 1ms timer
	MOV32	R1, GPT0					;Load base address
	STREG   CFG_16x2, R1, CFG			;32 bit timer
	STREG   TAMR_D_ONE_SHOT, R1, TAMR	;Enable one-shot mode countdown mode
	STREG   TIMER32_1ms, R1, TAILR		;Set timer duration to 1ms

    ;GPT0B will be our 1us tCycle timer (for write operation timing)
    MOV32   R1, GPT0                    ; Load base address
    STREG   CFG_16x2, R1, CFG           ; 32 bit timer
    STREG   TBMR_D_ONE_SHOT, R1, TBMR   ; Enable timer one-shot countdown mode
    STREG   TIMER32_1us, R1, TBILR      ; Set timer duration to 1us

	;Enable timeout interrupts for both
	STREG   IMR_TAB_TO, R1, IMR			;Enable A&B timeout interrupts

	;GPT1 will be our step timer (will trigger every time a new step needs to be taken)
	MOV32	R1, GPT1				;Load base address
	STREG   CFG_32x1, R1, CFG		;32 bit timer
	STREG   IMR_TA_TO, R1, IMR		;Enable timeout interrupt
	STREG   TAMR_D_PERIODIC, R1, TAMR	;Enable periodic mode
	STREG   TIMER32_30ms, R1, TAILR	;Set timer duration to 50ms
	STREG   CTL_TA_STALL, R1, CTL	;Enable timer with debug stall

	;GPT2 will be our motor channel A PWM microstep control timer
	MOV32	R1, GPT2				;Load base address
	STREG   CFG_16x2, R1, CFG			;16 bit timer
	STREG   TAMR_PWM_IE, R1, TAMR		;Set PWM mode with interrupts enabled
	STREG   TIMER16_1ms, R1, TAILR		;Set timer duration to 20 ms
	STREG   TIMER16_27us, R1, TAMATCHR	;Set timer match duration to 1.5 ms
	STREG   IMR_TA_CAPEV, R1, IMR		;Enable capture mode event interrupt

	;GPT3 will be our motor channel B PWM microstep control timer
	MOV32	R1, GPT3				;Load base address
	STREG   CFG_16x2, R1, CFG			;16 bit timer
	STREG   TAMR_PWM_IE, R1, TAMR		;Set PWM mode with interrupts enabled
	STREG   TIMER16_1ms, R1, TAILR		;Set timer duration to 40 us
	STREG   TIMER16_27us, R1, TAMATCHR	;Set timer match duration to 1.5 ms
	STREG   IMR_TA_CAPEV, R1, IMR		;Enable capture mode event interrupt

	MOV32	R1, SCS					;Load base address
	STREG   EN_INT_T1A, R1, NVIC_ISER0	;Interrupt enable
	STREG   EN_INT_T2A, R1, NVIC_ISER0	;Interrupt enable
	STREG   EN_INT_T3A, R1, NVIC_ISER0	;Interrupt enable


	BX	LR								;Return

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

;InstallGPTHandlers
;
; Description:       Install the event handler for the GPT timer interrupts.
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
InstallGPTHandlers:
    MOV32   R1, SCS       			;get address of SCS registers
    LDR     R1, [R1, #VTOR]     	;get table relocation address

    MOVA    R0, GPT1EventHandler    ;get handler address
    STR     R0, [R1, #(4 * GPT1A_EX_NUM)]   ;store vector addresses
    MOVA    R0, GPT2EventHandler    ;get handler address
    STR     R0, [R1, #(4 * GPT2A_EX_NUM)]   ;store vector addresses
    MOVA    R0, GPT3EventHandler    ;get handler address
    STR     R0, [R1, #(4 * GPT3A_EX_NUM)]   ;store vector addresses

    BX      LR						;all done, return


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
