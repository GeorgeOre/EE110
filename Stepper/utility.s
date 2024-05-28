;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																			   ;
;								Utility Functions							   ;
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;							Required Functions
	.ref	D2STable		;	To wait
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;							Table of Contents
;		Function Name		|	Purpose
	.def	Wait_1ms		;	To wait
	.def	Degree2Step		;	To wait
	.def	InLimTest		;	To wait
	.def	DisplayStepper	;	To wait
	.def	SetPWM			;	To wait
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Revision History:	02/04/24	George Ore	Created format
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;*******************************************************************************
;*									FUNCTIONS								   *
;*******************************************************************************

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
Wait_1ms:
	PUSH    {R0, R1, R2, R3, R4}	;Push registers

	MOV		R1, R0		;Relocate amount of ms into R1
	MOV32	R2, GPT0	;Load GPT0 base address
	MOV32	R3, COUNT_DONE	;Load ms count done condition
	MOV32	R4, IRQ_TATO	;Load timeout interrupt condition

W_1ms_Cntr_Loop:
	CMP		R1, R3			;Check if the ms counter is done
	BEQ		End_1ms_Wait	;If it is, end wait
	;BNE	Reset_1ms_Timer	;if not reset the 1ms timer

Reset_1ms_Timer:
	STREG   CTL_TA_STALL, R2, CTL	;Enable timer with debug stall

W_1ms_Timr_Loop:
	LDR		R0, [R2, #MIS]	;Get the masked interrupt status
	CMP		R0, R4			;Check if timeout interrupt has happened
	BNE		W_1ms_Timr_Loop	;If 1ms hasn't passed, wait
	;BEQ	DecCounter		;If 1ms passed, decrement the cntr

DecCounter:
	STREG   IRQ_TATO, R2, ICLR  	;Clear timer A timeout interrupt
	SUB		R1, #ONE	;Decrement the counter and go back to
	B		W_1ms_Cntr_Loop	;counter value check

End_1ms_Wait:
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

ENDDegree2Step:
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
InLimTest:
	PUSH    {R1}	;Push registers

MaxInputTest:
	CMP		R0, R1		;Compare angle with max
	BGT		InvalidInput	;If larger than max, handle invalid angle
	;BLE	MinInputTest	;If not test min

MinInputTest:
	CMP		R0, R2		;Compare angle with min
	BGE		ENDInLimTest	;If >= to min, simply return
	;BGT	InvalidInput	;If not, handle invalid angle

InvalidInput:	;Handling an error modifies R0
	MOV32	R0, INVALIDINPUT	;Set R0 to invalid and return

ENDInLimTest:
	POP    	{R1}	;Pop registers
	BX		LR			;Return

; DisplayStepper:
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
DisplayStepper:
	PUSH    {R0, R1, R2, R3}	;Push registers

	MOV32	R2, GPT0		;Load base address

	MOV32	R3, TAMATCHR	;Load match reg offset address
	STR   	R0, [R2, R3] 	;Set timer match duration

	MOV32	R3, TAPMR		;Load prescale reg offset address
	STR   	R1, [R2, R3]	;Set match prescaler

ENDDisplayStepper:
	POP    	{R0, R1, R2, R3}	;Pop registers
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
;	(ARGS: R0 = TAMATCHR, R1 = TAPMR, R2 = Base address)
;	TAMATCHR  = R0
;	TAPMR	  = R1
;	return
SetPWM:
	PUSH    {R0, R1, R2, R3}	;Push registers

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
