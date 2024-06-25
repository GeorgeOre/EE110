;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																			   ;
;								Handler Functions							   ;
;									George Ore								   ;
;																			   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description:	This file includes general utility functions.
;
; Goal:			The goal of these functions is to have quality of life uses
;				that can be applied in a wide range of applications.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;							Required Constant Files
	.include "constants.inc"	;contains misc. constants
	.include "macros.inc"		;contains all macros
	.include "GPIO.inc"			;contains GPIO control constants
	.include "GPT.inc"			;contains GPT control constants
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;							Required Functions
	.ref	D2STable		;	To wait
	.ref MotorStepTable
	.ref PWM1kHzSinTable
	.ref PWM1kHzCosTable
	.ref PWM20kHzSinTable
	.ref PWM20kHzCosTable
	.ref PWM25kHzSinTable
	.ref PWM25kHzCosTable
	.ref SetPWM
	.ref FullStep
	.global pwm_stat1
	.global pwm_stat2
	.global steps
	.global dir
	.global pos
	.global curStep
	.global pwm1_step
	.global pwm2_step
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;							Table of Contents
;		Function Name			|	Purpose
	.def	GPT1EventHandler	;	Step one degree in PWM
	.def	GPT2EventHandler	;	To wait
	.def	GPT3EventHandler	;	To wait
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Revision History:	02/04/24	George Ore	Created format
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;*******************************************************************************
;*									FUNCTIONS								   *
;*******************************************************************************
; GPT1EventHandler:
;
; Description:	This procedure is called through the GPT1 vector table
;		  		interupt. It happens when the PWM signal changes state.
;
; Operation:	Toggles GPIO 18 output when PWM changes state.
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
; Output:           GPIO 18 output state
;
; Error Handling:   Assumes that GPIO 18 is already in the correct state
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
;	*This interrupt is triggered every 50ms by the GPT1A timeout interrupt*
;	if steps>0
;		stepmotor()
;		update angle
;		update steps
;	return
;
;stepmotor method 1: just microstep the whole way
;	steps =- 1
;	if dir = CW
;		if curStep!=MAXSTEP
;			curStep	= curStep+1
;		else (curStep==MAXSTEP)
;			curStep	= MINSTEP
;		if pos != MAXPOS
;			pos = pos+DPOS
;		else (pos == MAXPOS)
;			pos = MINPOS
;	else (dir = CCW)
;		if curStep!=MINSTEP
;			curStep	= curStep-1
;		else (curStep==MINSTEP)
;			curStep	= MAXSTEP
;		if pos != MINPOS
;			pos = pos-DPOS
;		else (pos == MINPOS)
;			pos = MAXPOS
;	motorout = StepTable(curStep)
;
;curStep will be a value 0-60 which will index a step table:
;
;
;stepmotor method 2: calculate largest step you can take and excecute it
;	if steps<3
;		Do a microstep
;		pos +/- microstepangle with wrapping
;		steps =- 1
;	elseif steps<6
;		Do a half step
;		pos +/- halfstepangle with wrapping
;		steps =- 3
;	else (steps>=6)
;		Do a full step
;		pos +/- fullstepangle with wrapping
;		steps =- 6
;
;FOR NOW SO I CAN DO CALIBRATIONS IN LAB
;
;	if steps>0
;		steps =- 1
;		if dir = CW
;			if curStep!=MAXSTEP
;				curStep	= curStep+1
;			else (curStep==MAXSTEP)
;				curStep	= MINSTEP
;			if pos != MAXPOS
;				pos = pos+DPOS
;			else (pos == MAXPOS)
;				pos = MINPOS
;		else (dir = CCW)
;			if curStep!=MINPOS
;				curStep	= curStep-1
;			else (curStep==MINSTEP)
;				curStep	= MAXSTEP
;			if pos != MINPOS
;				pos = angle-DPOS
;			else (pos == MINPOS)
;				pos = MAXPOS
;		motorout = StepTable(curStep)
;	return
;curStep will be a value 0-20 which will index a step table:
;
;	- Periodic step timer
;		- Every time it interrupts it steps
;	- Steps once every 50ms
;	- Checks how many steps are left
;		- If 0, return and don’t do anything
;		- Else go on to next step
;	- Prepare to step
;		- Fetch stepping tables
;			- Cos table
;				- For PWM 1/2
;			- Sin table
;				- For PWM 2/1
;		- Fetch the "curstep" variable
;			- This is used to index the tables
;			- Load up a register with the current data table address
;	- Checks direction to step in
;		UpdateDirection
;		- If CW add/subtract from the address
;			- While you are add it inc/dec "steps"
;			- Perchance also update "pos" and "curstep"
;		UpdateSteps
;		- Else if CCW subtract/add from the address
;			- While you are add it inc/dec "steps"
;			- Maybe if 0 also update CCW to CW??
;			- Perchance also update "pos" and "curstep"
;	- Set the PWMs
;		- Use the address to set new PWMS
;			- Cos
;			- Sin
;	- Update pos
;		- Maybe use a table
;		- For now make it the same as
;	- THIS TOUCHES "curstep", "dir", "pos", AND "steps"
;		- WRITES TO ALL OF THEM EXCEPT MAYBE DIR WE WILL SEE LATER
;		- IMPORTANT FOR CRITICAL CODE
;
GPT1EventHandler:
	PUSH    {R0, R1, R2}	;R0-R3 are autosaved
	PUSH    {R3, R4}			;Push used register

	MOVA	R2, steps	;Load the motor step queue in R0
	LDR		R0, [R2]
	;B		StepsDoneTest	;Begin motor step queue test

StepsDoneTest:
	MOV32	R1, COUNT_DONE	;Test if steps are done excecuting
	CMP		R0, R1
	BEQ		EndGPT1EventHandler	;If no steps are left, end interrupt
	;BNE	HandleStep	;If there are nonzero steps, handle a step

HandleStep:
	MOVA	R2, dir		;Fetch the stepping direction
	LDR		R1, [R2]

	MOV32	R2, CW	;Test for CW or CCW cases
	CMP		R1, R2
	BNE		HandleCCWStep	;If CCW, go to CCW handler
	;BEQ	HandleCWStep	;If CW, continue into CW handler

HandleCWStep:
	SUB		R0, R0, #ONE	;Increment and save step queue var
	MOVA	R2, steps
	STR		R0, [R2]

	;Update curStep
	MOVA	R1, curStep
	LDR		R0, [R1]
	ADD		R0, R0, #ONE
	MOV32	R2, STEP_OVERFLOW
	CMP		R0, R2
	BLT		CurStepUpdated
	;BGE	StepOverflowed

;StepOverflowed:
	MOV32	R2, ZERO_START	;Wrap curStep if overflowed
	STR		R2, [R1]
;pos is the same as curStep but multiplied by MAX_STEPS
	MOV32	R3, MAXSTEP
	MUL		R2, R2, R3
	MOVA	R1, pos
	STR	R2, [R1]

;	MOV32	R0, -359*4	;Get the offset ready to wrap
	B	UpdateStep

CurStepUpdated:
	STR	R0, [R1]
;pos is the same as curStep but multiplied by MAX_STEPS
	MOV32	R2, SINGLE_STEP_ANGLE
	MUL		R0, R0, R2
	MOVA	R1, pos
	STR	R0, [R1]

;	MOV32	R0, STEPCW	;Set a CW step offset variable
	LSL	R0, #2	;Set a CW step offset variable
	;ADD R0, R0, #4

	B	UpdateStep

HandleCCWStep:
	SUB		R0, R0, #ONE	;Decrement and save step queue var
	MOVA	R2, steps
	STR		R0, [R2]

	;Update pos and curStep
	MOVA	R1, pos
	LDR		R0, [R1]
	SUB		R0, R0, #ONE
	MOV32	R2, POS_UNDERFLOW
	CMP		R0, R2
	BGE		CurStepUpdated2
	;BLT	PosUnderflowed

;PosUnderflowed:
	MOV32	R2, POS_WRAP	;Wrap pos if underflowed
	STR		R2, [R1]
;curStep is the same as pos so save that also
	MOVA	R1, curStep
	STR	R2, [R1]

	MOV32	R0, 359*4	;Get the offset ready to wrap
	B	UpdateStep

CurStepUpdated2:
	STR	R0, [R1]
;curStep is the same as pos so save that also
	MOVA	R1, curStep
	STR	R0, [R1]

;	MOV32	R0, STEPCCW	;Set a CCW step offset variable
	LSL	R0, #2	;Set a CW step offset variable
	;SUB R0, R0, #4


	;B	UpdateStep

UpdateStep:

	PUSH {LR}
	BL	FullStep

	POP  {LR}

EndGPT1EventHandler:
	MOV32 	R1, GPT1				;Load base into R1
	STREG   IRQ_TATO, R1, ICLR  	;Clear timer A timeout interrupt
	POP    {R3, R4}						;POP used register
	POP    {R0, R1, R2}			;R0-R2 are autorestored
	BX      LR                      ;return from interrupt


; GPT2EventHandler:
;
; Description:	This procedure is called through the GPT1 vector table
;		  		interupt. It happens when the PWM signal changes state.
;
; Operation:	Toggles GPIO 18 output when PWM changes state.
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
; Output:           GPIO 18 output state
;
; Error Handling:   Assumes that GPIO 18 is already in the correct state
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
;GPT2 handler
;	- Channel 1 PWM timer
;	- Only toggles the two channel 1 pwm pin
;		- Mods their variables but its not critical code
;			because this is the only place
;
GPT2EventHandler:
	;PUSH    {R0, R1, R2}	;R0-R3 are autosaved

	MOVA 	R0, pwm_stat1	;Load staus address
	LDR		R1, [R0]	;Fetch status
	CBZ		R1, PWMUpdate1	;Update if status is zero

	;If non zero, reset status to READY and end interrupt
	MOV32	R1, READY
	STR		R1, [R0]
	B EndGPT2EventHandler

PWMUpdate1:
	MOV32	R1, SET		;Update PWM status
	STR		R1, [R0]

	MOV32	R1, GPIO	;Load base address
	STREG	PWM_PIN1, R1, DTGL31_0	;Toggle PWM pin 1
	STREG	PWM_NPIN1, R1, DTGL31_0	;Toggle PWM not pin 1

EndGPT2EventHandler:
	MOV32 	R1, GPT2				;Load base into R1
	STREG   GPT_IRQ_CAE, R1, ICLR  	;Clear timer A capture event interrupt
	;POP    {R0, R1, R2}			;R0-R3 are autorestored
	BX      LR                      ;return from interrupt


; GPT3EventHandler:
;
; Description:	This procedure is called through the GPT1 vector table
;		  		interupt. It happens when the PWM signal changes state.
;
; Operation:	Toggles GPIO 18 output when PWM changes state.
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
; Output:           GPIO 18 output state
;
; Error Handling:   Assumes that GPIO 18 is already in the correct state
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
;GPT3 handler
;	- Channel 2 PWM timer
;	- Only toggles the two channel 2 pwm pin
;	- Mods their variables but its not critical code because
;		this is the only place
;
GPT3EventHandler:
	;PUSH    {R0, R1, R2}	;R0-R3 are autosaved

	MOVA 	R0, pwm_stat2	;Load staus address
	LDR		R1, [R0]	;Fetch status
	CBZ		R1, PWMUpdate2	;Update if status is zero

	;If non zero, reset status to READY and end interrupt
	MOV32	R1, READY
	STR		R1, [R0]
	B EndGPT3EventHandler

PWMUpdate2:
	MOV32	R1, SET		;Update PWM status
	STR		R1, [R0]

	MOV32	R1, GPIO	;Load base address
	STREG	PWM_PIN2, R1, DTGL31_0	;Toggle PWM pin 2
	STREG	PWM_NPIN2, R1, DTGL31_0	;Toggle PWM not pin 2

EndGPT3EventHandler:
	MOV32 	R1, GPT3				;Load base into R1
	STREG   GPT_IRQ_CAE, R1, ICLR  	;Clear timer A capture event interrupt
	;POP    {R0, R1, R2}			;R0-R3 are autorestored
	BX      LR                      ;return from interrupt
