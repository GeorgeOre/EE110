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
	.global steps
	.global dir
	.global pos
	.global curStep
	.global pwm1_step
	.global pwm2_step
	.global pwm_stat
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;							Table of Contents
;		Function Name			|	Purpose
	.def	GPT1EventHandler	;	Step one degree in PWM

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Revision History:	02/04/24	George Ore	Created format
;                   06/23/24 	George Ore  Refactored and turned in
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;*******************************************************************************
;*									FUNCTIONS								   *
;*******************************************************************************
; GPT1EventHandler:
;
; Description:	This procedure is called through the GPT1 vector table
;		  		interupt. It happens when the PWM signal changes state.
;
; Operation:	Toggles GPIO 30 output when PWM changes state.
; Arguments:        None.
; Return Values:    None.
;
; Local Variables:  None.
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

