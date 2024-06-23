;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																			   ;
;								EE110a HW5 Functions						   ;
;									George Ore								   ;
;																			   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description:	This file includes the functions that are required in the HW5
;				specifications.
; Goal:			The goal of these functions is to control a servo motor and
;				receive feedback to detect its postion.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;							Required Constant Files
	.include "constants.inc"	;contains misc. constants
	.include "macros.inc"		;contains all macros
	.include "configPWR&CLK.inc"	;contains power config constants
	.include "configGPIO.inc"	;contains GPIO config constants
	.include "GPIO.inc"			;contains GPIO control constants
	.include "GPT.inc"			;contains GPT control constants
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;							Required Functions
	;Reference variables
	.global	pos
	.global angle

	;Helper functions
	.ref 	SetPWM			;Change the duty cycle of the PWM signal
	.ref 	ErrorCorrection	;Correct for the error in the ADC input
	.ref 	CalculatePWMRate;Calculate the desirewd PWM duty cycle

	;ADC functions
	.ref	SampleADC		;	Trigger the ADC
	.ref	GetADCFIFO		;	Fetch ADC data
	.ref	FlushADCFIFO	;	Refresh the ADC FIFO
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;								Table of Contents
;		Function Name	|	Purpose
	.def	SetServo	;	Sets the servo to some angle from -90 to 90 degrees
	.def	ReleaseServo;	Releases the servo motor to be adjusted by user
	.def	GetServo	;	Fetches the current positional data of the servo
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Revision History:	02/04/24	George Ore	Created format
;					06/23/24	George Ore	Refactored and turned in
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;*******************************************************************************
;*								FUNCTIONS									   *
;*******************************************************************************

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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

	PUSH	{LR}
	BL		GetADCFIFO
	POP		{LR}

	PUSH	{LR}
	BL		ErrorCorrection
	POP		{LR}

	MOVA	R1, angle	;Save new angle in angle variable
	STR		R0, [R1]

	PUSH	{LR}
	BL		FlushADCFIFO
	POP		{LR}

EndGetServo:
	POP    	{R0, R1, R2, R3, R4}	;Pop registers
	BX		LR			;Return
