;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																			   ;
;								EE110a HW4 Functions						   ;
;									George Ore								   ;
;																			   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description:	This file includes the functions that are needed for the HW1
;				main loop.
; Goal:			The goal of these functions is to extract data from the
;				MPU-9250 IMU. It includes functions for the 3-axis
;				accelerometer, 3-axis gyroscope, and the 3-axis magnetometer.
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
	.ref	InLimTest
	.ref	Degree2Step
	.ref	Wait_1ms

	.ref	steps
	.ref	dir
	.ref	pos
	.ref	curStep

	.ref	PWM20kHzSinTable
	.ref	PWM20kHzCosTable

	.ref 	SetPWM

	.ref 	UpdateDirection
	.ref 	UpdateSteps

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;								Table of Contents
;		Function Name	|	Purpose
	.def	SetAngle	;	Fetch accelerometer x-axis data
	.def	SetRelAngle	;	Fetch accelerometer y-axis data
	.def	HomeStepper	;	Fetch accelerometer z-axis data
	.def	GetAngle	;	Fetch gyroscope x-axis data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Revision History:	02/04/24	George Ore	Created format
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;*******************************************************************************
;*								FUNCTIONS									   *
;*******************************************************************************

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SetAngle:
;
; Description:	The function is passed a single argument (angle) in R0 which is
;				the absolute angle (in degrees) at which the stepper motor is to
;				be pointed. This angle is unsigned (i.e. positive values only).
;				An angle of zero (0) indicates the "home" position for the
;				stepper motor and non-zero angles are measured clockwise.
;				The angle resolution must be at least 6 degrees.
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
; Error Handling:    Invalid angle inputs ignored
;
; Registers Changed: R0, R1, R2, R3, R4
; Stack Depth:       1 word
;
; Algorithms:        None.
; Data Structures:   None.
;
; Known bugs:
;
; Limitations: The angle resolution must be at least 6 degrees.
;
; Revision History:  12/30/24	George Ore	 created
;
; Pseudo Code
;
;	(ARGS: R0 = angle)
;
;	Input = InLimTest(ARGS: R0 = Input, R1 = MaxInput, R2 = MinInput)
;	If Input == InvalidInput
;		return
;
;	disableinterrupts(no more stepping)
;
;	DegreeOffset = angle-pos
;	DegreesNeeded = abs(DegreeOffset)
;	PSteps = Degree2Step(DegreesNeeded)
;
;	if angle>pos
;		if PSteps < 30
;			dir = CW
;			steps = PSteps
;		else (PSteps >= 30)
;			dir = CCW
;			steps = TotalSteps-PSteps
;	else (angle<=pos)
;		if PSteps < 30
;			dir = CCW
;			steps = PSteps
;		else (PSteps >= 30)
;			dir = CW
;			steps = TotalSteps-PSteps
;
;	enableinterrupts(ok stepping again)
;	return
;
;SetAngle(angle)	 rotate the stepper motor to absolute angle angle
;	- Input must be [0 - 359] integer
;		- Test to see if the input is valid
;			- Return if not
;	- Calculate where and how much to step towards
;		- Calculate direction
;			- See which direction gets you there quicker
;				- Fetch pos and subtract input angle
;				- If it is negative, go set dir CCW
;					- Else set it CW
;		- Calculate steps
;			- You already subtracted the two positions
;				- If it was negative, hit that yummy little 2s compliment
;			- Set that as the new amount of steps to take
;	- THIS TOUCHES "dir", "pos", AND "steps"
;		- IMPORTANT FOR CRITICAL CODE
SetAngle:
	PUSH    {R0, R1, R2}	;Push registers

;InputTest:
	MOV32	R1, MAXANGIN	;Set parameters for the input
	MOV32	R2, MINANGIN	;limit test function
	PUSH	{LR}	;Call InLimTest
	BL		InLimTest	;(ARGS: R0 = Input, R1 = MaxInput, R2 = MinInput)
	POP		{LR}	;If input is invalid, it will be modified

	MOV32	R1, INVALIDINPUT	;Test if input is invalid
	CMP		R0, R1
	BEQ		EndSetAngle	;If it is, return and dont set angle
	;BNE	SetAngleParams	;If not, start setting the input angle

SetAngleParams:
	MOVA	R2, pos	;Load motor position in R1****
;	CPSID	I	;Disable interrupts to avoid critical code
	LDR		R1, [R2]

;Calculate the difference in angle to get signed steps
	SUB		R0, R0, R1

	PUSH	{LR}
	BL UpdateDirection
	POP		{LR}

	PUSH	{LR}
	BL UpdateSteps
	POP		{LR}

;	CPSIE	I	;Enable interrupts again

EndSetAngle:
	POP    	{R0, R1, R2}	;Pop registers
	BX		LR			;Return


; SetRelAngle:
;
; Description:	The function is passed a single argument (angle) in R0 that is
;				the relative angle (in degrees) through which to turn the
;				stepper motor. A relative angle of zero (0) indicates no
;				movement, positive relative angles indicate clockwise rotation,
;				and negative relative angles indicate counterclockwise rotation.
;				The angle is relative to the current stepper motor position. The
;				angle resolution must be at least 6 degrees.
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
; Error Handling:    Invalid angle inputs ignored
;
; Registers Changed: R0, R1, R2, R3, R4
; Stack Depth:       1 word
;
; Algorithms:        None.
; Data Structures:   None.
;
; Known bugs:		 None.
;
; Limitations: The angle resolution must be at least 6 degrees.
;
; Revision History:  12/30/24	George Ore	 created
;
; Pseudo Code
;
;	(ARGS: R0 = relAngle)
;
;	Input = InLimTest(ARGS: R0 = Input, R1 = MaxInput, R2 = MinInput)
;	If Input == InvalidInput
;		return
;
;	disableinterrupts(no more stepping)
;
;	PRelAngle = Abs(relAngle)
;	relSteps = Degree2Step(PRelAngle)
;	if relSteps<steps (flip dir impossible)
;		if dir == CW
;			if relAngle<0
;				steps = steps-relSteps
;			else (relAngle>=0)
;				steps = steps+relSteps
;		else (dir == CCW)
;			if relAngle<0
;				steps =+ relSteps
;			else (relAngle>=0)
;				steps =- relSteps
;	else (relSteps>=steps)
;		if (dir == CCW) (steps is nonzero and negative so abs(relSteps) is nonzero and larger than steps)
;			if relAngle<0
;				steps =+ relSteps
;			else (relAngle>=0)
;				dir = CW
;				steps = relSteps-steps
;		else (dir == CW) (steps=0+ relSteps=any)
;			if relAngle>=0
;				steps = steps+relSteps
;			else (relAngle<0)
;				if relStep-steps == 0
;					steps = (0) relSteps-steps
;				else (relStep-steps>0)
;					pos = CCW
;					steps = relSteps-steps
;
;	enableinterrupts(ok stepping again)
;	return
;
;SetRelAngle(angle) rotate the stepper motor by relative angle angle
;	- Input can be [-359 - 359]
;		- Maybe later you can make it so that it can handle inputs up to 0xFFFFFFFF
;		- Test to see if the input is valid
;			- Return if not
;	- Calculate where and how much to step towards
;		- Calculate direction
;			- Direction is kinda given to you already
;				- If it is negative, go set dir CCW
;					- Else set it CW
;		- Calculate steps
;			- You kinda already know the amount of steps that you need to queue
;				- If it was negative, hit that yummy little 2s compliment
;			- Set that as the new amount of steps to take
;	- THIS TOUCHES "dir", AND "steps"
;		- IMPORTANT FOR CRITICAL CODE
;
SetRelAngle:
	PUSH    {R0, R1, R2, R3, R4}	;Push registers

;InputTest:
	MOV32	R1, MAXRELANGIN	;Set parameters for the input
	MOV32	R2, MINRELANGIN	;limit test function
	PUSH	{LR}	;Call InLimTest
	BL		InLimTest	;(ARGS: R0 = Input, R1 = MaxInput, R2 = MinInput)
	POP		{LR}	;If input is invalid, it will be modified

	MOV32	R1, INVALIDINPUT	;Test if input is invalid
	CMP		R0, R1
	BEQ		EndSetRelAngle	;If it is, return and dont set relative angle
	;BNE	SetRelAngleParams	;If not, start setting relative angle

SetRelAngleParams:
;	CPSID	I	;Disable interrupts to avoid critical code

	PUSH	{LR}
	BL UpdateDirection
	POP		{LR}

	PUSH	{LR}
	BL UpdateSteps
	POP		{LR}

;	CPSIE	I	;Enable interrupts again


EndSetRelAngle:
;	CPSIE	I	;Enable interrupts again
	POP    	{R0, R1, R2, R3, R4}	;Pop registers
	BX		LR			;Return

; HomeStepper:
;
; Description:	The function takes no arguments and sets the stepper motor to an
;				absolute angle of 0 degrees (the "home" position).
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
; Known bugs:	None
;
; Limitations: The angle resolution must be at least 6 degrees??? not mentioned
;
; Revision History:  12/30/24	George Ore	 created
;
; Pseudo Code
;
;	disableinterrupts(no more stepping)
;
;	HSteps = Degree2Step(pos)
;	if HSteps > Degree2Step(180)
;		dir = CW
;		steps = TotalSteps-HSteps
;	else (HSteps <= Degree2Step(180))
;		dir = CCW
;		steps = HSteps
;
;	enableinterrupts(ok stepping again)
;NEWNEWNEW REFACTOR
;HomeStepper()	 set the stepper motor to an absolute angle of 0 degrees
;	- Just call SetAngle with the 0 input lol
;
;	return
OldHomeStepper:
	PUSH    {R0, R1, R2, R3, R4}	;Push registers

;	CPSID	I	;Disable interrupts to avoid critical code

	MOVA	R1, pos	;Load current motor position in R0
	LDR		R0, [R1]

	PUSH	{LR}	;Call Degree2Step
	BL		Degree2Step	;(ARGS: R0 = degree)
	POP		{LR}	;Loads R0 with the step equivalent of the degree

;R0 now contains the steps away from home in the CCW direction

	MOV32	R1, HROT_STEPS	;Test if CCW steps from home is greater than or equal to
	CMP		R0, R1			;the number of steps it takes to make a half rotation
	BGE		HomeCW		;If steps from home >= steps in half rotation, go home
	;BLT	HomeCCW		;by going CW. If not, go home by going CCW

HomeCCW:
;Remember R0 has the number of steps to go home CCW
	MOVA	R1, steps	;Set steps to relSteps-steps and save
	STR		R0, [R1]

	MOV32	R0, CCW	;Set dir to CCW
	MOVA	R1, dir
	STR		R0, [R1]

	B		EndHomeStepper	;End setting step home

HomeCW:
;Remember R0 has the number of steps to go home CCW
	MOV32	R1, FROT_STEPS	;Calculate fullRotSteps- CCW dir home steps
	SUB		R1, R0

	MOVA	R0, steps	;Set steps to fullRotSteps-CCWdirHomesteps and save
	STR		R1, [R0]

	MOV32	R0, CW	;Set dir to CW
	MOVA	R1, dir
	STR		R0, [R1]

	;B		EndHomeStepper	;End setting step home

EndOldHomeStepper:
;	CPSIE	I	;Enable interrupts again
	POP    	{R0, R1}	;Pop registers
	BX		LR			;Return
;NEWNEWNEW REFACTOR
;HomeStepper()	 set the stepper motor to an absolute angle of 0 degrees
;	- Just call SetAngle with the 0 input lol
;
;	return
HomeStepper:
	PUSH    {R0}	;Push registers

	MOV32 R0, 0		;Set angle to 0 (home)
	PUSH    {LR}
	BL	SetAngle
	POP     {LR}

EndHomeStepper:
	POP    	{R0}	;Pop registers
	BX		LR			;Return



; GetAngle:
;
; Description:	The function is called with no arguments and returns the current
;				absolute angle setting for the stepper motor in degrees in R0.
;				An angle of zero (0) indicates the stepper motor is in the
;				"home" position and angles are measured clockwise. The value
;				returned must always be between 0 and 359 inclusively.
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
; Known bugs:
;
; Limitations: The angle resolution must be at least 6 degrees???
;
; Revision History:  12/30/24	George Ore	 created
;
; Pseudo Code
;
; GetAngle() returns the current absolute angle of the stepper motor
;	- Just fetch pos and return that foo
;		- Make sure to pause interrupts because critical code
;
;		R0 = pos
;		return R0
GetAngle:
	PUSH    {R1}	;Push register

;    CPSID   I   ;Disable interrupts to avoid critical code

	MOVA	R1, pos	; Fetch the current position (in angle 0-359)
	LDR		R0, [R1]

;    CPSIE   I   ;Enable interrupts again

EndGetAngle:
	POP    	{R1}	;Pop registers
	BX		LR			;Return


.end
