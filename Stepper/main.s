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

;Reference HW4 functions
	.ref	GetMagnetZ

;Reference utility functions
	.ref	Wait_1ms
	.ref	SetPWM

;Reference SPI and serial functions
	.ref	SerialSendRdy


	.ref	TestStepperTab
	.ref	EndTestStepperTab
	.ref	MotorStepTable
	.ref	EndMotorStepTable


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

;;;;;;Init Variable Values;;;;;;
InitVariables:
	MOVA    R1, pwm_stat1		;Set PWM 1 status READY
	MOV32   R0, SET
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
	STREG   ALL_PINS, R1, DCLR31_0	;Clear all GPIO pins
	STREG   NOT_PINS, R1, DSET31_0	;Set inverted pins

;;;;;;Enable PWM Clocks/Pins;;;;;;
	;GPT2 will be our motor channel A PWM microstep control timer
	MOV32	R1, GPT2				;Load base address
	STREG   GPT_CTL_EN_TA_PWM_STALL, R1, CTL	;Enable timer A with debug stall

	;GPT3 will be our motor channel B PWM microstep control timer
	MOV32	R1, GPT3				;Load base address
	STREG   GPT_CTL_EN_TA_PWM_STALL, R1, CTL	;Enable timer A with debug stall

;;;;;;Init Stepper State;;;;;;



;;;;;;Main Program;;;;;;


;testing pwm code 4
test:
	MOVA	R3, testtablebruh

testloop:

;	(ARGS: R0 = TAMATCHR, R1 = TAMPR, R2 = Base address)
	LDR		R0, [R3], #4
	LDR		R1, [R3], #4
	LDR		R2, [R3], #4
	BL	SetPWM
	LDR		R0, [R3], #4
	BL 	Wait_1ms

CheckPWMDoneTest: 				;check if tests done
	ADR 	R4, Endtesttablebruh	;check if at end of table

	CMP 	R3, R4
	BNE 	testloop	;not done with tests, keep looping
	B		test 	;otherwise complete restart

testtablebruh:	;Match time|Prescale|Timer|Delay (ms)
	.word		TIMER16_52us,	0,	GPT3,	0	;A starts up and stays up
	.word		TIMER16_5us,	0,	GPT2,	50	;B starts down and goes up
	.word		TIMER16_10us,	0,	GPT2,	50
	.word		TIMER16_15us,	0,	GPT2,	50
	.word		TIMER16_20us,	0,	GPT2,	50
	.word		TIMER16_25us,	0,	GPT2,	50
	.word		TIMER16_30us,	0,	GPT2,	50
	.word		TIMER16_35us,	0,	GPT2,	50
	.word		TIMER16_40us,	0,	GPT2,	50
	.word		TIMER16_45us,	0,	GPT2,	50

	.word		TIMER16_52us,	0,	GPT2,	0	;B stays up
	.word		TIMER16_45us,	0,	GPT3,	50	;A decends
	.word		TIMER16_40us,	0,	GPT3,	50
	.word		TIMER16_35us,	0,	GPT3,	50
	.word		TIMER16_30us,	0,	GPT3,	50
	.word		TIMER16_25us,	0,	GPT3,	50
	.word		TIMER16_20us,	0,	GPT3,	50
	.word		TIMER16_15us,	0,	GPT3,	50
	.word		TIMER16_10us,	0,	GPT3,	50

	.word		TIMER16_4us,	0,	GPT3,	0	;A stays down
	.word		TIMER16_45us,	0,	GPT2,	50 ;B decends
	.word		TIMER16_40us,	0,	GPT2,	50
	.word		TIMER16_35us,	0,	GPT2,	50
	.word		TIMER16_30us,	0,	GPT2,	50
	.word		TIMER16_25us,	0,	GPT2,	50
	.word		TIMER16_20us,	0,	GPT2,	50
	.word		TIMER16_15us,	0,	GPT2,	50
	.word		TIMER16_10us,	0,	GPT2,	50

	.word		TIMER16_4us,	0,	GPT2,	0	;B stays down
	.word		TIMER16_10us,	0,	GPT3,	50	;A accends
	.word		TIMER16_15us,	0,	GPT3,	50
	.word		TIMER16_20us,	0,	GPT3,	50
	.word		TIMER16_25us,	0,	GPT3,	50
	.word		TIMER16_30us,	0,	GPT3,	50
	.word		TIMER16_35us,	0,	GPT3,	50
	.word		TIMER16_40us,	0,	GPT3,	50
	.word		TIMER16_45us,	0,	GPT3,	50

Endtesttablebruh:
	NOP

TestStepper: ;do the Stepper function tests
	MOVA 	R4, TestStepperTab ;start at the beginning of table

TestStepperLoop:
	LDRSB	R0, [R4], #1 	;get the SetStepper argument from table
;	BL 		SetStepper		;call the function
	LDRB 	R5, [R4], #1 	;get iterations from the table

TestGetStepperLoop: 			;loop testing GetStepper function
;	BL 		GetStepper 		;call GetStepper
;	BL 		DisplayStepper 	;display GetStepper results
	LDRH 	R0, [R4] 		;get the time delay from the table
;	BL 		Wait_1ms 		;delay amount specified
	SUBS 	R5, #1 			;update loop counter
	BNE 	TestGetStepperLoop	;loop specified number of times
	;BEQ 	CheckDoneTest 	;then check if tests done

CheckDoneTest: 				;check if tests done
	ADD		R4, #2			;get past delay entry in table
	MOVA 	R5, EndTestStepperTab	;check if at end of table
	CMP 	R4, R5
	BNE 	TestStepperLoop	;not done with tests, keep looping
	;BEQ 	DoneTestStepper 	;otherwise done testing the Stepper

DoneTestStepper: ;done testing Stepper

	NOP
	B	test

;*******************************************************************************
;USED FUNCTIONS
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

GPT1EventHandler:
	;PUSH    {R0, R1, R2}	;R0-R3 are autosaved
	PUSH    {R4}			;Push used register

	MOVA	R2, steps	;Load the motor step queue in R0
	LDR		R0, [R2]
	;B		StepsDoneTest	;Begin motor step queue test

StepsDoneTest:
	MOV32	R1, COUNT_DONE	;Test if steps are done excecuting
	CMP		R0, R1
	BEQ		EndGPT1EventHandler	;If no steps are left, end interrupt
	;BNE	HandleStep	;If there are nonzero steps, handle a step

HandleStep:
	SUB		R0, #ONE	;Decrement and save step queue
	STR		R0, [R2]

;To efficiently test and update dir, curStep, and pos, their values will be preloaded here
	MOVA	R3, dir		;Load rotational direction in R0
	LDR		R0, [R3]

	MOVA	R3, curStep	;Load current motor step index in R1
	LDR		R1, [R3]

	MOVA	R3, pos		;Load motor position in R2
	LDR		R2, [R3]

	;B		DirTest		;Begin direction test

DirTest:
	MOV32	R3, CCW	;Test if direction is counterclockwise
	CMP		R0, R3
	BEQ		CCW_CStep_Test	;If it is, test the CCW curStep index
	;BNE	CW_CStep_Test	;If not, test the CW curStep index

CW_CStep_Test:
	MOV32	R3, MAXSTEP	;Test if curStep is at the positive limit
	CMP		R1, R3
	BEQ		WrapCStepCW	;If it is, wrap the CW curStep index
	;BNE	IncCStep	;If not, increment the CW curStep index

IncCStep:
	ADD		R1, #ONE	;Increment curStep index and save it
	MOVA	R3, curStep
	STR		R1, [R3]

	B		CWPosTest	;Begin CW position test

WrapCStepCW:
	MOV32	R3, MINSTEP	;Set curStep to lowest possible index
	MOVA	R4, curStep
	STR		R3, [R4]

	B		CWPosTest	;Begin CW position test

CWPosTest:
	MOV32	R3, MAXPOS	;Test if pos is at the positive limit
	CMP		R2, R3
	BEQ		WrapPosCW	;If it is, wrap the position clockwise
	;BNE	IncPos		;If not, increment the position

IncPos:
	ADD		R2, #DPOS	;Increment position value and save it
	MOVA	R3, curStep
	STR		R2, [R3]

	B		MotorUpdate	;Update motor state

WrapPosCW:
	MOV32	R3, MINPOS	;Set position to lowest possible value
	MOVA	R4, pos
	STR		R3, [R4]

	B		MotorUpdate	;Update motor state

CCW_CStep_Test:
	MOV32	R3, MINSTEP	;Test if curStep is at the negative limit
	CMP		R1, R3
	BEQ		WrapCStepCCW	;If it is, wrap the CCW curStep index
	;BNE	DecCStep	;If not, decrement the CCW curStep index

DecCStep:
	SUB		R1, #ONE	;Decrement curStep index and save it
	MOVA	R3, curStep
	STR		R1, [R3]

	B		CCWPosTest	;Begin CCW position test

WrapCStepCCW:
	MOV32	R3, MAXSTEP	;Set curStep to highest possible index
	MOVA	R4, curStep
	STR		R3, [R4]

	B		CCWPosTest	;Begin CCW position test

CCWPosTest:
	MOV32	R3, MINPOS	;Test if pos is at the negitive limit
	CMP		R2, R3
	BEQ		WrapPosCCW	;If it is, wrap the position CCW
	;BNE	DecPos		;If not, decrement the position

DecPos:
	SUB		R2, #DPOS	;Decrement position value and save it
	MOVA	R3, pos
	STR		R2, [R3]

	B		MotorUpdate	;Update motor state

WrapPosCCW:
	MOV32	R3, MAXPOS	;Set position to highest possible value
	MOVA	R4, pos
	STR		R3, [R4]

	B		MotorUpdate	;Update motor state

MotorUpdate:
	;R3 has the updated motor stepping index value
	MOVA	R1, MotorStepTable	;Fetch motor step data
	LDR		R0, [R1,R3]

	;output that shiii

	;B	ENDGPT1EventHandler		;End event handler

EndGPT1EventHandler:
	MOV32 	R1, GPT1				;Load base into R1
	STREG   IRQ_TATO, R1, ICLR  	;Clear timer A timeout interrupt
	POP    {R4}						;POP used register
	;POP    {R0, R1, R2}			;R0-R3 are autorestored
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

;InstallGPTHandlers
;
; Description:       Install the event handler for the GPT timer interrupts.
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
InstallGPTHandlers:
    MOV32   R1, SCS       			;get address of SCS registers
    LDR     R1, [R1, #VTOR]     	;get table relocation address

    MOVA    R0, GPT1EventHandler    ;get handler address
    STR     R0, [R1, #(4 * GPT1A_EX_NUM)]   ;store vector addresses
    MOVA    R0, GPT2EventHandler    ;get handler address
    STR     R0, [R1, #(4 * GPT2A_EX_NUM)]   ;store vector addresses
    MOVA    R0, GPT3EventHandler    ;get handler address
    STR     R0, [R1, #(4 * GPT3A_EX_NUM)]   ;store vector addresses

    BX      LR						;all done, return




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																			   ;
; 							Data Section									   ;
;																			   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.data

;;;;;;Variable Declaration;;;;;;
	.align 4
pwm_stat1:	.space 4	;PWM 1 status variable

pwm_stat2:	.space 4	;PWM 2 status variable

steps:		.space 4	;2 byte (16 bit) unsigned value representing steps needed

dir:		.space 4	;1 byte (8 bit) value representing step direction

pos:		.space 2	;2 byte (16 bit) unsigned value representing position
						;in degrees
curStep:	.space 2	;2 byte (16 bit) unsigned value representing the current
						;motor stepping index for a lookup table
						;(3C max theoretically with 60 steps which is the min)

;;;;;;Stack Declaration;;;;;;
	.align  8			;the stack (must be double-word aligned)
TopOfStack:     .bes    TOTAL_STACK_SIZE

;;;;;;Vector Table Declaration;;;;;;
        .align  512		;the interrupt vector table in SRAM
VecTable:       .space  VEC_TABLE_SIZE * BYTES_PER_WORD

.end
