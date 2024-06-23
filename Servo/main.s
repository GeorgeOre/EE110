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
;					to get the parameters of what angle to set, a milisecond delay time,
;					and how many iterations of the delay to wait.
;
; Arguments:        No arguments, set table to control inital sequence
;
; Return Values:    NA
;
; Local Variables:  None.
;
; Shared Variables: None.
;
; Global Variables: ResetISR (required)
;
; Input:            Potentiometer feedback
;
; Output:           PWM signal
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
; Limitations:       NA
;
; Revision History:   12/06/23  George Ore      initial version
;                     12/07/23  George Ore      finished inital version
;					  12/08/23	George Ore		fixed bugs, start testing
;					  01/03/24	George Ore		tested & updated functions
;					  06/22/24	George Ore		refactored and turned in
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
;	initVariables()
;	initRegisters()
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

;Reference Initalization
    .ref    InitPower    ;   Initialize power
    .ref    InitClocks   ;   Initialize clocks
    .ref    InitGPIO     ;   Initialize GPIO configurations
    .ref    InitGPTs     ;   Initialize GPTs configurations
    .ref	InitVariables;	 Initalize variables
    .ref	InitRegisters;	 Initalize vectors
    .ref	InitPWM		 ;	 Initalize PWM
    .ref	InitADC		 ;	 Initalize ADC
    .ref	InitLCD		 ;	 Initalize LCD
    .ref	MoveVecTable ;	 Initalize custom vector table
    .ref	InstallGPT1Handler ;	Install GPT1 handler

;Reference servo functions
    .ref	SetServo		;Set servo angle
    .ref	DisplayServo 	;Display servo results
    .ref	GetServo 		;Measure and update servo position
    .ref	ReleaseServo 	;Set servo in adjustable release mode


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
    .ref    PrepLCD		; 	Clears screen and prepares preamble

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
	BL	InitVariables

;;;;;;Init Register Values;;;;;;
	BL InitRegisters

;;;;;;Init PWM;;;;;;
	BL InitPWM

;;;;;;Init ADC;;;;;;
	BL	InitADC

;;;;;; Init LCD ;;;;;;
	BL	InitLCD

;;;;;;Main Program;;;;;;
Main:

TestServo: ;do the servo function tests
	MOVA 	R4, TestServoTable ;start at the beginning of table

TestServoLoop:
	LDRB	R0, [R4], #1 	;get the SetServo argument from table
	BL 		SetServo		;call the function
	LDRB 	R5, [R4], #1 	;get iterations from the table

TestGetServoLoop: 			;loop testing GetServo function
	BL 		GetServo 		;call GetServo

	BL		PrepLCD			;clear screen and print preamble

	BL 		DisplayServo 	;display GetServo results
	LDRH 	R0, [R4] 		;get the time delay from the table
	BL 		Wait_1ms 		;delay amount specified
	SUBS 	R5, #1 			;update loop counter
	BNE 	TestGetServoLoop	;loop specified number of times
	;BEQ 	CheckDoneTest 	;then check if tests done

CheckDoneTest: 				;check if tests done
	ADD		R4, #2			;get past delay entry in table
	MOVA	R5, EndTestServoTable	;check if at end of table
	SUB		R5, R5, #1		;fix address offset error
	CMP 	R4, R5
	BNE 	TestServoLoop	;not done with tests, keep looping
	;BEQ 	DoneTestServo 	;otherwise done testing the servo

DoneTestServo: ;done testing servo

	BL	ReleaseServo	;Put the servo in release mode

ReleaseLoop:
	BL	GetServo		;Get servo angle

	BL	PrepLCD			;clear screen and print preamble

	BL	DisplayServo	;Display servo angle

	MOV32 R0, WAIT1000
	BL Wait_1ms

	B	ReleaseLoop		;Loop forever

;;;;;;Testing Tables;;;;;;

TestServoTable: ;Argument 		Read Iters
				;Delay (ms)
	.byte 		-90,				3
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

EndTestServoTable:


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																			   ;
; 							Data Section									   ;
;																			   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.data
	.global angle		; Represents the servo's current angle
	.global pwm_stat	; Represents the PWM timer's status
    .global cRow		; Represents the LCD's current row
	.global cCol		; Represents the LCD's current column
	.global charbuffer  ; Stores the information to display on the LCD
	.global TopOfStack	; Represents the top of the stack
	.global VecTable	; Represents the root of the custom vector table

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
