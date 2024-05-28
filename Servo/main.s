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
	MOV32   R0, SET
	STR     R0, [R1]

;;;;;;Init Register Values;;;;;;
;InitRegisters:
	MOV32	R1, GPIO		;Load base address
	STREG   ALL_PINS, R1, DCLR31_0	;Clear all GPIO pins

;;;;;;Init PWM;;;;;;
	;GPT1 is our PWM timer
	MOV32	R1, GPT1					;Load base address
	STREG   GPT_CTL_EN_TA_PWM_STALL, R1, CTL ;Enable PWM timer A with debug stall

;;;;;;Init ADC;;;;;;
;	BL	InitADC

;;;;;;Main Program;;;;;;
Main:

TestPWM:
	ADR 	R4, PWMTable ;start at the beginning of table

TestPWMLoop:
	MOV32	R0, 300	;delay a bit
	BL	Wait_1ms

	LDRH	R0, [R4], #2 	;get the pwm argument from table
	LDRH	R1, [R4], #2 	;get the pwm argument from table
	BL 		SetPWM		;call the function

CheckPWMDoneTest: 				;check if tests done
	ADR 	R5, EndPWMTable	;check if at end of table

	CMP 	R4, R5
	BNE 	TestPWMLoop	;not done with tests, keep looping
	;BEQ 	DoneTestServo 	;otherwise done testing the servo

;Now go back
	SUB		R4, #4

TestPWMLoop2:
	MOV32	R0, 300	;delay a bit
	BL	Wait_1ms

	LDRH	R0, [R4], #-2 	;get the pwm argument from table
	LDRH	R1, [R4], #-2 	;get the pwm argument from table
	BL 		SetPWM		;call the function

CheckPWMDoneTest2: 				;check if tests done
	ADR 	R5, PWMTable	;check if at end of table
	ADD		R5, #4
	CMP 	R4, R5
	BNE 	TestPWMLoop2	;not done with tests, keep looping
	;BEQ 	DoneTestServo 	;otherwise done testing the servo

	B TestPWMLoop


TestServo: ;do the servo function tests
	ADR 	R4, TestServoTab ;start at the beginning of table

TestServoLoop:
	LDRB	R0, [R4], #1 	;get the SetServo argument from table
	BL 		SetServo		;call the function
	LDRB 	R5, [R4], #1 	;get iterations from the table

TestGetServoLoop: 			;loop testing GetServo function
	BL 		GetServo 		;call GetServo
;	BL 		DisplayServo 	;display GetServo results
	LDRH 	R0, [R4] 		;get the time delay from the table
	BL 		Wait_1ms 		;delay amount specified
	SUBS 	R5, #1 			;update loop counter
	BNE 	TestGetServoLoop	;loop specified number of times
	;BEQ 	CheckDoneTest 	;then check if tests done

CheckDoneTest: 				;check if tests done
	ADD		R4, #2			;get past delay entry in table
	ADR 	R5, EndTestServoTab	;check if at end of table
	CMP 	R4, R5
	BNE 	TestServoLoop	;not done with tests, keep looping
	;BEQ 	DoneTestServo 	;otherwise done testing the servo

DoneTestServo: ;done testing servo

	B	Main
	BL	ReleaseServo	;Put the servo in release mode

ReleaseLoop:
;	BL	GetServo		;Get servo angle
;	BL	DisplayServo	;Display servo angle
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
	MOVA	R1, angle	;Save new input angle in the angle variable
	STR		R0, [R1]

	PUSH	{LR}
	BL		CalculatePWMRate	;(ARGS: R0 = angle)
	POP		{LR}	;Return R0 and R1 with the duty cycle prescale value

	PUSH	{LR}
	BL		SetPWM			;(ARGS: R0 = TAMATCHR, R1 = TAPMR)
	POP		{LR}	;PWM should be updated/set

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

	STREG   GPT_CTL_TA_PWM_STALL, R1, CTL	;Disable PWM timer
	;Alternateivly disable interrupts??

	STREG	PWM_PIN, R1, DCLR31_0	;Clear the PWM pin

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

	PUSH	{LR}
	BL		GetADCFIFO
	POP		{LR}

	PUSH	{LR}
	BL		FlushADCFIFO
	POP		{LR}

	PUSH	{LR}
	BL		ErrorCorrection
	POP		{LR}

	MOVA	R1, angle	;Save new angle in angle variable
	STR		R0, [R1]

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

	PUSH	{R0}
	STREG   GPT_CTL_TA_PWM_STALL, R2, CTL	;Disable timer
	POP		{R0}

	CPSID	I	;Disable interrupts to avoid critical code

	MOV32	R3, TAPMR
	STR   	R1, [R2, R3] 	;Set timer match preset

	MOV32	R3, TAMATCHR 	;Set timer match duration
	STR   	R0, [R2, R3]

	CPSIE	I	;Enable interrupts again

	STREG   GPT_CTL_EN_TA_PWM_STALL, R2, CTL	;Enable timer

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
	PUSH    {R0, R1, R2}	;Push registers

	MOV32	R1, AUX_DDI0_OSC	;Load AUX domain clock control base address

ADCProcessingLoop:
	MOV32	R2, ADCDATAREADYMASK	;Get ADC processing status
	LDR     R0, [R1, #STAT0]		;First load general status register
	ANDS	R0, R2					;Mask for only the relevant bit
	BNE		ADCProcessingLoop		;Keep looping until ADC is ready
	;BEQ	ADCReady
;while you are at it STAT0 tells you if the RCOSC_HF is on which is your ADC source check it
ADCReady:
	MOV32	R1, AUX_ANAIF	;Load analog interface base address

	MOV32	R2, ADC_DATAMASK	;Get ADC data
	LDR     R0, [R1, #ADCFIFO]
	AND		R0, R2				;But only the relevant bits

ENDGetADCFIFO:
	POP    	{R0, R1, R2}	;Pop registers
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
	PUSH    {R0, R1}	;Push registers

	MOVA 	R2, SampleTable ;start at the beginning of table
;	ADR 	R2, CorrectionTable ;start at the beginning of table

LookupTableLoop:
	LDRSB	R1, [R2], #1 	;Get the first sample in lookup table

TestSampleLoop: 			;Check if sample is found in lookup table
	CMP 	R1, R0 			;Compare sample with table data
	BNE 	LookupTableLoop	;Loop until a match is found
	;BEQ 	GetCorrectData 	;When a match is found, get the correct data

GetCorrectData:
	ADD		R2, #ErrorCorrectionTableOffset	;Modify the address to map to correction table
	LDR		R0, [R2]

;ENDErrorCorrection:


;or

	MOV32	R2, ADCSCALINGFACTOR
	MUL		R0, R2
	MOV32	R2, ADCOFFSET
	ADD		R0, R2

ENDErrorCorrection:
	POP    	{R0, R1}	;Pop registers
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
;	STREG   NO_VDDR, R1, MUX0
;	STREG   NO_SOURCES, R1, MUX2

;	Mux AUXIO26 (GPIO 23) into the ADC channel
	STREG   MUX_AUXIO26, R1, MUX3

;	Enable ADC module in synchronous mode with 2.7us sampling rate
	STREG   ENADC_SYNC_2p7us, R1, ADC0

;	Keep the 1408/4095 (.3438) scaling
;	STREG   ADC_PRESCALE, R1, ADC1

;	Enable ADC reference even in idle state
	STREG   ADC_REF_EN_4p3_IDLE, R1, ADCREF0

;	Keep nominal 1.43V scaled reference
;	STREG   NOMINAL_ADCREF, R1, ADCREF1

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

	MOV32	R2, GPT0		;Load base address

	MOV32	R3, TAMATCHR	;Load match reg offset address
	STR   	R0, [R2, R3] 	;Set timer match duration

	MOV32	R3, TAPMR		;Load prescale reg offset address
	STR   	R1, [R2, R3]	;Set match prescaler

ENDDisplayServo:
	POP    	{R0, R1, R2, R3}	;Pop registers
	BX		LR			;Return

; GPT1EventHandler:
;
; Description:	This procedure is called through the GPT1 vector table
;		  		interupt. It happens when the PWM signal changes state.
;
; Operation:	Toggles GPIO 21 output when PWM changes state.
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
; Output:           GPIO 21 output state
;
; Error Handling:   Assumes that GPIO 21 is already in the correct state
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
;	ToggleGPIO(21)
;	return
GPT1EventHandler:
	;PUSH    {R0, R1, R2}	;R0-R3 are autosaved

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

	;POP    {R0, R1, R2}			;R0-R3 are autorestored
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
	STREG   GPT01_CLK_ON, R1, GPTCLKGR	;GPT0 and GPT1 clocks power on
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
;	Set GPIO pin 21 as an output
;	Set GPIO pin 23 as an AUXIO input for ADC
;
;	Write to DOE31_0 to enable the LED outputs
;	Load base address
;	Enable pins 0-3 as outputs
;	BX		LR			;Return
InitGPIO:
	;Write to IOCFG21 to be a PWM data output
	MOV32	R1, IOC						;Load base address
	STREG   IO_OUT_CTRL, R1, IOCFG21	;Set GPIO pin 21 as an output

	MOV32	R1, GPIO					;Load base address
	STREG   OUTPUT_ENABLE_21, R1, DOE31_0	;Enable pin 21 as output

	;Write to AUXIO26 to be an ADC input
	MOV32	R1, AUX_AIODIO3				;Load base address
	STREG   AUXIO8ip2IN, R1, IOMODE		;Enable AUXIO[8i+2] as input
	STREG   NODIB, R1, GPIODIE			;Disable digital input buffers
	;AUX pin 26 maps to GPIO pin 23

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

	MOV32	R1, SCS						;Load base address
	STREG   EN_INT_T1A, R1, NVIC_ISER0	;Interrupt enable

	BX	LR								;Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Wait_1ms:
;
; Description:	Waits in 1ms intervals. Takes how many ms as a parameter
;
; Operation:    Loops the 1ms timer as many times as in the parameter
;
; Arguments:         R0 - Amount of ms to wait
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
; Revision History:  12/7/24	George Ore	 created
;					 12/8/24	George Ore	 formated, moved to HW5
;					 01/2/24	George Ore	 made interrupt driven to fix
;											 skipping error and moved to HW4
;
; Pseudo Code
;
;	while(counter!=0)
;		reset 1msTimer
;		while(1msTimerTimeoutInterrupt!=Set)
;			NOP
;		counter--
;	return
Wait_1ms:
	PUSH    {R0, R1, R2, R3, R4}	;Push registers

	MOV		R1, R0		;Relocate amount of ms into R1
	MOV32	R2, GPT0	;Load GPT0 base address
	MOV32	R3, COUNT_DONE	;Load ms count done condition
	MOV32	R4, IRQ_TATO	;Load NOT1ms timer doneNOT timeout interrupt condition

W_1ms_Cntr_Loop:
	CMP		R1, R3			;Check if the ms counter is done
	BEQ		End_1ms_Wait	;If it is, end wait
	;BNE	Reset_1ms_Timer	;if not reset the 1ms timer

Reset_1ms_Timer:
	STREG   CTL_TA_STALL, R2, CTL	;Enable timer with debug stall

W_1ms_Timr_Loop:
	LDR		R0, [R2, #MIS]	;Get the masked interrupt status
;	LDR		R0, [R2, #TAR]	;Get the 1ms timer value
	CMP		R0, R4			;Check if 1ms timer is done Check if timeout interrupt has happened
	BNE		W_1ms_Timr_Loop	;If 1ms hasn't passed, wait
	;BEQ	DecCounter		;if 1ms passed, decrement the cntr

DecCounter:
	STREG   IRQ_TATO, R2, ICLR  	;Clear timer A timeout interrupt
	SUB		R1, #ONE	;Decrement the counter and go back to
	B		W_1ms_Cntr_Loop	;counter value check

End_1ms_Wait:
	POP    	{R0, R1, R2, R3, R4}	;Pop registers
	BX		LR			;Return

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
	.word		0x0000EA80,0x0000E975,0x0000E86A,0x0000E760,0x0000E655
	.word		0x0000E54A,0x0000E440,0x0000E335,0x0000E22A,0x0000E120
	.word		0x0000E015,0x0000DF0A,0x0000DE00,0x0000DCF5,0x0000DBEA
	.word		0x0000DAE0,0x0000D9D5,0x0000D8CA,0x0000D7C0,0x0000D6B5
	.word		0x0000D5AA,0x0000D4A0,0x0000D395,0x0000D28A,0x0000D180
	.word		0x0000D075,0x0000CF6A,0x0000CE60,0x0000CD55,0x0000CC4A
	.word		0x0000CB40,0x0000CA35,0x0000C92A,0x0000C820,0x0000C715
	.word		0x0000C60A,0x0000C500,0x0000C3F5,0x0000C2EA,0x0000C1E0
	.word		0x0000C0D5,0x0000BFCA,0x0000BEC0,0x0000BDB5,0x0000BCAA
	.word		0x0000BBA0,0x0000BA95,0x0000B98A,0x0000B880,0x0000B775
	.word		0x0000B66A,0x0000B560,0x0000B455,0x0000B34B,0x0000B240
	.word		0x0000B135,0x0000B02B,0x0000AF20,0x0000AE15,0x0000AD0B
	.word		0x0000AC00,0x0000AAF5,0x0000A9EB,0x0000A8E0,0x0000A7D5
	.word		0x0000A6CB,0x0000A5C0,0x0000A4B5,0x0000A3AB,0x0000A2A0
	.word		0x0000A195,0x0000A08B,0x00009F80,0x00009E75,0x00009D6B
	.word		0x00009C60,0x00009B55,0x00009A4B,0x00009940,0x00009835
	.word		0x0000972B,0x00009620,0x00009515,0x0000940B,0x00009300
	.word		0x000091F5,0x000090EB,0x00008FE0,0x00008ED5,0x00008DCB
	.word		0x00008CC0,0x00008BB5,0x00008AAB,0x000089A0,0x00008895
	.word		0x0000878B,0x00008680,0x00008575,0x0000846B,0x00008360
	.word		0x00008255,0x0000814B,0x00008040,0x00007F36,0x00007E2B
	.word		0x00007D20,0x00007C16,0x00007B0B,0x00007A00,0x000078F6
	.word		0x000077EB,0x000076E0,0x000075D6,0x000074CB,0x000073C0
	.word		0x000072B6,0x000071AB,0x000070A0,0x00006F96,0x00006E8B
	.word		0x00006D80,0x00006C76,0x00006B6B,0x00006A60,0x00006956
	.word		0x0000684B,0x00006740,0x00006636,0x0000652B,0x00006420
	.word		0x00006316,0x0000620B,0x00006100,0x00005FF6,0x00005EEB
	.word		0x00005DE0,0x00005CD6,0x00005BCB,0x00005AC0,0x000059B6
	.word		0x000058AB,0x000057A0,0x00005696,0x0000558B,0x00005480
	.word		0x00005376,0x0000526B,0x00005160,0x00005056,0x00004F4B
	.word		0x00004E40,0x00004D36,0x00004C2B,0x00004B21,0x00004A16
	.word		0x0000490B,0x00004801,0x000046F6,0x000045EB,0x000044E1
	.word		0x000043D6,0x000042CB,0x000041C1,0x000040B6,0x00003FAB
	.word		0x00003EA1,0x00003D96,0x00003C8B,0x00003B81,0x00003A76
	.word		0x0000396B,0x00003861,0x00003756,0x0000364B,0x00003541
	.word		0x00003436,0x0000332B,0x00003221,0x00003116,0x0000300B
	.word		0x00002F01
EndSampleTable:

	.align 4
ErrorCorrectionTable:
	.word		0x0000EA80,0x0000E975,0x0000E86A,0x0000E760,0x0000E655
	.word		0x0000E54A,0x0000E440,0x0000E335,0x0000E22A,0x0000E120
	.word		0x0000E015,0x0000DF0A,0x0000DE00,0x0000DCF5,0x0000DBEA
	.word		0x0000DAE0,0x0000D9D5,0x0000D8CA,0x0000D7C0,0x0000D6B5
	.word		0x0000D5AA,0x0000D4A0,0x0000D395,0x0000D28A,0x0000D180
	.word		0x0000D075,0x0000CF6A,0x0000CE60,0x0000CD55,0x0000CC4A
	.word		0x0000CB40,0x0000CA35,0x0000C92A,0x0000C820,0x0000C715
	.word		0x0000C60A,0x0000C500,0x0000C3F5,0x0000C2EA,0x0000C1E0
	.word		0x0000C0D5,0x0000BFCA,0x0000BEC0,0x0000BDB5,0x0000BCAA
	.word		0x0000BBA0,0x0000BA95,0x0000B98A,0x0000B880,0x0000B775
	.word		0x0000B66A,0x0000B560,0x0000B455,0x0000B34B,0x0000B240
	.word		0x0000B135,0x0000B02B,0x0000AF20,0x0000AE15,0x0000AD0B
	.word		0x0000AC00,0x0000AAF5,0x0000A9EB,0x0000A8E0,0x0000A7D5
	.word		0x0000A6CB,0x0000A5C0,0x0000A4B5,0x0000A3AB,0x0000A2A0
	.word		0x0000A195,0x0000A08B,0x00009F80,0x00009E75,0x00009D6B
	.word		0x00009C60,0x00009B55,0x00009A4B,0x00009940,0x00009835
	.word		0x0000972B,0x00009620,0x00009515,0x0000940B,0x00009300
	.word		0x000091F5,0x000090EB,0x00008FE0,0x00008ED5,0x00008DCB
	.word		0x00008CC0,0x00008BB5,0x00008AAB,0x000089A0,0x00008895
	.word		0x0000878B,0x00008680,0x00008575,0x0000846B,0x00008360
	.word		0x00008255,0x0000814B,0x00008040,0x00007F36,0x00007E2B
	.word		0x00007D20,0x00007C16,0x00007B0B,0x00007A00,0x000078F6
	.word		0x000077EB,0x000076E0,0x000075D6,0x000074CB,0x000073C0
	.word		0x000072B6,0x000071AB,0x000070A0,0x00006F96,0x00006E8B
	.word		0x00006D80,0x00006C76,0x00006B6B,0x00006A60,0x00006956
	.word		0x0000684B,0x00006740,0x00006636,0x0000652B,0x00006420
	.word		0x00006316,0x0000620B,0x00006100,0x00005FF6,0x00005EEB
	.word		0x00005DE0,0x00005CD6,0x00005BCB,0x00005AC0,0x000059B6
	.word		0x000058AB,0x000057A0,0x00005696,0x0000558B,0x00005480
	.word		0x00005376,0x0000526B,0x00005160,0x00005056,0x00004F4B
	.word		0x00004E40,0x00004D36,0x00004C2B,0x00004B21,0x00004A16
	.word		0x0000490B,0x00004801,0x000046F6,0x000045EB,0x000044E1
	.word		0x000043D6,0x000042CB,0x000041C1,0x000040B6,0x00003FAB
	.word		0x00003EA1,0x00003D96,0x00003C8B,0x00003B81,0x00003A76
	.word		0x0000396B,0x00003861,0x00003756,0x0000364B,0x00003541
	.word		0x00003436,0x0000332B,0x00003221,0x00003116,0x0000300B
	.word		0x00002F01
EndErrorCorrectionTable:


;;;;;;Testing Tables;;;;;;

TestServoTab: 	;Argument 		Read Iters
				;Delay (ms)
	.byte 		  -60,			1
	.half 		500
	.byte 		-30, 			1
	.half 		500
	.byte 		 90, 			1
	.half 		500
	.byte 		 30, 			1
	.half 		500
	.byte 		 45, 			1
	.half 		500


EndTestServoTab:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																			   ;
; 							Data Section									   ;
;																			   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.data

;;;;;;Variable Declaration;;;;;;
	.align 4
angle:		.space 4	;Signed value representing position
						;in degrees
pwm_stat:	.space 4	;PWM status variable

;;;;;;Stack Declaration;;;;;;
	.align  8			;the stack (must be double-word aligned)
TopOfStack:     .bes    TOTAL_STACK_SIZE

;;;;;;Vector Table Declaration;;;;;;
        .align  512		;the interrupt vector table in SRAM
VecTable:       .space  VEC_TABLE_SIZE * BYTES_PER_WORD

.end
