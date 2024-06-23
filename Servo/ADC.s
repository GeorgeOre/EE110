;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																			   ;
;								EE110a HW5 ADC Functions						   ;
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
	.include "ADC.inc"			;contains GPT control constants
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;							Required Functions
;	None.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;								Table of Contents
;		Function Name		|	Purpose
	.def	SampleADC		;	Trigger the ADC to collect data
	.def	GetADCFIFO		;	Fetch ADC data
	.def	FlushADCFIFO	;	Reset ADC FIFO
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Revision History:	02/04/24	George Ore	Created format
;					06/23/24	George Ore	Refactored and turned in
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;*******************************************************************************
;*								FUNCTIONS									   *
;*******************************************************************************

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SampleADC:
;
; Description:	Manually triggers the ADC to sample.
;
; Operation:    Writes to the ADC control register with a trigger command
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
;	Trigger ADC
;
;	return
SampleADC:
	PUSH    {R0, R1}	;Push registers

	MOV32	R1, AUX_ANAIF	;Load analog interface base address

	STREG   TRIGGER_ADC, R1, ADCTRIG	;Trigger an ADC sample

ENDSampleADC:
	POP    	{R0, R1}	;Pop registers
	BX		LR			;Return


; GetADCFIFO:
;
; Description:	Fetches data from the ADC FIFO.
;
; Operation:    Waits until ADC status register indicates that data is ready.
;				Subsequently, fetches and returns the data in R0
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
;	while(ADCBusy){
;		wait (blocking)
;	}
;
;	R0 = ADC FIFO DATA
;
;	return R0
GetADCFIFO:
	PUSH    {R1, R2}	;Push registers

	MOV32	R1, AUX_ANAIF	;Load analog interface base address

ADCProcessingLoop:
	MOV32	R2, ADCISEMPTY	;Get ADC processing status
	LDR     R0, [R1, #ADCFIFOSTAT]		;First load general status register
	ANDS	R0, R2					;Mask for only the relevant bit
	CMP		R0, R2
	BNE		ADCReady
	B		ADCProcessingLoop		;Keep looping until ADC is ready

;while you are at it STAT0 tells you if the RCOSC_HF is on which is your ADC source check it
ADCReady:
	MOV32	R1, AUX_ANAIF	;Load analog interface base address

	MOV32	R2, ADC_DATAMASK	;Get ADC data
	LDR     R0, [R1, #ADCFIFO]
	AND		R0, R2				;But only the relevant bits

ENDGetADCFIFO:
	POP    	{R1, R2}	;Pop registers
	BX		LR			;Return

; FlushADCFIFO:
;
; Description:	Resets and clears ADC FIFO.
;
; Operation:    Writes to the ADC control register with a flush command.
;				Must turn off interface and wait some time as per datasheet.
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
;	Disable ADC
;	Flush ADC
;	Enable ADC
;	return
FlushADCFIFO:
	PUSH    {R0, R1}	;Push registers

	MOV32	R1, AUX_ANAIF	;Load analog interface base address

	STREG   FLUSHADC_MANUAL, R1, ADCCTL	;Flush ADC FIFO
	NOP		;Two 48MHz clocks are needed before enabling or
	NOP		;disabling the ADC control interface
	NOP
	NOP
;	Enable ADC control interface with manual trigger
	STREG   ENABLEADC_MANUAL, R1, ADCCTL

EndFlushADCFIFO:
	POP    	{R0, R1}	;Pop registers
	BX		LR			;Return
