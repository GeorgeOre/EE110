;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                              ;
;                       	Initialization Functions	       		           ;
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
    .include "prototype.inc"  	  ; contains constants specific to this project
    .include "configPWR&CLK.inc"  ; contains power config constants
    .include "configGPIO.inc"     ; contains GPIO config constants
    .include "GPIO.inc"           ; contains GPIO control constants
    .include "GPT.inc"            ; contains GPT control constants
    .include "Keypad.inc"         ; contains keypad interface constants
    .include "LCD.inc"            ; contains LCD interface constants
    .include "general.inc"        ; contains misc general constants
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           Required Macro Files
    .include "macros.inc"       ; contains all macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           Required Variables
 ;   .global VecTable        	;	Holds the address of the custom vector table
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           Required Functions
    .ref    GPT1EventHandler    ;   Periodic 1 ms keypad debouncer
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                               Table of Contents
;       Function Name   		|   Purpose
    .def    InitPower    		;   Initialize power
    .def    InitClocks   		;   Initialize clocks
    .def    InitGPIO     		;   Initialize GPIO configurations
    .def    InitGPTs     		;   Initialize GPTs configurations
    .def	InitVariables		;	Initalize variables
    .def	InitRegisters		;	Initalize vectors
;    .def	MoveVecTable		;	Initalize custom vector table
 ;   .def	InstallGPT1Handler	;	Install PWM handler

	.def	InitGPT0			;	Glen code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Revision History:   02/04/24 George Ore   Created format
;                     05/30/24 George Ore   Ported to EE110a HW3
;                     06/23/24 George Ore   Refactored and turned in
;                     06/29/24 George Ore   Ported to EE110b HW5
;                     07/06/24 George Ore   Attempted compiling Glen example
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

WaitCLKPON:						;Wait for clock settings to be set
	MOV32 	R0, CLOCKS_LOADED	;Load success condition

	MOV32	R2, PRCM			;Read CLKLOADCTL to check if settings
	LDR		R1, [R2,#CLKLOADCTL];have loaded successfully

	SUB   	R0, R1 				;Compare test condition with CLKLOADCTL
	CMP 	R0, #0
	BNE		WaitCLKPON			;Keep looping if still loading
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
    ; Write to IOCFG0-3 to be row testing outputs
    MOV32   R1, IOC                    ; Load base address
    STREG   IO_OUT_CTRL, R1, IOCFG0    ; Set GPIO pin 0 as an output
    STREG   IO_OUT_CTRL, R1, IOCFG1    ; Set GPIO pin 1 as an output
    STREG   IO_OUT_CTRL, R1, IOCFG2    ; Set GPIO pin 2 as an output
    STREG   IO_OUT_CTRL, R1, IOCFG3    ; Set GPIO pin 3 as an output

    ; Write to IOCFG4-7 to be column testing inputs
    STREG   IO_IN_CTRL, R1, IOCFG4     ; Set GPIO pin 4 as an input
    STREG   IO_IN_CTRL, R1, IOCFG5     ; Set GPIO pin 5 as an input
    STREG   IO_IN_CTRL, R1, IOCFG6     ; Set GPIO pin 6 as an input
    STREG   IO_IN_CTRL, R1, IOCFG7     ; Set GPIO pin 7 as an input


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

    ; Write to DOE31_0 to enable keypad and LCD relevant pins as outputs
;	MOV32	R0, OUTPUT_ENABLE_KEYPAD_OUTPUTS	; Load keypad pins
;	MOV32	R1, OUTPUT_ENABLE_LCD				; Load LCD pins
;	AND		R0, R1				; Combine them

	MOV32	R0, OUTPUT_ENABLE_KEYPAD_LCD
	MOV32	R1, GPIO			; Load base address
	STR   	R0, [R1, #DOE31_0]	; Set output enable on loaded pins

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
	;GPT0 will be our 1ms one shot timer
	MOV32	R1, GPT0					;Load base address
	STREG   CFG_32x1, R1, CFG			;32 bit timer
	STREG   TAMR_D_ONE_SHOT, R1, TAMR	;Enable one-shot mode countdown mode
	STREG   TIMER32_1ms, R1, TAILR		;Set timer duration to 1ms
	STREG   IMR_TA_TO, R1, IMR			;Enable timeout interrupt

	;GPT1 will be our 1us one shot timer (for write operation timing)
	MOV32	R1, GPT1					;Load base address
    STREG   CFG_32x1, R1, CFG           ; 32 bit timer
    STREG   TAMR_D_ONE_SHOT, R1, TAMR   ; Enable timer one-shot countdown mode
    STREG   TIMER32_1us, R1, TAILR      ; Set timer duration to 1us
    STREG   IMR_TA_TO, R1, IMR          ; Enable timeout interrupt

    ; GPT2 will be our 1ms periodic timer
    MOV32   R1, GPT2                    ; Load base address
    STREG   CFG_32x1, R1, CFG           ; 32 bit timer
    STREG   TAMR_D_PERIODIC, R1, TAMR   ; Enable timer periodic countdown mode
    STREG   TIMER32_1ms, R1, TAILR      ; Set timer duration to 1ms
    STREG   IMR_TA_TO, R1, IMR          ; Enable timeout interrupt
    STREG   CTL_TA_STALL, R1, CTL       ; Enable timer with debug stall

	MOV32	R1, SCS						;Load base address
	STREG   EN_INT_T2A, R1, NVIC_ISER0	;Interrupt enable

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

;FIRST INIT ALL KEYPAD VARS
    .global prev0
    .global prev1
    .global prev2
    .global prev3

    .global dbnceCntr0
    .global dbnceCntr1
    .global dbnceCntr2
    .global dbnceCntr3

    .global buffer
    .global bIndex
    .global dbnceFlag
    .global keyValue

    MOV32   R0, NOT_PRESSED ;load the not-pressed value

    ; set previous values of all rows to start with the not-pressed value
    MOVA    R1, prev0
    STR     R0, [R1]
    MOVA    R1, prev1
    STR     R0, [R1]
    MOVA    R1, prev2
    STR     R0, [R1]
    MOVA    R1, prev3
    STR     R0, [R1]

    MOV32   R0, DBNCE_CNTR_RESET    ;load the counter reset value

    ; reset values of all row debounce counters
    MOVA    R1, dbnceCntr0  ;reset row0 debounce counter
    STR     R0, [R1]
    MOVA    R1, dbnceCntr1  ;reset row0 debounce counter
    STR     R0, [R1]
    MOVA    R1, dbnceCntr2  ;reset row0 debounce counter
    STR     R0, [R1]
    MOVA    R1, dbnceCntr3  ;reset row0 debounce counter
    STR     R0, [R1]

    MOV32   R0, NOT_PRESSED ;load the not-pressed value
    MOVA    R1, keyValue    ;set the initial key value to not-pressed
    STR     R0, [R1]

    MOVA    R1, dbnceFlag   ;set debounce flag to start in the reset state
    MOV32   R0, DBNCE_FLAG_RESET
    STR     R0, [R1]

    MOVA    R1, bIndex  ;set starting buffer index to 0
    MOV32   R0, ZERO_START
    STR     R0, [R1]

;NEXT INIT ALL LCD VARS
	.global cRow
	.global cCol

    MOVA    R1, cRow               ; set starting cursor row index to 0
    MOV32   R0, ZERO_START
    STR     R0, [R1]

    MOVA    R1, cCol               ; set starting cursor column index to 0
    MOV32   R0, ZERO_START
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
    STREG   R0_TEST, R1, DOUT31_0   ;Start testing row 0

	BX	LR

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
;MoveVecTable:
 ;       PUSH    {R4}                    ;store necessary changed registers
        ;B      MoveVecTableInit        ;start doing the copy

;MoveVecTableInit:                       ;setup to move the vector table
 ;       MOV32   R1, SCS       			;get base for CPU SCS registers
  ;      LDR     R0, [R1, #VTOR]     	;get current vector table address

   ;     MOVA    R2, VecTable            ;load address of new location
    ;    MOV     R3, #VEC_TABLE_SIZE     ;get the number of words to copy
        ;B      MoveVecCopyLoop         ;now loop copying the table

;MoveVecCopyLoop:                        ;loop copying the vector table
 ;       LDR     R4, [R0], #BYTES_PER_WORD   ;get value from original table
  ;      STR     R4, [R2], #BYTES_PER_WORD   ;copy it to new table

   ;     SUBS    R3, #1                  ;update copy count

    ;    BNE     MoveVecCopyLoop         ;if not done, keep copying
        ;B      MoveVecCopyDone         ;otherwise done copying

;MoveVecCopyDone:                        ;done copying data, change VTOR
 ;       MOVA    R2, VecTable            ;load address of new vector table
  ;      STR     R2, [R1, #VTOR]     	;and store it in VTOR
        ;B      MoveVecTableDone        ;and all done

;MoveVecTableDone:                       ;done moving the vector table
 ;       POP     {R4}                    ;restore registers and return
  ;      BX      LR						;return

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
;InstallGPT1Handler:
 ;   MOVA    R0, GPT1EventHandler    ;get handler address
  ;  MOV32   R1, SCS       			;get address of SCS registers
   ; LDR     R1, [R1, #VTOR]     	;get table relocation address
    ;STR     R0, [R1, #(4 * GPT1A_EX_NUM)]   ;store vector address

;    BX      LR						;all done, return


; InitGPT0
;
; Description:       This function initializes GPT0.  It sets up the timer to
;                    generate interrupts every MS_PER_BLINK milliseconds.
;
; Operation:         The appropriate values are written to the timer control
;                    registers, including enabling interrupts.
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
; Revision History:  02/17/21   Glen George      initial revision

InitGPT0:
        .def    InitGPT0


GPT0AConfig:            ;configure timer 0A as a down counter generating
                        ;   interrupts every MS_PER_BLINK milliseconds

        MOV32   R1, GPT0              ;get GPT0 base address
        STREG   CFG_32x1, R1, CFG   ;setup as a 32-bit timer
        STREG   GPT_CTL_EN_TA_PWM_STALL, R1, CTL   ;enable timer A
        STREG   IMR_TA_TO, R1, IMR   ;enable timer A timeout ints
        STREG   TAMR_D_PERIODIC, R1, TAMR    ;set timer A mode
                                                ;set 32-bit timer count
;        STREG   TIMER32_1ms, R1, TAILR
        STREG   (MS_PER_BLINK * CLK_PER_MS), R1, TAILR
;        STREG   (1000 * 48000), R1, GPT_TAILR_OFF


        BX      LR                              ;done so return


; InitGPIO
;
; Description:       Initialize the I/O pins for the LEDs.
;
; Operation:         Setup GPIO pins 6 and 7 to be 4 mA outputs for the LEDs.
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
; Revision History:  02/17/21   Glen George      initial revision

;InitGPIO:
 ;       .def    InitGPIO

                                        ;configure red and green LED outputs
  ;      MOV32   R1, IOC_BASE_ADDR       ;get base for I/O control registers
   ;     MOV32   R0, IOCFG_GEN_DOUT_4MA  ;setup for general 4 mA outputs
    ;    STR     R0, [R1, #IOCFG6]   ;write configuration for red LED I/O
     ;   STR     R0, [R1, #IOCFG7]   ;write configuration for green LED I/O

                                        ;enable outputs for LEDs
      ;  MOV32   R1, GPIO_BASE_ADDR      ;get base for GPIO registers
       ; STREG   ((1 << REDLED_IO_BIT) | (1 << GREENLED_IO_BIT)), R1, GPIO_DOE31_0_OFF


        ;BX      LR                      ;done so return




; InitGPT0
;
; Description:       This function initializes GPT0.  It sets up the timer to
;                    generate interrupts every MS_PER_BLINK milliseconds.
;
; Operation:         The appropriate values are written to the timer control
;                    registers, including enabling interrupts.
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
; Revision History:  02/17/21   Glen George      initial revision

;InitGPT0:
 ;       .def    InitGPT0


;GPT0AConfig:            ;configure timer 0A as a down counter generating
                        ;   interrupts every MS_PER_BLINK milliseconds

      ;  MOV32   R1, GPT0_BASE_ADDR              ;get GPT0 base address
     ;   STREG   GPT_CFG_32x1, R1, GPT_CFG_OFF   ;setup as a 32-bit timer
    ;    STREG   GPT_CTL_TAEN, R1, GPT_CTL_OFF   ;enable timer A
   ;     STREG   GPT_IRQ_TATO, R1, GPT_IMR_OFF   ;enable timer A timeout ints
  ;      STREG   GPT0A_MODE, R1, GPT_TAMR_OFF    ;set timer A mode
                                                ;set 32-bit timer count
 ;       STREG   (MS_PER_BLINK * CLK_PER_MS), R1, GPT_TAILR_OFF


;        BX      LR                              ;done so return



.end
