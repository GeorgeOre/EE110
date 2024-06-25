;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																			   ;
;							Stepper Control Functions						   ;
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
	.include "GPT.inc"			;contains GPT control constants
	.include "GPIO.inc"			;contains GPIO control constants
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;							Required Functions
	.ref	D2STable		;	To wait
	.ref	SetPWM		;	To wait
	.ref	Wait_1ms	;	To wait
	.ref	PWMCosMinReq
	.ref	EndPWMCosMinReq
	.ref	PWMSinMinReq
	.ref	EndPWMSinMinReq
	.global steps
	.global dir
	.global pos
	.global curStep
	.global pwm1_step
	.global pwm2_step
	.global pwm_stat1
	.global pwm_stat2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;							Table of Contents
;		Function Name		|	Purpose
	.def	StepperStep		;	Step one degree in PWM
	.def	Degree2Step		;	To wait
	.def	InLimTest		;	To wait
	.def 	UpdateDirection
	.def 	UpdateSteps
	.def 	FullStep
	.def 	MinStep
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Revision History:	02/04/24	George Ore	Created format
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;*******************************************************************************
;*									FUNCTIONS								   *
;*******************************************************************************

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; StepperStep:
;
; Description:	Steps the one unit in the PWM domain
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
; Known Bugs:        None.
;
; Limitations:       None.
;
; Revision History:  12/07/24	George Ore	 Created
;					 12/08/24	George Ore	 Formated, moved to HW5
;					 01/02/24	George Ore	 Made interrupt driven to fix
;											 Skipping error and moved to HW4
;					 01/10/24	George Ore	 Moved to 110b HW1
;
; Pseudo Code
;
;	while(counter!=0)
;		reset 1msTimer
;		while(1msTimerTimeoutInterrupt!=Set)
;			NOP
;		counter--
;	return
StepperStep:	; R0 - direction to step
	PUSH    {R0, R1, R2, R3, R4}	;Push registers

; R0-R2: function params
; R6: variable working register

; Fetch current step params
	; R3: direction offset
	MOV 	R3, R0
	; R4: pwm1_step
	MOVA	R6, pwm1_step
	LDR 	R4, [R6]
	; R5: pwm2_step
	MOVA	R6, pwm2_step
	LDR 	R4, [R6]

; Based on the desired direction to step update params
	; Set some offset variable that can be added (1 for CW and -1 for CCW maybe)

; If direction is CW
StepDirectionCheck:
	SUB R3, #CW
	CBZ R3, SetCCWStepOffset


SetCWStepOffset:
	; Set R3 var with the CW offset
	MOV32 R3, 1
	; Set a var with the CW edge for comparison
	B StepEdgeCheck

; Else if direction is CCW
SetCCWStepOffset:
	; Set R3 var with the CCW offset
	MOV32 R3, -1
	; Set R3 var with the CCW edge for comparison
	B StepEdgeCheck
; Check if the step is at the edge
StepEdgeCheck:
	; If it is, loop around

	; If not, just add the direction offset to step params

; Use updated params to step by changing the PWM value
	LDR		R0, [R3], #4	; match time
	LDR		R1, [R3], #4	; prescale
	LDR		R2, [R3], #4	; which timer

    PUSH    {LR}    ; Call LowestLevelRead
	BL	SetPWM	;(ARGS: R0 = TAMATCHR, R1 = TAMPR, R2 = Base address)
    POP     {LR}    ; Will read into R0

End_StepperStep:
	POP    	{R0, R1, R2, R3, R4}	;Pop registers
	BX		LR			;Return


; Degree2Step:
;
; Description:	The function is passed the position in degrees (pos) to which to
;				set the Stepper. The position (pos) is passed in R0 by value. It
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
; Revision History:  12/30/24	George Ore	 created
;					 12/31/24	George Ore	 added first code
;					 12/30/24	George Ore	 created
;					 12/30/24	George Ore	 created
;
; Pseudo Code
;
;	(ARGS: R0 = degree)
;	R0 = Degree2StepTable(degree)
;	Return
Degree2Step:
	PUSH    {R1}	;Push registers

	MOVA	R1,	D2STable	;Load base address of degree to step table

	ADD		R1, R0		;Use degree as an address offset

	LDR		R0, [R1]	;Load R0 with corresponding step value

EndDegree2Step:
	POP    	{R1}	;Pop registers
	BX		LR			;Return

; InLimTest:
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
; Registers Changed: R0
; Stack Depth:       1 word
;
; Algorithms:        None.
; Data Structures:   None.
;
; Revision History:  12/30/24	George Ore	 created
; Revision History:  12/31/24	George Ore	 fixed
;
; Pseudo Code
;
;	(ARGS: R0 = Input, R1 = MaxInput, R2 = MinInput)
;	if MaxInput<Input<MinInput
;		R0 = InvalidInput
;	return
;
;ValidateInput(input, min, max)
;	- Return INVALID_INPUT(-1) if not valid
;		- Maybe set the zero flag, this would make checking after easier
;	- Return the input (aka do nothing kinda) if valid
;	- MUST CHECK AFTER THIS IS CALLED
;
InLimTest:
	PUSH    {R1}	;Push registers

MaxInputTest:
	CMP		R0, R1		;Compare angle with max
	BGT		InvalidInput	;If larger than max, handle invalid angle
	;BLE	MinInputTest	;If not test min

MinInputTest:
	CMP		R0, R2		;Compare angle with min
	BGE		EndInLimTest	;If >= to min, simply return
	;BGT	InvalidInput	;If not, handle invalid angle

InvalidInput:	;Handling an error modifies R0
	MOV32	R0, INVALIDINPUT	;Set R0 to invalid and return

EndInLimTest:
	POP    	{R1}	;Pop registers
	BX		LR			;Return

; UpdateDirection(input):
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
; Registers Changed: R0
; Stack Depth:       1 word
;
; Algorithms:        None.
; Data Structures:   None.
;
; Revision History:  12/30/24	George Ore	 created
; Revision History:  12/31/24	George Ore	 fixed
;
; Pseudo Code
;
;	(ARGS: R0 = directional input)
;	- Takes in an input
;		- If it is negative, go set dir CCW
;			- Else set it CW
;	- Doesn’t return anything
;	- ASSUMES THAT INTERRUPTS ARE ALREADY PAUSED
;
;	return
;
UpdateDirection:
	PUSH    {R0, R1}	;Push registers

	MOV32 R1, 0	;Test if the input was negative
	CMP	  R0, R1
	BLT		UpdateDirCCW	;If negative, set dir to CCW
	;BGE	UpdateDirCW		;If not, set dir to CW

UpdateDirCW:
	MOV32	R0, CW
	MOVA	R1, dir
;THIS CODE ASSUMES THAT THE INTERRUPTS HAVE ALREADY BEEN PAUSED
;	CPSID	I	;Disable interrupts to avoid critical code
	STR		R0,	[R1]
;	CPSIE	I	;Enable interrupts again

	B		EndUpdateDirection

UpdateDirCCW:
	MOV32	R0, CCW
	MOVA	R1, dir
;THIS CODE ASSUMES THAT THE INTERRUPTS HAVE ALREADY BEEN PAUSED
;	CPSID	I	;Disable interrupts to avoid critical code
	STR		R0,	[R1]
;	CPSIE	I	;Enable interrupts again

	;B		EndUpdateDirection

EndUpdateDirection:
	POP    	{R0, R1}	;Pop registers
	BX		LR			;Return

; UpdateSteps(steps):
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
; Registers Changed: R0
; Stack Depth:       1 word
;
; Algorithms:        None.
; Data Structures:   None.
;
; Revision History:  12/30/24	George Ore	 created
; Revision History:  12/31/24	George Ore	 fixed
;
; Pseudo Code
;
;	(ARGS: R0 = signed steps to take)
;	- Take in the amount of steps in signed integer form
;		- If it was negative, hit that yummy little 2s compliment
;		- Set that as the new amount of steps to take
;	- Doesn’t return anything
;	- ASSUMES THAT INTERRUPTS ARE ALREADY PAUSED
;
;
;	return
;
UpdateSteps:
	PUSH    {R0, R1}	;Push registers

	MOV32 R1, 0	;Test if the steps input was negative
	CMP	  R0, R1
	BLT	HandleNegativeSteps	;If negative, jump to negative handler
	B	HandleUpdateSteps	;If not, update steps

HandleNegativeSteps:
;    RSBS R0, R0, #0	; Take two's complement to get positive equivalent

;	PUSH {LR}
;	BL	SWITCHFULLSTEPDIRECTION
;	POP {LR}

	ADD	R0, R0, #360	;Add 360 to turn it positive

	;B	HandleUpdateSteps

HandleUpdateSteps:

;THIS CODE ASSUMES THAT THE INTERRUPTS HAVE ALREADY BEEN PAUSED
;	CPSID	I	;Disable interrupts to avoid critical code

	MOV32 R1, 18
	SDIV	R0, R0, R1

	MOVA	R1, steps
	STR		R0,	[R1]
;	CPSIE	I	;Enable interrupts again

	;B		EndUpdateSteps

EndUpdateSteps:
	POP    	{R0, R1}	;Pop registers
	BX		LR			;Return


; FullStep
; This function will excecute a full step
;It assumes GPT1 is off
;Order: ++, +-, --, -+, ++
FullStep:
	PUSH    {R0, R1}	;Push registers

;Check pwm_stat1 as a status var
	MOVA	R1, pwm_stat1
	LDR 	R0, [R1]

	CMP	R0, #FULLSTEP4
	BEQ		SetFullStep4
	CMP	R0, #FULLSTEP3
	BEQ		SetFullStep3
	CMP	R0, #FULLSTEP2
	BEQ		SetFullStep2
	CMP	R0, #FULLSTEP1
	BEQ		SetFullStep1
	B	EndFullStep

SetFullStep1:
	MOV32 R1, GPIO	;Toggle step 1
	STREG FULLSTEP2, R1, DTGL31_0

	MOV32	R0, FULLSTEP2	;Exchange step var
	MOVA	R1, pwm_stat1
	STR		R0, [R1]
	B EndFullStep

SetFullStep2:
	MOV32 R1, GPIO	;Toggle step 2
	STREG FULLSTEP3, R1, DTGL31_0

	MOV32	R0, FULLSTEP2	;Exchange step var
	MOVA	R1, pwm_stat1
	STR		R0, [R1]
	B EndFullStep

SetFullStep3:
	MOV32 R1, GPIO	;Toggle step 2
	STREG FULLSTEP3, R1, DTGL31_0

	MOV32	R0, FULLSTEP4	;Exchange step var
	MOVA	R1, pwm_stat1
	STR		R0, [R1]
	B EndFullStep

SetFullStep4:
	MOV32 R1, GPIO	;Toggle step 2
	STREG FULLSTEP4, R1, DTGL31_0

	MOV32	R0, FULLSTEP1	;Exchange step var
	MOVA	R1, pwm_stat1
	STR		R0, [R1]
	B EndFullStep

EndFullStep:
;	MOV32	R0, 30	;Wait 30 ms
;	PUSH {LR}
;	BL	Wait_1ms
;	POP  {LR}

	POP    	{R0, R1}	;Pop registers
	BX		LR			;Return



	MOV32 R1, GPIO
	STREG FULLSTEP1, R1, DTGL31_0

	MOV32	R0, 30
	PUSH {LR}
	BL	Wait_1ms
	POP  {LR}

	MOV32 R1, GPIO
	STREG FULLSTEP2, R1, DTGL31_0

	MOV32	R0, 30
	PUSH {LR}
	BL	Wait_1ms
	POP  {LR}

	MOV32 R1, GPIO
	STREG FULLSTEP3, R1, DTGL31_0

	MOV32	R0, 30
	PUSH {LR}
	BL	Wait_1ms
	POP  {LR}

	MOV32 R1, GPIO
	STREG FULLSTEP4, R1, DTGL31_0

	MOV32	R0, 30
	PUSH {LR}
	BL	Wait_1ms
	POP  {LR}


;++
	MOV32	R0, 0x0000BB71	;Set the PWM match value from the table
	MOV32	R1, 0	;Set the prescale value to 0
	MOV32	R2, GPT2	;Set the address to PWM timer 1
	PUSH {LR}
	BL	SetPWM
	POP  {LR}

	MOV32	R0, 0x0000BB71	;Set the PWM match value from the table
	;MOV32	R1, 0	;Set the prescale value to 0
	MOV32	R2, GPT3	;Set the address to PWM timer 2
	PUSH {LR}
	BL	SetPWM
	POP  {LR}

	MOV32	R0, 1000	;Set the address to PWM timer 2
	PUSH {LR}
	BL	Wait_1ms
	POP  {LR}

;+-
	MOV32	R0, 0x0000BB71	;Set the PWM match value from the table
	MOV32	R1, 0	;Set the prescale value to 0
	MOV32	R2, GPT2	;Set the address to PWM timer 1
	PUSH {LR}
	BL	SetPWM
	POP  {LR}

	MOV32	R0, 0x0000000E	;Set the PWM match value from the table
	;MOV32	R1, 0	;Set the prescale value to 0
	MOV32	R2, GPT3	;Set the address to PWM timer 2
	PUSH {LR}
	BL	SetPWM
	POP  {LR}

	MOV32	R0, 1000	;Set the address to PWM timer 2
	PUSH {LR}
	BL	Wait_1ms
	POP  {LR}

;--
	MOV32	R0, 0x0000000E	;Set the PWM match value from the table
	MOV32	R1, 0	;Set the prescale value to 0
	MOV32	R2, GPT2	;Set the address to PWM timer 1
	PUSH {LR}
	BL	SetPWM
	POP  {LR}

	MOV32	R0, 0x0000000E	;Set the PWM match value from the table
	;MOV32	R1, 0	;Set the prescale value to 0
	MOV32	R2, GPT3	;Set the address to PWM timer 2
	PUSH {LR}
	BL	SetPWM
	POP  {LR}

	MOV32	R0, 1000	;Set the address to PWM timer 2
	PUSH {LR}
	BL	Wait_1ms
	POP  {LR}

;-+
	MOV32	R0, 0x0000000E	;Set the PWM match value from the table
	MOV32	R1, 0	;Set the prescale value to 0
	MOV32	R2, GPT2	;Set the address to PWM timer 1
	PUSH {LR}
	BL	SetPWM
	POP  {LR}

	MOV32	R0, 0x0000BB71	;Set the PWM match value from the table
	;MOV32	R1, 0	;Set the prescale value to 0
	MOV32	R2, GPT3	;Set the address to PWM timer 2
	PUSH {LR}
	BL	SetPWM
	POP  {LR}

	MOV32	R0, 1000	;Set the address to PWM timer 2
	PUSH {LR}
	BL	Wait_1ms
	POP  {LR}

;++
	MOV32	R0, 0x0000BB71	;Set the PWM match value from the table
	MOV32	R1, 0	;Set the prescale value to 0
	MOV32	R2, GPT2	;Set the address to PWM timer 1
	PUSH {LR}
	BL	SetPWM
	POP  {LR}

	MOV32	R0, 0x0000BB71	;Set the PWM match value from the table
	;MOV32	R1, 0	;Set the prescale value to 0
	MOV32	R2, GPT3	;Set the address to PWM timer 2
	PUSH {LR}
	BL	SetPWM
	POP  {LR}




SWITCHFULLSTEPDIRECTION:
	PUSH    {R0, R1}	;Push registers

;Check pwm_stat1 as a status var
	MOVA	R1, pwm_stat1
	LDR 	R0, [R1]

GPIOSwitchStep:
	CMP	R0, #FULLSTEP4
	BEQ		SwitchFullStep4
	CMP	R0, #FULLSTEP3
	BEQ		SwitchFullStep3
	CMP	R0, #FULLSTEP2
	BEQ		SwitchFullStep2
	CMP	R0, #FULLSTEP1
	BEQ		SwitchFullStep1
	B	EndFullStep

SwitchFullStep1:
	MOV32 R1, GPIO	;Toggle step 1
	STREG FULLSTEP2, R1, DTGL31_0

	MOV32	R0, FULLSTEP4	;Exchange step var
	MOVA	R1, pwm_stat1
	STR		R0, [R1]
	B EndFullStep

SwitchFullStep2:
	MOV32 R1, GPIO	;Toggle step 2
	STREG FULLSTEP3, R1, DTGL31_0

	MOV32	R0, FULLSTEP1	;Exchange step var
	MOVA	R1, pwm_stat1
	STR		R0, [R1]
	B EndFullStep

SwitchFullStep3:
	MOV32 R1, GPIO	;Toggle step 2
	STREG FULLSTEP3, R1, DTGL31_0

	MOV32	R0, FULLSTEP2	;Exchange step var
	MOVA	R1, pwm_stat1
	STR		R0, [R1]
	B EndFullStep

SwitchFullStep4:
	MOV32 R1, GPIO	;Toggle step 2
	STREG FULLSTEP4, R1, DTGL31_0

	MOV32	R0, FULLSTEP3	;Exchange step var
	MOVA	R1, pwm_stat1
	STR		R0, [R1]
	;B SWITCHFULLSTEPDIRECTION


EndSWITCHFULLSTEPDIRECTION:
;	MOV32	R0, 30	;Wait 30 ms
;	PUSH {LR}
;	BL	Wait_1ms
;	POP  {LR}

	POP    	{R0, R1}	;Pop registers
	BX		LR			;Return




;Takes the minimum amount to step and just does it
MinStep:	; R0 = Direction to step in
	PUSH   	{R0, R1, R2, R3}	;Push registers

;Check what direction to step in
	MOV32	R1, CW
	CMP		R0, R1
	BNE	MinStepCCW
	;BEQ	MinStepCW

;Prep step in that direction
MinStepCW:
	;Fetch curStep
	MOVA	R1, curStep
	LDR		R0,	[R1]

;Update current step
	ADD		R0, R0, #1

	;Handle wrapping
CWWrapTest:
	MOV32 R1, STEP_OVERFLOW
	CMP	R0, R1
	BLT	DoMinStep
	;BGE CWWrap

CWWrap:
	MOV32 R0, 0
	B DoMinStep

MinStepCCW:
	;Fetch curStep
	MOVA	R1, curStep
	LDR		R0,	[R1]

;Update current step
	SUB		R0, R0, #1

	;Handle wrapping
CCWWrapTest:
	MOV32 R1, 0
	CMP	R0, R0
	BGE	DoMinStep
	;BLT CCWWrap

CCWWrap:
	MOV32 R0, STEP_WRAP
	;B DoMinStep

DoMinStep:
	;Save curStep
	MOVA	R1, curStep
	STR		R0, [R1]

;Save the pos angle
	MOVA	R1, pos
	MOV32	R2, 0
	MOV32	R3, 0
PosCalcLoop:
	CMP	R0, R3
	BLE	SaveNewPos
	SUB	R0, R0, #1
	ADD	R2, R2, #6
	B	PosCalcLoop

SaveNewPos:
	STR R2, [R1]
	;B	SetMinStepPWM

SetMinStepPWM:
;Mod the actual PWM values now
	MOVA	R1, curStep
	LDR	R0, [R1]
	LSL	R0, #2	;Multiply by 4 for word addressing

	PUSH {R0}

	MOVA R1, PWMCosMinReq
	LDR	 R0, [R1, R0]	;Set the PWM match value from the table
	MOV32	R1, 0	;Set the prescale value to 0
	MOV32	R2, GPT2	;Set the address to PWM timer 1
	PUSH {LR}
	BL	SetPWM
	POP  {LR}

	POP {R0}

	MOVA R1, PWMSinMinReq
	LDR	 R0, [R1, R0]	;Set the PWM match value from the table
	MOV32	R1, 0	;Set the prescale value to 0
	MOV32	R2, GPT3	;Set the address to PWM timer 1
	PUSH {LR}
	BL	SetPWM
	POP  {LR}

;Wait a bit (blocking)
	MOV32	R0, 500	;Set the address to PWM timer 2
;	MOV32	R0, 30	;Set the address to PWM timer 2
	PUSH {LR}
	BL	Wait_1ms
	POP  {LR}

EndMinStep:
	POP    	{R0, R1, R2, R3}	;Pop registers
	BX		LR			;Return
.end
