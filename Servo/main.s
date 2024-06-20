;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																			   ;
;							EE110 HW5 George Ore							   ;
;																			   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
; Description:      This program configures the CC2652R LaunchPad to control a
;					servo motor on the Glen George TM wire wrap board. It uses
;					table driven code to move the servo and display the active
;					angles on an LCD. When the table is finished, the servo
;					goes into release mode and allows the user to set the servo
;					position while continuously displaying the angle.
;
; Operation:        The program loops through the memory in a testing data table
;					to get the parameters of what angle to set, what
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
; Revision History:   12/06/23  George Ore      initial version
;                     12/07/23  George Ore      finished inital version
;					  12/08/23	George Ore		fixed bugs, start testing
;					  01/03/24	George Ore		tested & updated functions
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
;	initGPTs()
;   initGPIO()
;	initADC()
;
;	servoMode = SETMODE
;	angle = 0DEGREES
;
;	for (angle, iterations, msdelay) in TestServo:
;		SetServo(angle)
;		for i in range(iterations)
;			Wait_1ms(msdelay)
;
;	ReleaseServo()
;	while(1)
;		angle = getServo()
;		display(angle)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Include constant, and macro files
	.include "configPWR&CLK.inc"	;contains power config constants
	.include "configGPIO.inc"	;contains GPIO config constants
	.include "GPIO.inc"			;contains GPIO control constants
	.include "GPT.inc"			;contains GPT control constants
	.include "ADC.inc"			;contains ADC config and control constants
	.include "constants.inc"	;contains misc. constants

	.include "macros.inc"		;contains all macros

;Reference LCD handler functions
    .ref    Display          ;   Display a string to the LCD
    .ref    DisplayChar      ;   Display a char to the LCD
    .ref    Wait_1ms         ;   Wait 1 ms
    .ref    LowestLevelWrite ;   Handles an LCD write cycle
    .ref    LowestLevelRead  ;   Handles an LCD read cycle
    .ref    WaitLCDBusy      ;   Waits until the LCD is not busy
    .ref	Int2Ascii		 ; 	 Converts an integer to ascii

;Reference LCD functions
    .ref    Display     ;   Display a string to the LCD
    .ref    DisplayChar ;   Display a char to the LCD

;Reference LCD variables
    .global cRow
	.global cCol

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

;;;;;;Install GPT1 Handler;;;;;;
	BL	InstallGPT1Handler

;;;;;;Initalize GPIO;;;;;;
	BL	InitGPIO

;;;;;;Initalize GPTs;;;;;;
	BL	InitGPTs

;;;;;;Init Variable Values;;;;;;
InitVariables:
	MOVA    R1, angle		;Set starting angle at 0
	MOV32   R0, ZERO_START
	STR     R0, [R1]

	MOVA    R1, pwm_stat		;Set PWM status READY
	MOV32   R0, READY
	STR     R0, [R1]

;;;;;;Init Register Values;;;;;;
;InitRegisters:
	MOV32	R1, GPIO		;Load base address
	STREG   ALL_PINS, R1, DCLR31_0	;Clear all GPIO pins
	;STREG   PWM_PIN, R1, DSET31_0	;Set the PWM pin

;;;;;;Init PWM;;;;;;
	;GPT1 is our PWM timer
	MOV32	R1, GPT1					;Load base address
	STREG   GPT_CTL_EN_TA_PWM_STALL, R1, CTL ;Enable PWM timer A with debug stall

;;;;;;Init ADC;;;;;;
	BL	InitADC

;;;;;; Init LCD ;;;;;;
InitLCD:    ; The following is LCD function set/startup
    MOV32   R0, WAIT30             ; Wait 30 ms (15 ms min)
    BL      Wait_1ms
    BL      WaitLCDBusy
    MOV32   R0, FSET_2LINES_DFONT  ; Write function set command
    MOV32   R1, FSET_RS
    BL      LowestLevelWrite

    MOV32   R0, WAIT8              ; Wait 8 ms (4.1 ms min)
    BL      Wait_1ms

    MOV32   R0, FSET_2LINES_DFONT  ; Write function set command
    MOV32   R1, FSET_RS
    BL      LowestLevelWrite

    MOV32   R0, WAIT1              ; Wait 1 ms (100 us min)
    BL      Wait_1ms

    MOV32   R0, FSET_2LINES_DFONT  ; Write function set command
    MOV32   R1, FSET_RS
    BL      LowestLevelWrite

; From here we need to wait until the busy flag is reset before executing the next command
    BL      WaitLCDBusy
    MOV32   R0, FSET_2LINES_DFONT  ; Write function set command
    MOV32   R1, FSET_RS
    BL      LowestLevelWrite

    BL      WaitLCDBusy
    MOV32   R0, LCD_OFF            ; Write display off command
    MOV32   R1, LCD_OFF_RS
    BL      LowestLevelWrite

    BL      WaitLCDBusy
    MOV32   R0, CLR_LCD            ; Write clear display command
    MOV32   R1, CLR_LCD_RS
    BL      LowestLevelWrite

    BL      WaitLCDBusy
    MOV32   R0, FWD_INC            ; Write entry mode set command
    MOV32   R1, ENTRY_RS
    BL      LowestLevelWrite

    BL      WaitLCDBusy
    MOV32   R0, CUR_BLINK          ; Write display on command
    MOV32   R1, LCD_ON_RS
    BL      LowestLevelWrite

;;;;;;Main Program;;;;;;
Main:

TestServo: ;do the servo function tests
	ADR 	R4, TestServoTable ;start at the beginning of table

TestServoLoop:
	LDRB	R0, [R4], #1 	;get the SetServo argument from table
	BL 		SetServo		;call the function
	LDRB 	R5, [R4], #1 	;get iterations from the table

    ;BL 		DisplayServo 	;display GetServo results

TestGetServoLoop: 			;loop testing GetServo function
	BL 		GetServo 		;call GetServo

	PUSH {R0, R1}

	BL      WaitLCDBusy
    MOV32   R0, CLR_LCD            ; Write clear display command
    MOV32   R1, CLR_LCD_RS
    BL      LowestLevelWrite
	BL      WaitLCDBusy

	POP {R0, R1}

	BL 		DisplayServo 	;display GetServo results
	LDRH 	R0, [R4] 		;get the time delay from the table
	BL 		Wait_1ms 		;delay amount specified
	SUBS 	R5, #1 			;update loop counter
	BNE 	TestGetServoLoop	;loop specified number of times
	;BEQ 	CheckDoneTest 	;then check if tests done

CheckDoneTest: 				;check if tests done
	ADD		R4, #2			;get past delay entry in table
	ADR 	R5, EndTestServoTable	;check if at end of table
	CMP 	R4, R5
	BNE 	TestServoLoop	;not done with tests, keep looping
	;BEQ 	DoneTestServo 	;otherwise done testing the servo

DoneTestServo: ;done testing servo

	BL	ReleaseServo	;Put the servo in release mode

;	MOV32	R1, GPIO		;Load base address
;	STREG   PWM_PIN, R1, DCLR31_0	;Clear the PWM pin

ReleaseLoop:
	BL	GetServo		;Get servo angle

	PUSH {R0, R1}

	BL      WaitLCDBusy
    MOV32   R0, CLR_LCD            ; Write clear display command
    MOV32   R1, CLR_LCD_RS
    BL      LowestLevelWrite
	BL      WaitLCDBusy

	POP {R0, R1}

	BL	DisplayServo	;Display servo angle

	MOV32 R0, WAIT1000
	BL Wait_1ms

	B	ReleaseLoop		;Loop forever

;*******************************************************************************
;USED FUNCTIONS
;*******************************************************************************
; SetServo:
;
; Description:	The function is passed the position in degrees (pos) to which to
;				set the servo. The position (pos) is passed in R0 by value. It
;				is a signed integer between -90 and +90.
;
; Operation:    Fetches dbnceFlag state and if set, it fetches the key value
;		and converts it into an EventID before passign it to EnqueueEvent
;
; Arguments:         R0 - amount of ms to wait
; Return Values:     None, waits
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
; 		  			 1/3/24		George Ore	 added invalid input error correction
;
; Pseudo Code
;
;	if MININPUT > angle or MAXINPUT < angle
;		return
;
;	rate = CalculatePWMRate(angle)
;	SetPWM(rate)
;
;	return
SetServo:
	PUSH    {R0, R1, R2}	;Push registers

	SXTB	R0, R0	;Sign extend input to prep for validity tests

MaxInputTest:
	MOV32	R1, MAXINPUT
	CMP		R0, R1		;Compare angle with max input value
	BGT		ENDSetServo	;If larger than max, dont set servo and simply return
	;BLE	MinInputTest	;If not, test min

MinInputTest:
	MOV32	R1, MININPUT
	CMP		R0, R1		;Compare angle with min input value
	BLT		ENDSetServo	;If less than min, dont set servo and simply return
	;BGE	KeepSettingServo	;If not, keep setting the angle

;KeepSettingServo:
	CPSID	I	;Disable interrupts to avoid critical code

	MOVA	R1, angle	;Save new input angle in the angle variable
	STR		R0, [R1]

	PUSH	{LR}
	BL		CalculatePWMRate	;(ARGS: R0 = angle)
	POP		{LR}	;Return R0 and R1 with the duty cycle prescale value

	PUSH	{LR}
	BL		SetPWM			;(ARGS: R0 = TAMATCHR, R1 = TAPMR)
	POP		{LR}	;PWM should be updated/set

	CPSIE	I	;Enable interrupts again

ENDSetServo:
	POP    	{R0, R1, R2}	;Pop registers
	BX		LR			;Return


; ReleaseServo:
;
; Description:	The function allows the servo to be moved manually. Calling
;				SetServo() with a valid argument returns control of the servo
;				position to the software.
;
; Operation:    Fetches dbnceFlag state and if set, it fetches the key value
;		and converts it into an EventID before passign it to EnqueueEvent
;
; Arguments:         R0 - amount of ms to wait
; Return Values:     None, waits
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
;	servoMode = RELEASED
;	return
ReleaseServo:
	PUSH    {R0, R1}	;Push registers

	MOV32	R1, GPT1
	STREG   GPT_CTL_TA_PWM_STALL, R1, CTL	;Disable PWM timer
	;Alternateivly disable interrupts??

	MOV32	R1, GPIO
;	STREG	PWM_PIN, R1, DCLR31_0	;Clear the PWM pin
	STREG	PWM_PIN, R1, DSET31_0	;Clear the PWM pin

EndReleaseServo:
	POP    	{R0, R1}	;Pop registers
	BX		LR			;Return

; GetServo:
;
; Description:	The function returns the current position of the servo in
;				degrees. The position is returned in R0. The returned
;				position should be a signed integer typically between -90 and +90.
;
; Operation:    Fetches dbnceFlag state and if set, it fetches the key value
;		and converts it into an EventID before passign it to EnqueueEvent
;
; Arguments:         R0 - amount of ms to wait
; Return Values:     None, waits
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
;		SampleADC()
;		sample = FetchADCFIFO()
;		FlushADCFIFO()
;		pos = ErrorCorrection(sample)
;		return pos
GetServo:
	PUSH    {R0, R1, R2, R3, R4}	;Push registers

	PUSH	{LR}
	BL		SampleADC
	POP		{LR}

;	CPSID	I	;Disable interrupts to avoid critical code

	PUSH	{LR}
	BL		GetADCFIFO
	POP		{LR}

	PUSH	{LR}
	BL		ErrorCorrection
	POP		{LR}

	MOVA	R1, angle	;Save new angle in angle variable
	STR		R0, [R1]

;	CPSIE	I	;Enable interrupts again

	PUSH	{LR}
	BL		FlushADCFIFO
	POP		{LR}

EndGetServo:
	POP    	{R0, R1, R2, R3, R4}	;Pop registers
	BX		LR			;Return


; CalculatePWMRate:
;
; Description:	The function is passed the position in degrees (pos) to which to
;				set the servo. The position (pos) is passed in R0 by value. It
;				is a signed integer between -90 and +90.
;
; Operation:    Fetches dbnceFlag state and if set, it fetches the key value
;		and converts it into an EventID before passign it to EnqueueEvent
;
; Arguments:         R0 - amount of ms to wait
; Return Values:     None, waits
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
; Registers Changed: R0, R1
; Stack Depth:       1 word
;
; Algorithms:        None.
; Data Structures:   None.
;
; Revision History:  12/6/24	George Ore	 created
; 		  			 1/3/24		George Ore	 revised
;
; Pseudo Code
;
;	(ARGS: R0 = angle)
;
;	R0 = PWMTable(angle)
;
;	return R0 (timer match), R1 (match prescale)
CalculatePWMRate:
;	PUSH    {}	;No registers to push

	MOV32	R1, LNIBBLE	;Preprocess angle for 16 bit operation
	AND		R0, R1

	MOV32	R1, ANGLE_INPUT_OFFSET	;Add 90 to get rid of negative values
	SADD16	R0, R0, R1

	MOVA	R1,	PWMTable	;Load base addresses of tables

	LSL		R0, #PWM_SHIFT_OFFSET	;Adjust input to become address offset

	ADD		R1, R0		;Add offset to addresses

	LDRH	R0, [R1]	;Load R0 with the duty cycle match value
    LDR		R1, [R1]	;and R1 with the prescale match value
    LSR		R1, #PWM_PRESCALE_SHIFT

ENDCalculatePWMRate:
;	POP    	{}	;No registers to pop
	BX		LR			;Return

; SetPWM:
;
; Description:	The function is passed the timer control settings to change the PWM.
;				It writes to the timer registers to change PWM.
;
; Operation:    Fetches dbnceFlag state and if set, it fetches the key value
;		and converts it into an EventID before passign it to EnqueueEvent
;
; Arguments:         R0 - amount of ms to wait
; Return Values:     None, waits
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
; 		  			 1/3/24		George Ore	 revised
;
; Pseudo Code
;
;	(ARGS: R0 = TAMATCHR, R1 = TAPMR)
;	TAMATCHR  = R0
;	TAPMR	  = R1
;	return
SetPWM:
	PUSH    {R0, R1, R2, R3}	;Push registers

	MOV32	R2, GPT1		;Load base address


;	CPSID	I	;Disable interrupts to avoid critical code


	PUSH	{R0}
	STREG   GPT_CTL_TA_PWM_STALL, R2, CTL	;Disable timer
	POP		{R0}



	MOV32	R3, TAPMR
	STR   	R1, [R2, R3] 	;Set timer match preset

	MOV32	R3, TAMATCHR 	;Set timer match duration
	STR   	R0, [R2, R3]

	STREG   GPT_CTL_EN_TA_PWM_STALL, R2, CTL	;Enable timer

;	CPSIE	I	;Enable interrupts again


ENDSetPWM:
	POP    	{R0, R1, R2, R3}	;Pop registers
	BX		LR			;Return


; SampleADC:
;
; Description:	The function is passed the timer control settings to change the PWM.
;				It writes to the timer registers to change PWM.
;
; Operation:    Fetches dbnceFlag state and if set, it fetches the key value
;		and converts it into an EventID before passign it to EnqueueEvent
;
; Arguments:         R0 - amount of ms to wait
; Return Values:     None, waits
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
;	(ARGS: R0 = TAMATCHR, R1 = TAMPR)
;	TAMATCHR  = R0
;	TAMPR = R1
;
;	return
SampleADC:
	PUSH    {R0, R1}	;Push registers

	MOV32	R1, AUX_ANAIF	;Load analog interface base address

	STREG   TRIGGER_ADC, R1, ADCTRIG	;Trigger an ADC sample

ENDSampleADC:
	POP    	{R0, R1}	;Pop registers
	BX		LR			;Return


; GetADCFIFO:
;
; Description:	The function is passed the timer control settings to change the PWM.
;				It writes to the timer registers to change PWM.
;
; Operation:    Fetches dbnceFlag state and if set, it fetches the key value
;		and converts it into an EventID before passign it to EnqueueEvent
;
; Arguments:         R0 - amount of ms to wait
; Return Values:     None, waits
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
;	(ARGS: R0 = TAMATCHR, R1 = TAMPR)
;	pos = GetADCFIFO()
;
;	return
GetADCFIFO:
	PUSH    {R1, R2}	;Push registers

;	MOV32	R1, AUX_DDI0_OSC	;Load AUX domain clock control base address
	MOV32	R1, AUX_ANAIF	;Load analog interface base address

ADCProcessingLoop:
;	MOV32	R2, ADCDATAREADYMASK	;Get ADC processing status
	MOV32	R2, ADCISEMPTY	;Get ADC processing status
;	LDR     R0, [R1, #STAT0]		;First load general status register
	LDR     R0, [R1, #ADCFIFOSTAT]		;First load general status register
	ANDS	R0, R2					;Mask for only the relevant bit
	CMP		R0, R2
	BNE		ADCReady
	B		ADCProcessingLoop		;Keep looping until ADC is ready

;while you are at it STAT0 tells you if the RCOSC_HF is on which is your ADC source check it
ADCReady:
	MOV32	R1, AUX_ANAIF	;Load analog interface base address

	MOV32	R2, ADC_DATAMASK	;Get ADC data
	LDR     R0, [R1, #ADCFIFO]
	AND		R0, R2				;But only the relevant bits

ENDGetADCFIFO:
	POP    	{R1, R2}	;Pop registers
	BX		LR			;Return

; FlushADCFIFO:
;
; Description:	The function is passed the timer control settings to change the PWM.
;				It writes to the timer registers to change PWM.
;
; Operation:    Fetches dbnceFlag state and if set, it fetches the key value
;		and converts it into an EventID before passign it to EnqueueEvent
;
; Arguments:         R0 - amount of ms to wait
; Return Values:     None, waits
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
;	(ARGS: R0 = TAMATCHR, R1 = TAMPR)
;	TAMATCHR  = R0
;	TAMPR = R1
;
;	return
FlushADCFIFO:
	PUSH    {R0, R1}	;Push registers

	MOV32	R1, AUX_ANAIF	;Load analog interface base address

	STREG   FLUSHADC_MANUAL, R1, ADCCTL	;Flush ADC FIFO
	NOP		;Two (24MHz or 48MHz???)clocks are needed before enabling or
	NOP		;disabling the ADC control interface
	NOP
	NOP
;	Enable ADC control interface with manual trigger
	STREG   ENABLEADC_MANUAL, R1, ADCCTL

ENDFlushADCFIFO:
	POP    	{R0, R1}	;Pop registers
	BX		LR			;Return

; ErrorCorrection:
;
; Description:	The function is passed the timer control settings to change the PWM.
;				It writes to the timer registers to change PWM.
;
; Operation:    Fetches dbnceFlag state and if set, it fetches the key value
;		and converts it into an EventID before passign it to EnqueueEvent
;
; Arguments:         R0 - amount of ms to wait
; Return Values:     None, waits
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
; Revision History:  12/30/24	George Ore	 created
;
; Pseudo Code
;
;	(ARGS: R0 = sample data)
;	R0 = CorrectionTable(R0)
;	return R0
;
; or
;
;	Multiply scaling ratio
;	Add offset
;	return
ErrorCorrection:
	PUSH    {R1, R2, R3}	;Push registers

	ADR 	R2, SampleTable ;start at the beginning of table
	MOV32	R3, ZERO_START	;load a counter variable to count search offset

LookupTableLoop:
	LDR		R1, [R2], #NEXT_WORD 	;Get the next sample in sample table

TestSampleLoop: 			;Check if sample is less than the RAW ADC data in R0
	CMP 	R1, R0 			;Compare sample with table data
	BGE 	GetCorrectData	;When threshold is supassed, get the correct data
	ADD		R3, R3, #NEXT_WORD	;Add one byte of distance to the counter
	B 	LookupTableLoop 	;Keep traversing the sample table until the threshold is surpassed

GetCorrectData:
	ADR 	R2, ErrorCorrectionTable ;Start at the beginning of error correction table
	LDR		R0, [R2, R3]	;Load corrected angle

EndErrorCorrection:
	POP    	{R1, R2, R3}	;Pop registers
	BX		LR			;Return

; InitADC:
;
; Description:	The function is passed the timer control settings to change the PWM.
;				It writes to the timer registers to change PWM.
;
; Operation:    Fetches dbnceFlag state and if set, it fetches the key value
;		and converts it into an EventID before passign it to EnqueueEvent
;
; Arguments:         R0 - amount of ms to wait
; Return Values:     None, waits
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
;	(ARGS: R0 = TAMATCHR, R1 = TAMPR)
;	TAMATCHR  = R0
;	TAMPR = R1
;
;	return
InitADC:
	PUSH    {R0, R1, R2, R3}	;Push registers

	MOV32	R1, AUX_ADI4		;Load analog digital interface master base address

;	Do not allow VDDR or any other voltage source into the ADC channel
;	STREG   NO_VDDR, R1, MUX0	; DONT NEED
;	STREG   NO_SOURCES, R1, MUX2	;DONTNEED

;	Mux AUXIO20 (GPIO 29) into the ADC channel
	STREG   MUX_AUXIO20, R1, MUX3	;FIX THIS

;	Enable ADC module in synchronous mode with 2.7us sampling rate
	STREG   ENADC_SYNC_341us, R1, ADC0 ;341microseconds

;	Keep the 1408/4095 (.3438) scaling
;	STREG   ADC_PRESCALE, R1, ADC1	;DONT NEED

;	Enable ADC reference even in idle state
	STREG   ADC_REF_EN_4p3_IDLE, R1, ADCREF0	;YYOU NEED THIS


;	Keep nominal 1.43V scaled reference
;	STREG   NOMINAL_ADCREF, R1, ADCREF1	;Dont need

	MOV32	R1, AUX_ANAIF		;Load analog interface base address




	NOP		;Two (24MHz or 48MHz???)clocks are needed before enabling or
	NOP		;disabling the ADC control interface
	NOP
	NOP
;	Enable ADC control interface with manual trigger
	STREG   ENABLEADC_MANUAL, R1, ADCCTL

ENDInitADC:
	POP    	{R0, R1, R2, R3}	;Pop registers
	BX		LR			;Return

; DisplayServo:
;
; Description:	The function is passed the timer control settings to change the PWM.
;				It writes to the timer registers to change PWM.
;
; Operation:    Fetches dbnceFlag state and if set, it fetches the key value
;		and converts it into an EventID before passign it to EnqueueEvent
;
; Arguments:         R0 - amount of ms to wait
; Return Values:     None, waits
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
;	(ARGS: R0 = TAMATCHR, R1 = TAMPR)
;	TAMATCHR  = R0
;	TAMPR = R1
;
;	return
DisplayServo:
	PUSH    {R0, R1, R2, R3}	;Push registers

;    CPSID   I   ;Disable interrupts to avoid critical code

	MOVA	R1, angle	;Fetch angle address
	LDR	R0, [R1]	;Fetch the angle

; Prep the ascii buffer
	MOVA	R1, charbuffer
	PUSH    {LR}
	BL Int2Ascii	; Returns
	POP     {LR}

;    CPSIE   I   ;Enable interrupts again

; Display the value
	MOV32	R0, DISPLAY_LCD_ROW	; Set the default display position
	MOV32	R1, DISPLAY_LCD_COL
    MOVA    R2, charbuffer     	; Start at the beginning of word data table

	PUSH    {LR}
    BL      Display                 ; Call the function (should increment R2 address)
	POP     {LR}

ENDDisplayServo:
	POP    	{R0, R1, R2, R3}	;Pop registers
	BX		LR			;Return

; GPT1EventHandler:
;
; Description:	This procedure is called through the GPT1 vector table
;		  		interupt. It happens when the PWM signal changes state.
;
; Operation:	Toggles GPIO 30 output when PWM changes state.
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
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           GPIO 30 output state
;
; Error Handling:   Assumes that GPIO 30 is already in the correct state
;
; Registers Changed: R0, R1, R2, R3
; Stack Depth:      1 word
;
; Algorithms:       None.
; Data Structures:  None.
;
; Revision History:  12/29/23	George Ore	 created
;
; Pseudo Code
;
;	ToggleGPIO(30)
;	return
GPT1EventHandler:
;TODO: Double check that this is working good and if I should push and pop this or not
;	PUSH    {R0, R1, R2}	;R0-R3 are autosaved

	MOVA 	R0, pwm_stat	;Load staus address
	LDR		R1, [R0]	;Fetch status
	CBZ		R1, PWMUpdate	;Update if status is zero

	;If non zero, reset status to READY and end interrupt
	MOV32	R1, READY
	STR		R1, [R0]
	B EndGPT1EventHandler

PWMUpdate:
	MOV32	R1, SET		;Update PWM status
	STR		R1, [R0]

	MOV32	R1, GPIO	;Load base address
	STREG	PWM_PIN, R1, DTGL31_0	;Toggle the PWM pin

EndGPT1EventHandler:
	MOV32 	R1, GPT1				;Load base into R1
	STREG   GPT_IRQ_CAE, R1, ICLR  	;Clear timer A capture event interrupt

;	POP    {R0, R1, R2}			;R0-R3 are autorestored
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
;	Write to IOCFG0-3 to be row testing outputs
;	Load base address
;	Set GPIO pin 29 as an AUXIO input for ADC
;	Set GPIO pin 30 as an output
;
;	Write to DOE31_0 to enable the LED outputs
;	Load base address
;	Enable pins 0-3 as outputs
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
; Operation:    Writes to the GPT0 control registers.
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
; Registers Changed: GPT0, GPT1, and SCS control registers, R0, R1
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

;;;;;;Calculation Tables;;;;;;

	.align 4
PWMTable:
	.word		0x000CC7E0, 0x000CC9E8, 0x000CCBF0, 0x000CCDF8, 0x000CD000
	.word		0x000CD208, 0x000CD410, 0x000CD618, 0x000CD820, 0x000CDA28
	.word		0x000CDC30, 0x000CDE38, 0x000CE040, 0x000CE248, 0x000CE450
	.word		0x000CE658, 0x000CE860, 0x000CEA68, 0x000CEC70, 0x000CEE78
	.word		0x000CF080, 0x000CF288, 0x000CF490, 0x000CF698, 0x000CF8A0
	.word		0x000CFAA8, 0x000CFCB0, 0x000CFEB8, 0x000D00C0, 0x000D02C8
	.word		0x000D04D0, 0x000D06D8, 0x000D08E0, 0x000D0AE8, 0x000D0CF0
	.word		0x000D0EF8, 0x000D1100, 0x000D1308, 0x000D1510, 0x000D1718
	.word		0x000D1920, 0x000D1B28, 0x000D1D30, 0x000D1F38, 0x000D2140
	.word		0x000D2348, 0x000D2550, 0x000D2758, 0x000D2960, 0x000D2B68
	.word		0x000D2D70, 0x000D2F78, 0x000D3180, 0x000D3388, 0x000D3590
	.word		0x000D3798, 0x000D39A0, 0x000D3BA8, 0x000D3DB0, 0x000D3FB8
	.word		0x000D41C0, 0x000D43C8, 0x000D45D0, 0x000D47D8, 0x000D49E0
	.word		0x000D4BE8, 0x000D4DF0, 0x000D4FF8, 0x000D5200, 0x000D5408
	.word		0x000D5610, 0x000D5818, 0x000D5A20, 0x000D5C28, 0x000D5E30
	.word		0x000D6038, 0x000D6240, 0x000D6448, 0x000D6650, 0x000D6858
	.word		0x000D6A60, 0x000D6C68, 0x000D6E70, 0x000D7078, 0x000D7280
	.word		0x000D7488, 0x000D7690, 0x000D7898, 0x000D7AA0, 0x000D7CA8
	.word		0x000D7EB0, 0x000D80B8, 0x000D82C0, 0x000D84C8, 0x000D86D0
	.word		0x000D88D8, 0x000D8AE0, 0x000D8CE8, 0x000D8EF0, 0x000D90F8
	.word		0x000D9300, 0x000D9508, 0x000D9710, 0x000D9918, 0x000D9B20
	.word		0x000D9D28, 0x000D9F30, 0x000DA138, 0x000DA340, 0x000DA548
	.word		0x000DA750, 0x000DA958, 0x000DAB60, 0x000DAD68, 0x000DAF70
	.word		0x000DB178, 0x000DB380, 0x000DB588, 0x000DB790, 0x000DB998
	.word		0x000DBBA0, 0x000DBDA8, 0x000DBFB0, 0x000DC1B8, 0x000DC3C0
	.word		0x000DC5C8, 0x000DC7D0, 0x000DC9D8, 0x000DCBE0, 0x000DCDE8
	.word		0x000DCFF0, 0x000DD1F8, 0x000DD400, 0x000DD608, 0x000DD810
	.word		0x000DDA18, 0x000DDC20, 0x000DDE28, 0x000DE030, 0x000DE238
	.word		0x000DE440, 0x000DE648, 0x000DE850, 0x000DEA58, 0x000DEC60
	.word		0x000DEE68, 0x000DF070, 0x000DF278, 0x000DF480, 0x000DF688
	.word		0x000DF890, 0x000DFA98, 0x000DFCA0, 0x000DFEA8, 0x000E00B0
	.word		0x000E02B8, 0x000E04C0, 0x000E06C8, 0x000E08D0, 0x000E0AD8
	.word		0x000E0CE0, 0x000E0EE8, 0x000E10F0, 0x000E12F8, 0x000E1500
	.word		0x000E1708, 0x000E1910, 0x000E1B18, 0x000E1D20, 0x000E1F28
	.word		0x000E2130, 0x000E2338, 0x000E2540, 0x000E2748, 0x000E2950
	.word		0x000E2B58, 0x000E2D60, 0x000E2F68, 0x000E3170, 0x000E3378
	.word		0x000E3580
EndPWMTable:

	.align 4
SampleTable:
	.word		0x000000FC, 0x00000105, 0x0000010F, 0x00000119, 0x00000122
	.word		0x0000012C, 0x00000136, 0x0000013F, 0x00000149, 0x00000153
	.word		0x0000015C, 0x00000166, 0x00000170, 0x0000017A, 0x00000183
	.word		0x0000018D, 0x00000197, 0x000001A0, 0x000001AA, 0x000001B4
	.word		0x000001BD, 0x000001C7, 0x000001D1, 0x000001DA, 0x000001E4
	.word		0x000001EE, 0x000001F8, 0x00000201, 0x0000020B, 0x00000215
	.word		0x0000021E, 0x00000228, 0x00000232, 0x0000023B, 0x00000245
	.word		0x0000024F, 0x00000259, 0x00000262, 0x0000026C, 0x00000276
	.word		0x0000027F, 0x00000289, 0x00000293, 0x0000029C, 0x000002A6
	.word		0x000002B0, 0x000002B9, 0x000002C3, 0x000002CD, 0x000002D7
	.word		0x000002E0, 0x000002EA, 0x000002F4, 0x000002FD, 0x00000307
	.word		0x00000311, 0x0000031A, 0x00000324, 0x0000032E, 0x00000337
	.word		0x00000341, 0x0000034B, 0x00000355, 0x0000035E, 0x00000368
	.word		0x00000372, 0x0000037B, 0x00000385, 0x0000038F, 0x00000398
	.word		0x000003A2, 0x000003AC, 0x000003B6, 0x000003BF, 0x000003C9
	.word		0x000003D3, 0x000003DC, 0x000003E6, 0x000003F0, 0x000003F9
	.word		0x00000403, 0x0000040D, 0x00000416, 0x00000420, 0x0000042A
	.word		0x00000434, 0x0000043D, 0x00000447, 0x00000451, 0x0000045A
	.word		0x00000464, 0x0000046E, 0x00000477, 0x00000481, 0x0000048B
	.word		0x00000494, 0x0000049E, 0x000004A8, 0x000004B2, 0x000004BB
	.word		0x000004C5, 0x000004CF, 0x000004D8, 0x000004E2, 0x000004EC
	.word		0x000004F5, 0x000004FF, 0x00000509, 0x00000513, 0x0000051C
	.word		0x00000526, 0x00000530, 0x00000539, 0x00000543, 0x0000054D
	.word		0x00000556, 0x00000560, 0x0000056A, 0x00000573, 0x0000057D
	.word		0x00000587, 0x00000591, 0x0000059A, 0x000005A4, 0x000005AE
	.word		0x000005B7, 0x000005C1, 0x000005CB, 0x000005D4, 0x000005DE
	.word		0x000005E8, 0x000005F1, 0x000005FB, 0x00000605, 0x0000060F
	.word		0x00000618, 0x00000622, 0x0000062C, 0x00000635, 0x0000063F
	.word		0x00000649, 0x00000652, 0x0000065C, 0x00000666, 0x00000670
	.word		0x00000679, 0x00000683, 0x0000068D, 0x00000696, 0x000006A0
	.word		0x000006AA, 0x000006B3, 0x000006BD, 0x000006C7, 0x000006D0
	.word		0x000006DA, 0x000006E4, 0x000006EE, 0x000006F7, 0x00000701
	.word		0x0000070B, 0x00000714, 0x0000071E, 0x00000728, 0x00000731
	.word		0x0000073B, 0x00000745, 0x0000074E, 0x00000758, 0x00000762
	.word		0x0000076C, 0x00000775, 0x0000077F, 0x00000789, 0x00000792
	.word		0x0000079C, 0x000007A6, 0x000007AF, 0x000007B9, 0x000007C3
	.word		0x000007CD, 0x00000FFF
EndSampleTable:

	.align 4
ErrorCorrectionTable:
	.word		-90, -89, -88, -87, -86
	.word		-85, -84, -83, -82, -81
	.word		-80, -79, -78, -77, -76
	.word		-75, -74, -73, -72, -71
	.word		-70, -69, -68, -67, -66
	.word		-65, -64, -63, -62, -61
	.word		-60, -59, -58, -57, -56
	.word		-55, -54, -53, -52, -51
	.word		-50, -49, -48, -47, -46
	.word		-45, -44, -43, -42, -41
	.word		-40, -39, -38, -37, -36
	.word		-35, -34, -33, -32, -31
	.word		-30, -29, -28, -27, -26
	.word		-25, -24, -23, -22, -21
	.word		-20, -19, -18, -17, -16
	.word		-15, -14, -13, -12, -11
	.word		-10, -9, -8, -7, -6
	.word		-5, -4, -3, -2, -1
	.word		0, 1, 2, 3, 4
	.word		5, 6, 7, 8, 9
	.word		10, 11, 12, 13, 14
	.word		15, 16, 17, 18, 19
	.word		20, 21, 22, 23, 24
	.word		25, 26, 27, 28, 29
	.word		30, 31, 32, 33, 34
	.word		35, 36, 37, 38, 39
	.word		40, 41, 42, 43, 44
	.word		45, 46, 47, 48, 49
	.word		50, 51, 52, 53, 54
	.word		55, 56, 57, 58, 59
	.word		60, 61, 62, 63, 64
	.word		65, 66, 67, 68, 69
	.word		70, 71, 72, 73, 74
	.word		75, 76, 77, 78, 79
	.word		80, 81, 82, 83, 84
	.word		85, 86, 87, 88, 89
	.word		90, 90
EndErrorCorrectionTable:



;;;;;;Testing Tables;;;;;;

TestServoTable: ;Argument 		Read Iters
				;Delay (ms)
	.byte 		-90,				3
	.half 		500
	.byte 		-90, 			3
	.half 		500
	.byte 		-80, 			3
	.half 		500
	.byte 		70, 			3
	.half 		500
	.byte 		50, 			3
	.half 		500
	.byte 		45, 			3
	.half 		500
	.byte 		30, 			3
	.half 		500
	.byte 		10, 			3
	.half 		500
	.byte 		-10, 			3
	.half 		500
	.byte 		-30, 			3
	.half 		500
	.byte 		-45, 			3
	.half 		500
	.byte 		-60, 			3
	.half 		500
	.byte 		-90, 			3
	.half 		500
	.byte 		-90, 			3
	.half 		500

EndTestServoTable:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																			   ;
; 							Data Section									   ;
;																			   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.data
	.global charbuffer

;;;;;;Variable Declaration;;;;;;
	.align 4
angle:		.space 4	;Signed value representing position
						;in degrees
	.align 4
pwm_stat:	.space 4	;PWM status variable

; Vars for Int2Ascii
	.align 4
charbuffer: .space 12       ; Buffer to store ASCII characters (including negative sign and null terminator)

; LCD Vars
    .align 4
cRow:   .space 1    ; cRow holds the index of the cursor

    .align 4
cCol:   .space 1    ; cCol holds the index of the column


;;;;;;Stack Declaration;;;;;;
	.align  8			;the stack (must be double-word aligned)
TopOfStack:     .bes    TOTAL_STACK_SIZE

;;;;;;Vector Table Declaration;;;;;;
        .align  512		;the interrupt vector table in SRAM
VecTable:       .space  VEC_TABLE_SIZE * BYTES_PER_WORD

.end
