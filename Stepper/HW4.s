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
	BEQ		ENDSetAngle	;If it is, return and dont set angle
	;BNE	SetAngleParams	;If not, start setting the input angle

SetAngleParams:
	MOVA	R2, pos	;Load motor position in R1****
	CPSID	I	;Disable interrupts to avoid critical code
	LDR		R1, [R2]
	CPSIE	I	;Enable interrupts again

	MOV		R2, R0	;Store a copy of input angle in R2

	CMP		R0, R1	;Test if angle is >= to motor position
	BGE		SetDegreeOffset2	;If angle >= pos, do calculation 2
	;BLT	SetDegreeOffset1	;If not, do calculation 1

SetDegreeOffset1:	;angle >= pos, so our degree offset from the
	SUB		R0, R1	;target angle should be angle-pos stored in R0****

	B		PotStepsCalc	;Proceed to the potential steps calculation

SetDegreeOffset2:	;angle < pos, so our degree offset from
	MOV		R0, R1	;the target angle should be pos-angle
	SUB		R0, R2	;stored in R0****

;	B		PotStepCalc	;Proceed to the potential step calculation

PotStepsCalc:
	PUSH	{LR}	;Call Degree2Step
	BL		Degree2Step	;(ARGS: R0 = degree)
	POP		{LR}	;Loads R0 with the step equivalent of the degree
;This means R0 now contains a potential number of steps to queue up - PSteps

	CMP		R2, R1	;Test if angle is >= to motor position
	BGE		StepDirTest2	;If angle >= pos, do steps/direction test 2
	;BLT	StepDirTest1	;If not, do steps/direction test 1

StepDirTest1:
	MOV32	R1, HROT_STEPS
	CMP		R0, R1	;Test if potential step value is greater than or equal to half a rotation of steps
	BGE		SetCCWInvertSteps	;If not, set dir=ccw and steps=TotalSteps-PSteps
	;BLT	SetCWPSteps	;If it is, set dir=cw and steps=PSteps

SetCWPSteps:
	MOVA	R1, steps
	CPSID	I	;Disable interrupts to avoid critical code
	STR		R0,	[R1]
	CPSIE	I	;Enable interrupts again

	MOV32	R0, CW
	MOVA	R1, dir
	CPSID	I	;Disable interrupts to avoid critical code
	STR		R0,	[R1]
	CPSIE	I	;Enable interrupts again

	B		ENDSetAngle

StepDirTest2:
	MOV32	R1, HROT_STEPS
	CMP		R0, R1	;Test if potential step value is greater than or equal to half a rotation of steps
	BGE		SetCWInvertSteps	;If it is, set dir=cw and steps=PSteps
	;BLT	SetCCWPSteps	;If not, set dir=ccw and steps=TotalSteps-PSteps

SetCCWPSteps:
	MOVA	R1, steps
	CPSID	I	;Disable interrupts to avoid critical code
	STR		R0,	[R1]
	CPSIE	I	;Enable interrupts again

	MOV32	R0, CCW
	MOVA	R1, dir
	CPSID	I	;Disable interrupts to avoid critical code
	STR		R0,	[R1]
	CPSIE	I	;Enable interrupts again

	B		ENDSetAngle

SetCWInvertSteps:
	MOV32	R2, FROT_STEPS
	SUB		R2, R0
	MOVA	R1, steps
	CPSID	I	;Disable interrupts to avoid critical code
	STR		R2,	[R1]
	CPSIE	I	;Enable interrupts again

	MOV32	R0, CW
	MOVA	R1, dir
	CPSID	I	;Disable interrupts to avoid critical code
	STR		R0,	[R1]
	CPSIE	I	;Enable interrupts again

	B		ENDSetAngle

SetCCWInvertSteps:
	MOV32	R2, FROT_STEPS
	SUB		R2, R0
	MOVA	R1, steps
	CPSID	I	;Disable interrupts to avoid critical code
	STR		R2,	[R1]
	CPSIE	I	;Enable interrupts again

	MOV32	R0, CCW
	MOVA	R1, dir
	CPSID	I	;Disable interrupts to avoid critical code
	STR		R0,	[R1]
	CPSIE	I	;Enable interrupts again

	;B		ENDSetAngle

ENDSetAngle:
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
	BEQ		ENDSetRelAngle	;If it is, return and dont set relative angle
	;BNE	SetRelAngleParams	;If not, start setting relative angle

SetRelAngleParams:
	CPSID	I	;Disable interrupts to avoid critical code

	MOV		R3, R0	;Store a copy of input relAngle in R1****

	;Calculate abs(relAngle) = positive relative angle (PRelAngle) into R0
	MOV		R2, R0		;Move relAngle in R2
	MOVS 	R0, R2 		;R0 = R2, setting flags.
	IT 		MI 			;IT instruction for the negative condition.
	RSBMI 	R0, R2, #0 	;If negative, R0 = -R2.

relStepsCalc:
	PUSH	{LR}	;Call Degree2Step
	BL		Degree2Step	;(ARGS: R0 = degree)
	POP		{LR}	;Loads R0 with the step equivalent of the degree
;This means the positive relAngle now contains the corresponding number of steps to queue up
;													R0=relSteps****

	MOVA	R3, steps	;Load R2 with the number of motor queue steps*****
	LDR		R2, [R3]

relStepsTest:
	CMP		R0, R2	;Test if relSteps >= motor queue steps
	BGE		NoDirFlip_DirTest	;If relSteps >= steps, do a direction test with the condition that direction flipping is impossible,
	;BLT	MaybeDirFlip_DirTest	;If not, do a direction test with the condition that direction flipping is possible

NoDirFlip_DirTest:
	MOVA	R4, dir	;Load R3 with step direction
	LDR		R3, [R4]

	MOV32	R4, CCW	;Test if direction is counterclockwise
	CMP		R3, R4
	BEQ		CCW_AngleTest1	;If dir == CCW, do an angle test with the condition that the direction is CCW
	;BNE	CW_AngleTest1	;If not, do an angle test with the condition that the direction is CW

CW_AngleTest1:
;Remember that R1 has a copy of relAngle
	MOV32	R3, ZERO_START	;Test if relAngle is zero or positive
	CMP		R1, R3
	BGE		AddRel	;If relAngle >= 0, add relative steps
	;BLT	SubRel	;If not, subtract relative steps

SubRel:
	SUB		R2, R0		;Subtract relative steps from steps and save
	MOVA	R3, steps
	STR		R2, [R3]

	B		ENDSetRelAngle	;End setting relative angle

CCW_AngleTest1:
;Remember that R1 has a copy of relAngle
	MOV32	R3, ZERO_START	;Test if relAngle is zero or positive
	CMP		R1, R3
	BGE		SubRel	;If relAngle >= 0, subtract relative steps
	;BLT	AddRel	;If not, add relative steps

AddRel:
	ADD		R2, R0		;Add relative steps from steps and save
	MOVA	R3, steps
	STR		R2, [R3]

	B		ENDSetRelAngle	;End setting relative angle

MaybeDirFlip_DirTest:
	MOVA	R4, dir	;Load R3 with step direction
	LDR		R3, [R4]

	MOV32	R4, CW	;Test if direction is counterclockwise
	CMP		R3, R4
	BEQ		CW_AngleTest2	;If dir == CW, do an angle test with the condition that the direction is CW
	;BNE	CCW_AngleTest2	;If not, do an angle test with the condition that the direction is CCW

CCW_AngleTest2:
;Remember that R1 has a copy of relAngle
	MOV32	R4, ZERO_START	;Test if relAngle is negative
	CMP		R1, R4
	BLT		AddRel		;If relAngle < 0, add relative steps
	;BGE	SetCW_RSmS	;If not, change dir to CW and subtract steps from relative steps

SetCW_RSmS:
	MOV32	R4, CW	;Set dir to CW
	MOVA	R3, dir
	STR		R4, [R3]

;Remember R0 has relSteps and R2 has value of steps
	SUB		R0, R2	;Calculate relSteps-steps
	MOVA	R3, steps	;Set steps to relSteps-steps and save
	STR		R0, [R3]

	B		ENDSetRelAngle	;End setting relative angle

CW_AngleTest2:
;Remember that R1 has a copy of relAngle
	MOV32	R3, ZERO_START	;Test if relAngle is zero or positive
	CMP		R1, R3
	BGE		AddRel	;If relAngle >= 0, add relative steps
	;BLT	RSmSTest	;If not, test relSteps-steps

RSmSTest:
;Remember R2 has value of steps
	SUB		R0, R2	;Calculate relSteps-steps
	MOV32	R4, ZERO_START	;Test if relSteps-steps is zero
	CMP		R0, R4
	BEQ		Steps0	;If relSteps-steps == 0, set steps to zero
	;BNE	SetCCW_RSmS	;If not, change dir to CCW and subtract steps from relative steps

SetCCW_RSmS:
	MOV32	R4, CCW		;Set dir to CCW
	MOVA	R3, dir
	STR		R4, [R3]

;Remember R0 has relSteps and R2 has value of steps
	SUB		R0, R2	;Calculate relSteps-steps
	MOVA	R3, steps	;Set steps to relSteps-steps and save
	STR		R0, [R3]

	B		ENDSetRelAngle	;End setting relative angle

Steps0:
	MOV32	R4, ZERO_START	;Set steps to 0 and save
	MOVA	R3, steps
	STR		R0, [R3]

	;B		ENDSetRelAngle	;End setting relative angle

ENDSetRelAngle:
	CPSIE	I	;Enable interrupts again
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
;	return
HomeStepper:
	PUSH    {R0, R1, R2, R3, R4}	;Push registers

	CPSID	I	;Disable interrupts to avoid critical code

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

	B		ENDHomeStepper	;End setting step home

HomeCW:
;Remember R0 has the number of steps to go home CCW
	MOV32	R1, FROT_STEPS	;Calculate fullRotSteps- CCW dir home steps
	SUB		R1, R0

	MOVA	R0, steps	;Set steps to fullRotSteps-CCWdirHomesteps and save
	STR		R1, [R0]

	MOV32	R0, CW	;Set dir to CW
	MOVA	R1, dir
	STR		R0, [R1]

	;B		ENDHomeStepper	;End setting step home

ENDHomeStepper:
	CPSIE	I	;Enable interrupts again
	POP    	{R0, R1}	;Pop registers
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
;		R0 = pos
;		return R0
GetAngle:
	PUSH    {R1}	;Push register

	MOVA	R1, pos
	LDR		R0, [R1]

EndGetAngle:
	POP    	{R1}	;Pop registers
	BX		LR			;Return
