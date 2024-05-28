;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																			   ;
;							EE110 HW2 George Ore							   ;
;																			   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
; Description:      This program configures the CC2652R LaunchPad to connect to
;					a 4x4 keypad on the Glen George TM wire wrap board.
;					When a button is pressed, the program registers the input's
;					keyID inside a data memory buffer.
;
; Operation:        The program constantly checks a debounce flag for
;					"permission" in the form of a set flag to store the
;					identifier of the corresponding debounced button in a data
;					memory buffer.
;
; Arguments:        NA
;
; Return Values:    NA
;
; Local Variables:  eventID (passed into EnqueueEvent to be placed in the buffer)
;
; Shared Variables: bOffset, dbnceCntr, dbnceFlag, keyValue, prev0-3
;
; Global Variables: ResetISR (required)
;
; Input:            Keypad columns (DIN31_0 register bits 3-7)
;
; Output:           Keypad rows (DOUT31_0 register bits 0-3)
;
; Error Handling:   NA
;
; Registers Changed: flags, R0, R1, R2,
;
; Stack Depth:       0 words
;
; Algorithms:        NA
;
; Data Structures:   NA
;
; Known Bugs:        NA
;
; Limitations:       Does not support multiple simultaneous keypresses
;
; Revision History:   11/06/23  George Ore      initial version
;                     11/07/23  George Ore      finished inital version
;					  12/04/23	George Ore		fixed bugs, start testing
;					  12/05/23	George Ore		finished
;
; Pseudo Code
;
;	includeconstants()
;	includemacros()
;	global ResetISR
;
;	initstack()
;   initpower()
;   initclocks()
;	movevectortable()
;	installGPT0handler()
;	initGPT0()
;   initGPIO()
;
;	keyValue = NOT_PRESSED
;	prev0, prev1, prev2, prev3 = NOT_PRESSED
;	dbnceFlag = DBNCE_FLAG_RESET
;	dbnceCntr = DBNCE_CNTR_RESET
;	bIndex = ZERO_START
;
;	DOUT31-0 = ALL_OFF
;
;	while(1)
;	if dbnceFlag == DBNCE_FLAG_SET:
;		eventID = KeypadID & keyValue
;		EnqueueEvent(eventID)
;		dbnceFlag = DBNCE_FLAG_RESET
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Include constant, and macro files
	.include "configPWR&CLK.inc"	;contains power config constants
	.include "configGPIO.inc"	;contains GPIO config constants
	.include "GPIO.inc"			;contains GPIO control constants
	.include "GPT.inc"			;contains GPT control constants
	.include "constants.inc"	;contains misc. constants

	.include "macros.inc"		;contains all macros

	.text				;program start
	.global ResetISR	;requred global var

ResetISR:				;System required label

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																			   ;
;							Actual Program Code								   ;
;																			   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;Initialize Stack;;;;;;
InitStack:
    MOVA    R0, TopOfStack
    MSR     MSP, R0
    SUB     R0, R0, #HANDLER_STACK_SIZE
    MSR     PSP, R0

;;;;;;Initialize Power;;;;;;
	BL	InitPower

;;;;;;Initialize Clocks;;;;;;
	BL	InitClocks

;;;;;;Initialize Vector Table;;;;;;
	BL	MoveVecTable

;;;;;;Install GPT0 Handler;;;;;;
	BL	InstallGPT0Handler

;;;;;;Initalize GPT0;;;;;;
	BL	InitGPT0

;;;;;;Initalize GPIO;;;;;;
	BL	InitGPIO

;;;;;;Init Variable Values;;;;;;
InitVariables:
	MOV32   R0, NOT_PRESSED	;load the not-pressed value

	;set previous values of all rows to start with the not-pressed value
	MOVA    R1, prev0
	STR     R0, [R1]
	MOVA    R1, prev1
	STR     R0, [R1]
	MOVA    R1, prev2
	STR     R0, [R1]
	MOVA    R1, prev3
	STR     R0, [R1]

	MOV32   R0, DBNCE_CNTR_RESET	;load the counter reset value

	;reset values of all row debounce counters
	MOVA    R1, dbnceCntr0	;reset row0 debounce counter
	STR     R0, [R1]
	MOVA    R1, dbnceCntr1	;reset row0 debounce counter
	STR     R0, [R1]
	MOVA    R1, dbnceCntr2	;reset row0 debounce counter
	STR     R0, [R1]
	MOVA    R1, dbnceCntr3	;reset row0 debounce counter
	STR     R0, [R1]

	MOV32   R0, NOT_PRESSED	;load the not-pressed value
	MOVA    R1, keyValue	;set the inital key value to not-pressed
	STR     R0, [R1]

	MOVA    R1, dbnceFlag	;set debounce flag to start in the reset state
	MOV32   R0, DBNCE_FLAG_RESET
	STR     R0, [R1]

	MOVA    R1, bIndex	;set starting buffer index to 0
	MOV32   R0, ZERO_START
	STR     R0, [R1]

;;;;;;Init Register Values;;;;;;
InitRegisters:
	MOV32	R1, GPIO				;Load base address

;	STREG   ALL_PINS, R1, DCLR31_0	;Clear all GPIO pins
	STREG   R0_TEST, R1, DOUT31_0	;Start testing row 0

;;;;;;Main Program;;;;;;
MainLoop:	;Loop goes on forever
	MOVA 	R1, dbnceFlag	;Load dbnceFlag address into R1

	CPSID	I	;Disable interrupts to avoid critical code
	LDR 	R0, [R1]	;Load dbnceFlag data onto R0

	MOV32 	R1, DBNCE_FLAG_SET	;Load R1 with the event pressed condition
	CMP   	R0, R1
	BNE SkipEvent		;If dbnceFlag != SET, skip EnqueueEvent
	BL	EnqueueEvent	;If debounce flag == set, enqueue event

SkipEvent: ;This label is only used in the != case
	CPSIE	I	;Enable interrupts again

	B	MainLoop		;Repeat forever

;********************************************************
;USED FUNCTIONS
;********************************************************

; EnqueueEvent:
;
; Description:	This procedure places an inputed eventID into the keybuffer
;
; Operation:    Fetches dbnceFlag state and if set, it fetches the key value
;		and converts it into an EventID before passign it to EnqueueEvent
;
; Arguments:         R0 - eventID
; Return Values:     None, instead writes to buffer
;
; Local Variables:   None.
; Shared Variables:  buffer, bIndex
; Global Variables:  None.
;
; Input:             None
; Output:            None
;
; Error Handling:    None.
;
; Registers Changed: R0, R1, R2, R3
; Stack Depth:       1 word
;
; Algorithms:        None.
; Data Structures:   None.
;
; Revision History:  12/4/23	George Ore	 added documentation
;
; Pseudo Code
;
;	buffer(bIndex) = keyValue
;	bIndex++
;	return
EnqueueEvent:
	PUSH    {R0, R1, R2, R3}	;Push registers

;To avoid critical code, preload addresses
	MOVA 	R1, keyValue
	MOVA 	R2, bIndex
	MOVA	R3, buffer	;Fetch buffer address on R3

	CPSID	I			;Disable interrupts to avoid critical code

	LDR 	R0, [R1]	;Load R0 with the key value
	LDR 	R1, [R2]	;Load R1 with the buffer index value

	ADD		R1, #ONE	;Increment the buffer index value
	STR		R1, [R2]	;Save the buffer index

	SUB		R1, #ONE	;Restore the buffer index value

;Use buffer index value as a counter for calculating the
;desired buffer address
	MOV32	R2, COUNT_DONE	;Load calc-finished condition

BAddressLoop:
	CMP		R1, R2		;Test index counter
	BEQ		Enqueue		;Start enqueue if done
;If not...
	ADD		R3, #1		;Add [] for every value of index
	SUB		R1, #ONE	;Decrement index counter

	B		BAddressLoop	;Keep looping until done

Enqueue:
	STR		R0, [R3]	;Put keyValue in the calculated buffer address

	MOVA	R0, dbnceFlag		;Reset status of dbnceFlag
	MOV32	R1, DBNCE_FLAG_RESET
	STR		R1, [R0]

	CPSIE	I	;Enable interrupts again

	POP    {R0, R1, R2, R3}	;Pop registers
	BX		LR	;Return


; GPT0EventHandler:
;
; Description:	  This procedure is called through the GPIO vector table
;		  interupt. It debounces keypresses and updates the dbnceFlag
;		  and keyValue variables.
;
; Operation:	  Updates output row. Then tests if input indicates nothing is
;		  pressed and returns if so. Tests if debounce counter is
; Arguments:        None.
; Return Values:    None.
;
; Local Variables:  R0: temp
;					R1: input
;					R2: output
;					R3: prevAddress
;					R4: cntrAddress
;					R5: temp2
;					R6: temp3
; Shared Variables: bOffset, dbnceCntr, dbnceFlag, keyValue, prev0-prev3
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   Does not set dbnceFlag again until previous event has been
;					handled.
;
; Registers Changed: R0, R1, R2, R3, R4, R5, R6
; Stack Depth:      1-2 words
;
; Algorithms:       None.
; Data Structures:  None.
;
; Revision History:  12/4/23	George Ore	 added documentation and fixed bugs
;
; Pseudo Code
;
;	fetch input state
;	mask the 32bit value to only get the 4 relevant values
;
;	Get current output state (keep in a reg for later)
;	Test to see which row it is
;	if(row0):
;		keep prev0 address in a register for later
;		update to start outputting row 1
;	else if(row1):
;		keep prev1 address in a register for later
;		update to start outputting row 2
;	else if(row2):
;		keep prev2 address in a register for later
;		update to start outputting row 3
;	else(row3):
;		keep prev3 address in a register for later
;		update to start outputting row 0
;
;	if input == NOTHINGPRESSED
;		reset debouncecounter
;		end debounce test
;	else (something is pressed)
;		if debounceCounter = 0
;			if dbnceFlag == reset
;				reset debouncecounter
;				end debounce test
;			else (dbnceFlag is still set)
;				end debounce test
;		else (debounce counter has nonzero value)
;			if inputstate == previnputstate
;				dec debounce counter
;				if debounce counter finished (0)
;					keyvalue = outputstate+inputstate
;					dbnceFlag = SET
;					(dont reset dbncecntr)
;					return
;				else (debounce counter still nonzero)
;					return
;			else (inputstate != previnputstate)
;				reset dbcounter
;				store inputstate in prevstate
;				return
GPT0EventHandler:
	PUSH    {R4, R5, R6}		;save the registers (R0-R3 are autosaved)

GetCurrentRowInput:
	MOV32 	R5, GPIO			;Load base address into R5

	LDR 	R1, [R5, #DIN31_0]	;Load current input state in R1
	MOV32	R0, INPUT_MASK
	AND		R1, R0				;Mask to only receive relevant input bits

GetCurrentRowOutput:
	LDR 	R2, [R5, #DOUT31_0]	;Load state of outputs in R2
	MOV32	R0, OUTPUT_MASK
	AND		R2, R0				;Mask to only receive output bits

R0Test:
	MOV32	R0, R0_TEST		;See if the output is row 0
	CMP		R2, R0
	BNE		R1Test			;if not, test row 1

R0Update:
	MOVA	R3, prev0		;if it is, save the address of prev0 in R3 for later
	MOVA	R4, dbnceCntr0	;save the address of dbnceCntr0 in R4 for later
	STREG   R1_TEST, R5, DOUT31_0	;and update output to test row 1
	B		DebounceTest	;start debounce test

R1Test:
	MOV32	R0, R1_TEST		;See if it is row 1
	CMP		R2, R0
	BNE		R2Test			;if not, test row 2

R1Update:
	MOVA	R3, prev1		;if it is, save the address of prev1 in R3 for later
	MOVA	R4, dbnceCntr1	;save the address of dbnceCntr1 in R4 for later
	STREG   R2_TEST, R5, DOUT31_0	;and update output to test row 2
	B		DebounceTest	;start debounce test

R2Test:
	MOV32	R0, R2_TEST		;See if it is row 2
	CMP		R2, R0			;if not, it means row three is being tested
	BNE		R3Update		;branch to handle a row 3 update

R2Update:
	MOVA	R3, prev2		;if it is, save the address of prev2 in R3 for later
	MOVA	R4, dbnceCntr2	;save the address of dbnceCntr2 in R4 for later
	STREG   R3_TEST, R5, DOUT31_0	;and update output to test row 3
	B		DebounceTest	;start debounce test


R3Update:
	MOVA	R3, prev3		;if it is, save the address of prev3 in R3 for later
	MOVA	R4, dbnceCntr3	;save the address of dbnceCntr3 in R4 for later
	STREG   R0_TEST, R5, DOUT31_0	;update to test row 0
	;B		DebounceTest	;start debounce test

DebounceTest:
;The debounce test section has many conditions to test. Here is a quick
;conditional map:
;	if input == NOTHINGPRESSED
;		reset debouncecounter
;		end debounce test
;	else (something is pressed)
;		if debounceCounter = 0
;			if dbnceFlag == reset
;				reset debouncecounter
;				end debounce test
;			else (dbnceFlag is still set)
;				end debounce test
;		else (debounce counter has nonzero value)
;			if inputstate == previnputstate
;				dec debounce counter
;				if debounce counter finished (dbncecntr == 0)
;					keyvalue = outputstate+inputstate
;					dbnceFlag = SET
;					(dont reset dbncecntr)
;					end debounce test
;				else (debounce counter still nonzero)
;					end debounce test
;			else (inputstate != previnputstate)
;				reset dbcounter
;				store inputstate in prevstate
;				end debounce test

TestUnpressed:
	;Reminder that R1 contains the masked input state
	MOV32	R0, NOT_PRESSED	;Test if the input pattern is not pressed
	CMP		R1, R0

	BNE		DbnceCntrTest	;If something is pressed, start the dbnceCntr test
	;BEQ	ResetDbnceCntr	;But if no buttons are pressed, reset dbnce counter

ResetDbnceCntr:
	;Reminder that R4 contains the relevant debounce counter address
	MOV32   R0, DBNCE_CNTR_RESET	;Reset relevant debounce counter
	STR     R0, [R4]

	B		EndDbnceTest	;End debounce test

;The following code excecutes only if there is pressed input
DbnceCntrTest:
	;Reminder that R4 contains the relevant debounce counter address
	LDR 	R5, [R4]		;Load relevant debounce counter value
	MOV32	R0, COUNT_DONE	;Load counter-finished test condition
	CMP		R5, R0
	BNE		PrevTest	;If the count is not done, test input with prev state
	;BEQ	FlagTest	;if the count is done, test dbnceFlag

FlagTest:
	MOVA	R5, dbnceFlag	;Load debounce flag value onto R6
	LDR 	R6, [R5]
	MOV32	R0, DBNCE_FLAG_SET	;Load flag set test condition
	CMP		R6, R0
	BNE		ResetDbnceCntr	;If the flag is not set, reset the dbnceCntr
	B		EndDbnceTest	;If the flag is set, end debounce test
							;This allows events to be set only if the
							;previous event has been handled

;The following code excecutes only when dbnceCntr tested a >0 value
PrevTest:
	;Reminder that R1 contains the masked input state and that R3 contains the
	;relevant prev variable address
	LDR 	R0, [R3]		;Load relevant prev state value

	CMP		R1, R0			;Compare the input and the prev input values
	BEQ		DecCounterTest	;If equal, start the decremented counter test
	;BNE	ResetDbnceCntr	;If different, update prev state

UpdatePrev:
	;Reminder that R1 contains the masked input state & that R3 contains the
	;relevant prev variable address
	STR		R1, [R3]		;Update relevant prev variable
	B		ResetDbnceCntr	;Reset debounce counter

;The following code excecutes only when input == previnput
DecCounterTest:
	;Reminder that the address of the relevant dbnceCntr is in R4
	LDR		R5, [R4]	;Decrement and save the counter
	SUB		R5, #ONE
	STR		R5, [R4]

	MOV32	R0, COUNT_DONE	;Load counter-finished test condition
	CMP   	R5, R0			;Test decremented counter
	BNE		EndDbnceTest	;If the count is not done, end the debounce test
	;B		SetKeyVars		;if the count is done, set the key variables

;The following code excecutes only when dbnceCntr-1 == 0
SetKeyVars:
	;Reminder that R1 contains the masked input state and that R2 contains the
	;masked output state
	ADD		R1,R2			;Calculate keyValue ID (inputstate+outputstate)
	MOVA	R5, keyValue	;Save keyValue
	STR		R1, [R5]

	MOV32	R0, DBNCE_FLAG_SET	;Set dbnceFlag
	MOVA	R5, dbnceFlag
	STR		R0, [R5]

	;B		EndDbnceTest		;End debounce test

EndDbnceTest:
	MOV32 	R1, GPT0				;Load base into R1
	STREG   IRQ_TATO, R1, ICLR  	;clear timer A timeout interrupt
	POP     {R4, R5, R6}    ;restore registers
	BX      LR                      ;return from interrupt

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

;InstallGPT0Handler
;
; Description:       Install the event handler for the GPT0 timer interrupt.
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
InstallGPT0Handler:
    MOVA    R0, GPT0EventHandler    ;get handler address
    MOV32   R1, SCS       			;get address of SCS registers
    LDR     R1, [R1, #VTOR]     	;get table relocation address
    STR     R0, [R1, #(4 * GPT0A_EX_NUM)]   ;store vector address
    BX      LR						;all done, return

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
	STREG   GPT0_CLK_ON, R1, GPTCLKGR		;GPT clock power on
	;Write to CLKLOADCTL to turn on GPIO clock
	STREG   LOAD_CLOCKS, R1, CLKLOADCTL		;Load clock settings

WaitCLKPON:						;Wait for clock settings to be set
	MOV32 	R0, CLOCKS_LOADED	;Load success condition

	MOV32	R2, PRCM			;Read CLKLOADCTL to check if settings
	LDR		R1, [R2,#CLKLOADCTL];have loaded successfully

	SUB   	R0, R1 				;Compare test condition with CLKLOADCTL
	CMP 	R0, #0
	BNE	WaitCLKPON				;Keep looping if still loading

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
;	Write to IOCFG0-3 to be row testing outputs
;	Load base address
;	Set GPIO pin 0 as an output
;	Set GPIO pin 1 as an output
;	Set GPIO pin 2 as an output
;	Set GPIO pin 3 as an output
;
;	Write to IOCFG4-7 to be column testing inputs
;	Set GPIO pin 4 as an input with pullup resistor
;	Set GPIO pin 5 as an input with pullup resistor
;	Set GPIO pin 6 as an input with pullup resistor
;	Set GPIO pin 7 as an input with pullup resistor
;
;	Write to DOE31_0 to enable the LED outputs
;	Load base address
;	Enable pins 0-3 as outputs
;	BX		LR			;Return
InitGPIO:
	;Write to IOCFG0-3 to be row testing outputs
	MOV32	R1, IOC					;Load base address
	STREG   IO_OUT_CTRL, R1, IOCFG0	;Set GPIO pin 0 as an output
	STREG   IO_OUT_CTRL, R1, IOCFG1	;Set GPIO pin 1 as an output
	STREG   IO_OUT_CTRL, R1, IOCFG2	;Set GPIO pin 2 as an output
	STREG   IO_OUT_CTRL, R1, IOCFG3	;Set GPIO pin 3 as an output

	;Write to IOCFG4-7 to be column testing inputs
	STREG   IO_IN_CTRL, R1, IOCFG4		;Set GPIO pin 4 as an input
	STREG   IO_IN_CTRL, R1, IOCFG5		;Set GPIO pin 5 as an input
	STREG   IO_IN_CTRL, R1, IOCFG6		;Set GPIO pin 6 as an input
	STREG   IO_IN_CTRL, R1, IOCFG7		;Set GPIO pin 7 as an input

	;Write to DOE31_0 to enable the LED outputs
	MOV32	R1, GPIO					;Load base address
	STREG   OUTPUT_ENABLE_0_3, R1, DOE31_0	;Enable pins 0-3 as outputs
	BX		LR							;Return

; InitGPT0
;
; Description:	This function initalizes the GPT0 and its interrupts.
;
; Operation:    Writes to the GPT0 and SCS control registers.
;
;
; Arguments:         None
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             Constants defining GPT0 controls
; Output:            Writes to GPT0 control registers
;
; Error Handling:    None.
;
; Registers Changed: GPT0 and SCS control registers, R0, R1
; Stack Depth:       1 word
;
; Algorithms:        None.
; Data Structures:   None.
;
; Revision History:  12/4/23	George Ore	 added documentation
;
; Pseudo Code
;
;	Load base address
;	32 bit timer
;	Enable timer with debug stall
;	Enable timeout interrupt
;	Enable periodic mode
;	Set timer duration to 1ms
;	BX	LR			;Return
InitGPT0:
	MOV32	R1, GPT0				;Load base address
	STREG   CFG_32x1, R1, CFG		;32 bit timer
	STREG   CTL_TA_STALL, R1, CTL	;Enable timer with debug stall
	STREG   IMR_TA_TO, R1, IMR		;Enable timeout interrupt
	STREG   TAMR_PERIODIC, R1, TAMR	;Enable periodic mode
	STREG   TIMER16_1ms, R1, TAILR	;Set timer duration to 1ms

	MOV32	R1, SCS					;Load base address
	STREG   EN_INT_TA, R1, NVIC_ISER0		;Interrupt enable

	BX	LR							;Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; 							Data Section									   ;
;																			   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.data

;;;;;;Variable Declaration;;;;;;

;prev0-3 will store previous states of the IO inputs for each row
	.align 4
prev0:		.space 1	;will store previous value of row 0
	.align 4
prev1:		.space 1	;will store previous value of row 1
	.align 4
prev2:		.space 1	;will store previous value of row 2
	.align 4
prev3:		.space 1	;will store previous value of row 3

;dbnceCntr0-3 will function as debounce counter's for each row
	.align 4
dbnceCntr0:	.space 4	;dbnceCntr is a 32 bit one shot decrementer
	.align 4
dbnceCntr1:	.space 4	;dbnceCntr is a 32 bit one shot decrementer
	.align 4
dbnceCntr2:	.space 4	;dbnceCntr is a 32 bit one shot decrementer
	.align 4
dbnceCntr3:	.space 4	;dbnceCntr is a 32 bit one shot decrementer

	.align 4
keyValue:	.space 1	;keyValue will have codes unique to each button. the
						;high nibble represents the rows and the low nibble
						;represents the columns

	.align 4
dbnceFlag:	.space 1	;flag indicates if a button is successfully debounced

	.align 4
bIndex:		.space 1	;stores index of the next empty buffer address

;;;;;;Buffer Declaration;;;;;;

	.align 4			;buffer will store the 2 byte key identification numbers
buffer:		.space 160	;has enough space to store 160 key presses
						;(16keys*10times)

;;;;;;Stack Declaration;;;;;;
	.align  8			;the stack (must be double-word aligned)
TopOfStack:     .bes    TOTAL_STACK_SIZE

;;;;;;Vector Table Declaration;;;;;;
        .align  512		;the interrupt vector table in SRAM
VecTable:       .space  VEC_TABLE_SIZE * BYTES_PER_WORD

.end
