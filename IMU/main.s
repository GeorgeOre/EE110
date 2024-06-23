;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																			   ;
;								EE110b HW1 Main Loop						   ;
;									George Ore								   ;
;																			   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description:  This program configures the CC2652R LaunchPad to connect to
;				a MPU9250 IMU module on the Glen George TM wire wrap board.
;				It constantly displays new accelerometer, gyroscope, and
;				magnetometer data into a data buffer.
;
; Operation:	The program first includes all necessary constants, macros,
;				and functions. Then it initalizes all relevant power
;				domains, clocks, and modules. Then it initializes the
;				buffer index variable. The next stage is the main loop:
;				The program begins a poll driven main loop that constantly
;				fetches data from the accelerometer, gyroscope, and
;				magnetometer through the SPI communication protocol at a
;				frequency of 1 Hz. Every time data is aquired it displays
;				the latest data on a data buffer.
;
; Arguments:        None.
;
; Return Values:    None.
;
; Local Variables:  None.
;
; Shared Variables: None.
;
; Global Variables: ResetISR (required)
;
; Input:            Transformations of the IMU module in Euclidean space
;
; Output:           None (Data buffer is internal)
;
; Error Handling:   None.
;
; Registers Changed: R0, R1, R2, R3
;
; Stack Depth:      1 word	(Main loop)
;
; Algorithms:       None.
;
; Data Structures:	Word aligned data buffer
;
; Known Bugs:		Eventually, the data buffer will fill up and there will be a
;					memory collision.
;
; Limitations:		Limited buffer space.
;
; Revision History:	01/08/24	George Ore	Created document
;					01/09/24	George Ore	Created pseudo codes
;					01/10/24	George Ore	Finished pseudo codes
;					01/24/24	George Ore	Made test code with memory buffer
;					01/26/24	George Ore	Adjusted times for buffer access
;											and reworked comments
;					01/29/24	George Ore	Updated documentation
;					01/30/24	George Ore	Found last bugs
;					01/31/24	George Ore	Updated implementation
;					02/01/24	George Ore	Reformatted to include file
;											heiarchy and finalized first
;											version of SSI implementation
;					02/02/24	George Ore	Finally made project work and demoed
;					02/04/24	George Ore	Final comments and restuctures
;
; Pseudo Code
;
;	IncludeConstants()
;	IncludeMacros()
;	ReferenceFunctions()
;
;	global ResetISR
;
;	InitStack()
;   InitPower()
;   InitClocks()
;   InitGPIO()
;   InitGPT()
;
;	InitSPI()
;	InitIMU()
;	InitMag()
;
;	bIndex = ZERO_START
;
;	while(1)
;		R1 = GetAccelX()+GetAccelY()
;		R2 = GetAccelZ()+GetGyroX()
;		R3 = GetGyroY()+GetGyroZ()
;
;		Save2Buffer()
;		Wait_1ms(1000)
;
;		R1 = GetMagnetX()
;		R2 = GetMagnetY()
;		R3 = GetMagnetZ()
;
;		Save2Buffer()
;		Wait_1ms(1000)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Include constant files
	.include "configPWR&CLK.inc"	;Contains power config constants
	.include "configGPIO.inc"	;Contains GPIO config constants
	.include "GPIO.inc"			;Contains GPIO control constants
	.include "GPT.inc"			;Contains GPT control constants
	.include "SSI.inc"			;Contains SSI control constants
	.include "IMU.inc"			;Contains IMU control constants
	.include "constants.inc"	;Contains misc. constants

;Include macro files
	.include "macros.inc"		;contains all macros

;Reference initialization functions
	.ref	InitPower
	.ref	InitClocks
	.ref	InitGPIO
	.ref	InitGPTs
	.ref	InitSSI
	.ref	InitMPU9250
	.ref	InitAK8963

;Reference HW1 functions
	.ref	GetAccelX
	.ref	GetAccelY
	.ref	GetAccelZ
	.ref	GetGyroX
	.ref	GetGyroY
	.ref	GetGyroZ
	.ref	GetMagnetX
	.ref	GetMagnetY
	.ref	GetMagnetZ

;Reference utility functions
	.ref	Wait_1ms

;Reference SPI and serial functions
	.ref	SPIReadCycle
	.ref	SPIWriteCycle
	.ref	SerialGetData
	.ref	SerialSendData
	.ref	SerialGetRdy
	.ref	SerialSendRdy

	.text				;program start
	.global ResetISR	;requred global var

ResetISR:				;System required label

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																			   ;
;							Actual Program Code								   ;
;																			   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;Initialize Stack;;;;;;
;InitStack:
    MOVA    R0, TopOfStack
    MSR     MSP, R0
    SUB     R0, R0, #HANDLER_STACK_SIZE
    MSR     PSP, R0

;;;;;;Initialize Power;;;;;;
	BL	InitPower

;;;;;;Initialize Clocks;;;;;;
	BL	InitClocks

;;;;;;Initalize GPTs;;;;;;
	BL	InitGPTs

;;;;;;Initalize GPIO;;;;;;
	BL	InitGPIO

;;;;;;Initalize SPI;;;;;;
	BL	InitSSI

;;;;;;Initalize IMU;;;;;;
	BL	InitMPU9250

;;;;;;Initalize Magnetometer;;;;;;
	BL	InitAK8963

;;;;;;Init Variable Values;;;;;;
InitVariables:
	MOVA    R1, bIndex	;Start the buffer index at 0
	MOV32   R0, ZERO_START
	STR     R0, [R1]

;;;;;;Main Program;;;;;;
Main:
;For the accelerometer and gyroscope data, it will be stored in the following
;format with each register representing a 32 bit word on the buffer:
;	Register	|	Upper Half Word		|	Lower Half Word
;		R1		|	Acceleromter Y Data	|	Acceleromter X Data
;		R2		|	Gyroscope X Data	|	Acceleromter Z Data
;		R3		|	Gyroscope Z Data	|	Gyroscope Y Data

;Fetch AccelXY data and place it on R1
	BL	GetAccelX	;Function to fetch the data
	MOV	R1, R0		;Place in R1
	BL	GetAccelY	;Function to fetch the data
	LSL	R0, #HWORD_SHIFT	;Prep for being the upper half word
	ADD	R1, R0		;Place in R1

;Fetch AccelZ and GyroX data and place it on R2
	BL	GetAccelZ	;Function to fetch the data
	MOV	R2, R0		;Place in R2
	BL	GetGyroX	;Function to fetch the data
	LSL	R0, #HWORD_SHIFT	;Prep for being the upper half word
	ADD	R2, R0		;Place in R2

;Fetch GyroYZ data and place it on R3
	BL	GetGyroY	;Function to fetch the data
	MOV	R3, R0		;Place in R3
	BL	GetGyroZ	;Function to fetch the data
	LSL	R0, #HWORD_SHIFT	;Prep for being the upper half word
	ADD	R3, R0		;Place in R3

;Save all Gyro and Accel data to data buffer
	BL	Save2Buffer
;Wait 1 second before proceeding
	MOV32	R0, WAIT1000
	BL	Wait_1ms

;Each magnet data will be saved to the buffer in its own word in this format
; R1: Magnetometer X Data | R2: Magnetometer Y Data | R3: Magnetometer Z Data
	BL	GetMagnetX	;Function to fetch the data
	MOV	R1, R0		;Place in R1
	BL	GetMagnetY	;Function to fetch the data
	MOV	R2, R0		;Place in R2
	BL	GetMagnetZ	;Function to fetch the data
	MOV	R3, R0		;Place in R3

;Save data to buffer
	BL	Save2Buffer
;Wait 1 second before proceeding
	MOV32	R0, WAIT1000
	BL	Wait_1ms

	B	Main		;Loop forever


;*******************************************************************************
;*							USED FUNCTIONS									   *
;*******************************************************************************
;The following function(s) are used in the event that variables need accessing
;and in order to prevent needing global variables.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Save2Buffer:
;
; Description:	Saves three words of inforation into a data buffer.
;
; Operation:    Checks where the next empty buffer index is and saves data
;				there. Also updates the index.
;
; Arguments:         R0, R1, R2 - Data to store
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
; Stack Depth:       1 word (Called in main)
;
; Algorithms:        None.
; Data Structures:   None.
; Known Bugs:        None.
;
; Limitations:       None.
;
; Revision History:  01/26/24	George Ore	 Created
;
; Pseudo Code
;	(ARGS: R0 = data)
;	buffer[next empty index] = data
;	bindex += 1
;
;	return
Save2Buffer:
	PUSH    {R0, R1, R2, R3, R4}	;Push registers

;To avoid critical code, preload addresses
	MOVA 	R4, bIndex

	LDR 	R0, [R4]	;Load R1 with the buffer index value

	ADD		R0, #NEXTBINDEX	;Increment the buffer index value
	STR		R0, [R4]		;Save the buffer index

	SUB		R0, #NEXTBINDEX	;Restore the buffer index value

	MOVA	R4, buffer	;Fetch buffer address on R4

	ADD		R4, R0		;Add next empty buffer index value to the buffer address
						;in order to point there

	STR	R1, [R4], #NEXT_WORD	;Put data in the calculated buffer address
	STR	R2, [R4], #NEXT_WORD	;Put data in the calculated buffer address
	STR	R3, [R4], #NEXT_WORD	;Put data in the calculated buffer address

End_Save2Buffer:
	POP    {R0, R1, R2, R3, R4}	;Pop registers
	BX		LR	;Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																			   ;
; 							Data Section									   ;
;																			   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.data

;;;;;;Variable Declaration;;;;;;
	.align 4
bIndex:		.space 4	;Holds the next empty index of the buffer

;;;;;;Buffer Declaration;;;;;;

	.align 4				;Buffer will store the positional information from
buffer:		.space 10000	;the IMU. It has enough space to store lots of data

;;;;;;Stack Declaration;;;;;;
	.align  8			;the stack (must be double-word aligned)
TopOfStack:     .bes    TOTAL_STACK_SIZE

.end
