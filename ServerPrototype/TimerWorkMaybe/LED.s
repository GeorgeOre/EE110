;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                              ;
;                          	  EE110 LED Functions	                           ;
;                                 George Ore                                   ;
;                                                                              ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description: This file contains functions that interface with the LCD module.
; Goal: The goal of these functions is to modularize LED handling to be easily.
;	imported into any project with this simple file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           Required Constant Files
    .include "configPWR&CLK.inc"  ; contains power config constants
    .include "configGPIO.inc"     ; contains GPIO config constants
    .include "GPIO.inc"           ; contains GPIO control constants
    .include "GPT.inc"            ; contains GPT control constants
    .include "LCD.inc"            ; contains LCD interface constants
    .include "LED.inc"            ; contains LCD interface constants
    .include "general.inc"        ; contains misc general constants
    .include "macros.inc"         ; contains all macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           Required Functions
    .ref    Wait_1ms         ;   Wait 1 ms
	.ref	Int2Ascii		;	Stores an integer's value into ascii (buffer)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           Required Variables
	.global cRow        	;	Holds the current cursor row position
	.global cCol        	;	Holds the current cursor column position
	.global charbuffer  	;	Address of a user defined char buffer
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                               Table of Contents
;       Function Name   |   Purpose
    .def    InitLEDs    ;   Initializes LED outputs and inputs
    .def    Toggle_Both_LEDS    ;   Initializes LED outputs and inputs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Revision History:   07/06/24 George Ore   Inital revison
;                     05/30/24 George Ore   Ported to EE110a HW3
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;*******************************************************************************
;*                              FUNCTIONS                                      *
;*******************************************************************************
.text                           ; program memory space start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; InitLEDs:
;
; Description:  This function initializes the LEDs and buttons to control them
;				on the development board.
;
; Operation:    Configures the relevant control GPIO control registers
;
; Arguments:         None.
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
; Registers Changed: R0, R1
; Stack Depth:       2 words
;
; Algorithms:        None.
; Data Structures:   None.
; Known Bugs:        None.
;
; Limitations:       None.
;
; Revision History:  07/06/24   George Ore  created
;
; Pseudo Code
;	Set LED pins to outputs
;	Set button pins to inputs
;
InitLEDs:
    PUSH    {R0, R1}    ; Push registers

	MOV32  	R0, IO_OUT_CTRL	;Write to IOCFG6 to set Red LED output
	MOV32	R1, IOC
	STR 	R0, [R1,#IOCFG6]

	MOV32  	R0, IO_OUT_CTRL	;Write to IOCFG7 to set Green LED output
	MOV32	R1, IOC
	STR 	R0, [R1,#IOCFG7]

	MOV32  	R0, IO_IN_CTRL		;Write to IOCFG13 to set Red LED button input
	MOV32	R1, IOC				;with pullup resistor
	STR 	R0, [R1,#IOCFG13]

	MOV32  	R0, IO_IN_CTRL		;Write to IOCFG13 to set Red LED button input
	MOV32	R1, IOC				;with pullup resistor
	STR 	R0, [R1,#IOCFG14]

	MOV32  	R0, OUTPUT_ENABLE_LED	;Write to DOE31_0 to enable the LED outputs
	MOV32	R1, GPIO
	STR 	R0, [R1,#DOE31_0]

End_InitLEDs:
    POP     {R0, R1}    ; Pop registers
    BX      LR            ; Return


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; InitLEDs:
;
; Description:  This function initializes the LEDs and buttons to control them
;				on the development board.
;
; Operation:    Configures the relevant control GPIO control registers
;
; Arguments:         None.
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
; Registers Changed: R0, R1
; Stack Depth:       2 words
;
; Algorithms:        None.
; Data Structures:   None.
; Known Bugs:        None.
;
; Limitations:       None.
;
; Revision History:  07/06/24   George Ore  created
;
; Pseudo Code
;	Set LED pins to outputs
;	Set button pins to inputs
;
Toggle_Both_LEDS:
    PUSH    {R0, R1}    ; Push registers


	MOV32  	R0, OUTPUT_ENABLE_LED	;Toggle the LED outputs
	MOV32	R1, GPIO
	STR 	R0, [R1,#DTGL31_0]

End_Toggle_Both_LEDS:
    POP     {R0, R1}    ; Pop registers
    BX      LR            ; Return
