;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																			   ;
;							EE110 HW1 George Ore							   ;
;																			   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
; Description:       This program functionalizes the LEDs and buttons on the
;					 CC2652R LaunchPad.
;
; Operation:         The program constantly scans the states of the buttons and
;					 adjusts the LEDs accordingly.
;
; Arguments:         NA
;
; Return Values:     NA
;
; Local Variables:   NA
;                    
; Shared Variables:  NA
;
; Global Variables:  NA
;
; Input:             Buttons (DIN31_0 register bits 13 & 14)
;
; Output:            LEDs (DOUT31_0 register bits 6 & 7)
;
; Error Handling:    NA
;
; Registers Changed: flags, R0, R1, R2
;
; Stack Depth:       0 words
;
; Algorithms:        NA
;                    
; Data Structures:   NA
;
; Known Bugs:        NA
;
; Limitations:       Does not work if the LED jumpers on the board disconnect
;
; Revision History:   10/27/23  George Ore      initial revision
;                     10/31/23  George Ore      fixed constant value bugs
;
;
; Pseudo Code
;
;   initpower()
;   initclocks()
;   initIO()
;   WHILE (1)
;       R0 = getInput()
;       IF (buttons_unpressed) THEN
;           Output(none)
;       ELSEIF (red_pressed) THEN
;           Output(red)
;       ELSEIF (green_pressed) THEN
;           Output(green)
;       ELSE
;           Output(both)
;       ENDIF
;   ENDWHILE
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Include constants and macro files
	.include "constants.inc"
	.include "macros.inc"

	.text				;program start
	.global ResetISR	;requred global var



ResetISR:					;System required label 



;;;;;;Initialize Power;;;;;;

	MOV32 	R0, GPIO_ON		;GPIO power turned on
	MOV32	R1, PRCM
	STR 	R0, [R1,#PDCTL0];PDCTRL0 is writen to in order to turn power on

WaitPON:					;Wait until power is on
	MOV32 	R0, GPIO_ON		;Load test constant
	MOV32	R2, PRCM		;Load PDSTAT0 to check if power is on 
	LDR		R1, [R2,#PDSTAT0]
	SUB   	R0, R1 			;Compare test constant with PDSTAT0
	CMP 	R0, #0
	BNE		WaitPON			;Keep looping if power is not on
	
	MOV32 	R0, CLOCK_ON	;Write to GPIOCLKGR to turn on the sysclock
	MOV32	R1, PRCM
	STR 	R0, [R1,#GPIOCLKGR]
	
	MOV32 	R0, LOAD_CLOCK	;Write to CLKLOADCTL to turn on IO clock
	MOV32	R1, PRCM
	STR 	R0, [R1,#CLKLOADCTL]
	
WaitCLKPON:						;Wait for clocks to be on
	MOV32 	R0, CLOCK_LOADED	;Load test constant
	MOV32	R2, PRCM			;Read CLKLOADCTL to check if clock is on
	LDR		R1, [R2,#CLKLOADCTL]
	SUB   	R0, R1 				;Compare test constant with CLKLOADCTL
	CMP 	R0, #0
	BNE	WaitCLKPON				;Keep looping if clock is not on

;;;;;;Initalize GPIO;;;;;;
  
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

	MOV32  	R0, OUTPUT_ENABLE	;Write to DOE31_0 to enable the LED outputs
	MOV32	R1, GPIO
	STR 	R0, [R1,#DOE31_0]
	
;;;;;;Main Program;;;;;;
MainLoop:						;Loop goes on forever
	MOV32 	R1, GPIO
	LDR 	R0, [R1, #DIN31_0]	;Load status of IO into R0
	AND  	R0, #INPUT_MASK		;Apply mask to only get input bits

OffTest:
	MOV32 R1, NOT_PRESSED	;Load R1 with the not pressed condition
	CMP   R0, R1			;If !=, test red
	BNE  RedTest
BOTHOFF:					;If =, set LEDs off
	MOV32  R0, BOTH_OFF
	MOV32	R1, GPIO
	STR   R0, [R1, #DOUT31_0]
	B 	  MainLoop			;Back to main loop

RedTest:
	MOV32 R1, RED_PRESSED	;Load R1 with the red pressed condition
	CMP   R0, R1			;If !=, test green
	BNE  GreenTest
RLEDON:						;If =, set red LED only
	MOV32  R0, RED_ON
	MOV32	R1, GPIO
	STR   R0, [R1, #DOUT31_0]
	B     MainLoop			;Back to main loop

GreenTest:
	MOV32 R1, GREEN_PRESSED	;Load R1 with the green pressed condition
	CMP   R0, R1			;If !=, both are on
	BNE   BothOn
GLEDON:						;If =, set green LED only
	MOV32  R0, GREEN_ON
	MOV32	R1, GPIO
	STR   R0, [R1, #DOUT31_0]
	B     MainLoop			;Back to main loop
	
BothOn:
	MOV32  R0, BOTH_ON		;Set both LEDs on
	MOV32	R1, GPIO
	STR   R0, [R1, #DOUT31_0]
	B     MainLoop			;Back to main loop



;data section is irrelevant
	.data

	.align 8;
counter:    .space 4
	.align 8
