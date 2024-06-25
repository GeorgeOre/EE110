;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																			   ;
;							EE110 HW4 George Ore							   ;
;																			   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
; Description:      This program configures the CC2652R LaunchPad to control a
;					stepper motor on the Glen George TM wire wrap board. It uses
;					table driven code to move the stepper and display the active
;					angles on an LCD. When the table is finished, the program
;					simply loops
;
; Operation:        The program loops through a testing data table stored in
;					memory to get the parameters of what angles to set.
;
; Arguments:        NA
;
; Return Values:    NA
;
; Local Variables:  NA
;
; Shared Variables: NA
;
; Global Variables: ResetISR (required)
;
; Input:            User must modify memory tables to control the motor
;
; Output:           Motor motion
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
; Limitations:       Unknown
;
; Revision History:   12/30/23  George Ore      initial version
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
;	MoveVecTable()
;	InstallGPT1Handler()
;	initGPTs()
;   initGPIO()
;
;	steps = 0
;	dir	= CW
;	pos = 0DEGREES
;	curStep = 0
;	initmotor(curstep)
;
;	while(1)
;		for (angle, iterations, msdelay) in TestStepper:
;		for (angle1, angle2, iterations, msdelay) in TestStepper:
;			SetAngle(angle1)
;			for i in range(iterations)
;				Wait_1ms(msdelay)
;			GetAngle()
;			for i in range(iterations)
;				Wait_1ms(msdelay)
;			DisplayStepper()
;			for i in range(iterations)
;				Wait_1ms(msdelay)
;			SetRelAngle(angle2)
;			for i in range(iterations)
;				Wait_1ms(msdelay)
;			GetAngle()
;			for i in range(iterations)
;				Wait_1ms(msdelay)
;			DisplayStepper()
;			for i in range(iterations)
;				Wait_1ms(msdelay)
;			HomeStepper()
;			for i in range(iterations)
;				Wait_1ms(msdelay)
;			GetAngle()
;			for i in range(iterations)
;				Wait_1ms(msdelay)
;			DisplayStepper()
;			for i in range(iterations)
;				Wait_1ms(msdelay)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Include constant, and macro files
	.include "configPWR&CLK.inc"	;contains power config constants
	.include "configGPIO.inc"	;contains GPIO config constants
	.include "GPIO.inc"			;contains GPIO control constants
	.include "GPT.inc"			;contains GPT control constants
	.include "constants.inc"	;contains misc. constants
	.include "timer.inc"	;contains misc. constants

	.include "macros.inc"		;contains all macros

;Reference initialization functions
	.ref	InitPower
	.ref	InitClocks
	.ref	InitGPIO
	.ref	InitGPTs
	.ref	MoveVecTable
	.ref	InstallGPTHandlers
	.ref	InitLCD
	.ref	PrepLCD

;Reference HW4 functions
	.ref	SetAngle	;	Set the stepper to a certain angle
	.ref	SetRelAngle	;	Set the stepper to an angle relative to cur pos
	.ref	HomeStepper	;	Set stepper back home
	.ref	GetAngle	;	Get the current angle of the stepper

;Reference utility functions
	.ref	Wait_1ms
	.ref	SetPWM
	.ref	DisplayStepper

;Reference SPI and serial functions
	.ref	SerialSendRdy

;Reference tables
	.ref	TestStepperTab
	.ref	EndTestStepperTab
	.ref	MotorStepTable
	.ref	EndMotorStepTable

	.ref 	FullStep
	.ref 	MinStep

;Define variables
	.def	steps
	.def	dir
	.def	pos
	.def	curStep

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

;;;;;;Install GPT Handlers;;;;;;
	BL	InstallGPTHandlers

;;;;;;Initalize GPIO;;;;;;
	BL	InitGPIO

;;;;;;Initalize GPTs;;;;;;
	BL	InitGPTs

;;;;;;Initalize LCD;;;;;;
	BL	InitLCD


;;;;;;Init Variable Values;;;;;;
InitVariables:
    CPSID   I   ;Disable interrupts to avoid critical code THIS MIGHT BE REMOVABLE

	MOVA    R1, pwm_stat1		;Set PWM 1 status READY
;	MOV32   R0, SET
	MOV32   R0, FULLSTEP1
	STR     R0, [R1]
	MOVA    R1, pwm_stat2		;Set PWM 2 status READY
	MOV32   R0, SET
	STR     R0, [R1]
	MOVA    R1, steps	;Set starting steps needed at 0
	MOV32   R0, ZERO_START
	STR     R0, [R1]
	MOVA    R1, dir		;Set starting direction clockwise
	MOV32   R0, CW
	STR     R0, [R1]
	MOVA    R1, pos		;Set starting position at 0
	MOV32   R0, ZERO_START
	STR     R0, [R1]
	MOVA    R1, curStep		;Set starting motor stepping index at 0
	MOV32   R0, ZERO_START
	STR     R0, [R1]

;;;;;;Init Register Values;;;;;;
;InitRegisters:
	MOV32	R1, GPIO		;Load base address
	;STREG   ALL_PINS, R1, DCLR31_0	;Clear all GPIO pins
	STREG   NOT_PINS, R1, DSET31_0	;Set inverted pins

    CPSIE   I   ;Enable interrupts again THIS MIGHT BE REMOVABLE

;;;;;;Enable PWM Clocks/Pins;;;;;;
	;GPT2 will be our motor channel A PWM microstep control timer
	MOV32	R1, GPT2				;Load base address
;	STREG   GPT_CTL_EN_TA_PWM_STALL, R1, CTL	;Enable timer A with debug stall

	;GPT3 will be our motor channel B PWM microstep control timer
	MOV32	R1, GPT3				;Load base address
;	STREG   GPT_CTL_EN_TA_PWM_STALL, R1, CTL	;Enable timer A with debug stall

;;;;;;Init Stepper State;;;;;;



;;;;;;Main Program;;;;;;


TestStepper: ;do the Stepper function tests
	MOVA 	R4, TestStepperTab ;start at the beginning of table

TestStepperLoop:
	LDRSH	R0, [R4], #2 	;get the SetStepper argument from table

;	CPSID	I	;Disable interrupts to avoid critical code
	BL 		SetAngle		;call the function
;	CPSIE	I	;Enable interrupts again

	LDRH 	R5, [R4], #2 	;get iterations from the table

TestGetStepperLoop: 			;loop testing GetStepper function
	BL 		GetAngle 		;call GetAngle
	BL		PrepLCD
	BL 		DisplayStepper 	;display GetStepper results
	LDRH 	R0, [R4] 		;get the time delay from the table
	BL 		Wait_1ms 		;delay amount specified
	SUBS 	R5, #1 			;update loop counter
	BNE 	TestGetStepperLoop	;loop specified number of times
	;BEQ 	CheckDoneTest 	;then check if tests done

CheckDoneTest: 				;check if tests done
	ADD		R4, #2			;get past delay entry in table
	MOVA 	R5, EndTestStepperTab	;check if at end of table
	SUB		R5, R5, #1
	CMP 	R4, R5
	BNE 	TestStepperLoop	;not done with tests, keep looping
	;BEQ 	DoneTestStepper 	;otherwise done testing the Stepper

DoneTestStepper: ;done testing Stepper

	BL		HomeStepper			;Set the stepper home at the end

HomeLoop:
	BL 		GetAngle 		;call GetAngle
	BL		PrepLCD
	BL 		DisplayStepper 	;display GetStepper results

	MOV32	R0, 30			;wait 30 ms to actually see the display
	BL 		Wait_1ms 		;delay amount specified
	B	HomeLoop

;*******************************************************************************
;USED FUNCTIONS
;*******************************************************************************





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																			   ;
; 							Data Section									   ;
;																			   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.data

	.global pwm_stat1
	.global pwm_stat2
	.global steps
	.global dir
	.global pos
	.global curStep
	.global pwm1_step
	.global pwm2_step

	.global cRow
	.global cCol
	.global charbuffer

	.global VecTable

;;;;;;Variable Declaration;;;;;;
	.align 4
pwm_stat1:	.space 4	;PWM 1 status variable

pwm_stat2:	.space 4	;PWM 2 status variable

steps:		.space 4	;2 byte (16 bit) unsigned value representing steps needed

dir:		.space 4	;1 byte (8 bit) value representing step direction

pos:		.space 4	;2 byte (16 bit) unsigned value representing position
						;in degrees
curStep:	.space 4	;2 byte (16 bit) unsigned value representing the current
						;motor stepping index for a lookup table
						;(3C max theoretically with 60 steps which is the min)

pwm1_step:	.space 4	;2 byte (16 bit) unsigned value representing the current
						;motor stepping index for a lookup table
						;(3C max theoretically with 60 steps which is the min)
pwm2_step:	.space 4	;2 byte (16 bit) unsigned value representing the current
						;motor stepping index for a lookup table
						;(3C max theoretically with 60 steps which is the min)

; Vars for Int2Ascii
	.align 4
charbuffer: .space 12       ; Buffer to store ASCII characters (including negative sign and null terminator)

; LCD Vars
    .align 4
cRow:   .space 4    ; cRow holds the index of the cursor

    .align 4
cCol:   .space 4    ; cCol holds the index of the column


;;;;;;Stack Declaration;;;;;;
	.align  8			;the stack (must be double-word aligned)
TopOfStack:     .bes    TOTAL_STACK_SIZE

;;;;;;Vector Table Declaration;;;;;;
        .align  512		;the interrupt vector table in SRAM
VecTable:       .space  VEC_TABLE_SIZE * BYTES_PER_WORD

.end
