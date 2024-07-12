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
    .include "prototype.inc"      ;contains project constants

    .include "general.inc"      ;contains misc general constants
	.include "macros.inc"		;contains all macros
	.include "GPT.inc"			;contains GPT control constants
	.include "GPIO.inc"			;contains GPIO control constants
	.include "configGPIO.inc"	;contains GPIO config constants

	.include "LED.inc"	;contains GLEN LED CODE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;							Required Functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;							Table of Contents
;		Function Name		|	Purpose
	.def	Wait_1ms		;	To wait
	.def	Int2Ascii		;	Stores an integer's value into ascii (buffer)
	.def	Divmod			;	Divides an integer into result and remainder
	.def	DivByZero		;	Catches handling when attempting to divide by 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Revision History:	07/02/24	George Ore	Imported format and made first rev
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
;	MOV32	R4, 0	;Load timeout interrupt condition

;	MOV32	R5, 0x11111111
;	PUSH	{R5}

W_1ms_Cntr_Loop:
;	MOV32	R5, 0x22222222
;	PUSH	{R5}
	CMP		R1, R3			;Check if the ms counter is done
	BEQ		End_1ms_Wait	;If it is, end wait
	;BNE	Reset_1ms_Timer	;if not reset the 1ms timer

Reset_1ms_Timer:
;	MOV32	R5, 0x33333333
;	PUSH	{R5}
	STREG   CTL_TA_STALL, R2, CTL	;Enable timer with debug stall

W_1ms_Timr_Loop:
;	PUSH	{R0, R4}
	LDR		R0, [R2, #MIS]	;Get the masked interrupt status
;	LDR		R0, [R2, #TAR]	;Get the masked interrupt status
	CMP		R0, R4			;Check if timeout interrupt has happened
	BNE		W_1ms_Timr_Loop	;If 1ms hasn't passed, wait
	;BEQ	DecCounter		;If 1ms passed, decrement the cntr

DecCounter:
;	MOV32	R5, 0x12345678
;	PUSH	{R5}
	STREG   IRQ_TATO, R2, ICLR  	;Clear timer A timeout interrupt
	SUB		R1, #ONE	;Decrement the counter and go back to
	B		W_1ms_Cntr_Loop	;counter value check

End_1ms_Wait:
	POP    	{R0, R1, R2, R3, R4}	;Pop registers
	BX		LR			;Return

; Int2Ascii
;
; Description:	Computes an integer into an ascii value and places it into
;				a buffer.
;
; Operation:    Checks for sign and stores a negative sign into buffer if true.
;				Uses division and mod to find divisors and remainder to parse
;				the binary into decimal. Convert results in to ascii and store
;				while incrementing to a count. Use that count to invert the
;				buffer before saving it and returning.
;
; Arguments:         R0 - target integer
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
; Revision History:  12/6/23   George Ore  Created
;
; Pseudo Code
;
;	if negative
;		add '-' to buffer and offset by 1
;	count = 0
;	while (remainder exists){
;		divide and mod the integer
;		convert it to ascii
;		add it to the buffer
;		count ++
;	}
;	swap the order of the counted (non '-') values
;
;	store into buffer
Int2Ascii:    ; R0 = target integer ; R1 = Ascii string buffer pointer
    PUSH    {R0, R1, R2, R3, R4, R5, R6, R7}    ; Push registers

    MOV R2, R0                  ; Save number to R2
    MOV R3, R1                  ; Save original buffer pointer to R3 and R4
    MOV R4, R1                  ; Save original buffer pointer to R3 and R4

    MOV R5, #ZERO_START         ; Digit counter
    MOV32 R6, ASCII_ZERO        ; ASCII value of '0'

    CMP R2, #COUNT_DONE
    BGE PositiveNumber         ; If number is positive, skip negative handling
	;BLT NegativeNumber

;NegativeNumber:
    MOV R0, #ASCII_NEGATIVE     ; Handle negative sign
    STRB R0, [R3], #NEXT_BYTE   ; Store '-' in buffer and increment pointer
	;RSBS is reverse subtract setting flags and allows us to do 0 - R2
    RSBS R2, R2, #0             ; Take two's complement to get positive equivalent
    ADD R4, R4, #NEXT_BYTE      ; Adjust buffer pointer
    ;B PositiveNumber

PositiveNumber:
	MOV R7, #ZERO_START		; Char counter

ConvertDigitLoop:
    MOV R0, R2	; Number to divide
    MOV32 R1, BASE10	; Divisor (base 10)

    PUSH    {LR}    ; Call Divmod
    BL Divmod                 ; Divide R0 by 10
    POP     {LR}    ; Will place result in R0 (quotient), remainder in R1

    ADD R1, R1, R6              ; Convert remainder to ASCII
    STRB R1, [R4], #1               ; Store ASCII character
    ADD R7, R7, #1              ; Increment digit counter
    MOV R2, R0                  ; Update number with quotient
    CMP R2, #0
    BNE ConvertDigitLoop            ; Loop until all digits are processed

; Now the digits are in reverse order, reverse them to correct order
    MOV R5, R7	; Save char count
    MOV R6, #0	; Make this one inverse

ReverseLoop:
    SUBS R7, R7, #ONE           ; Decrement digit counter
    CBZ R7, DoneReversing
    LDRB R1, [R3]       ; Load digits
    LDRB R2, [R3, R7]

    STRB R1, [R4, #-1]	; Store digits in reverse order
    STRB R2, [R3], #1   ; Store digits in reverse order
    B ReverseLoop

DoneReversing:
    MOV R0, #STRING_END
    STRB R0, [R3, #NEXT_BYTE]        ; Null-terminate the string

EndInt2Ascii:
; By this point, the buffer should have the ascii values
	MOV R0, R5	; Return the number of chars in R0
    POP {R0, R1, R2, R3, R4, R5, R6, R7}    ; Restore registers and return
    BX      LR                  			; Return



;ANOTHER FUNCITON NOW

Divmod:
    ; Perform integer division: R0 / R1
    ; Result: Quotient in R0, Remainder in R1

    PUSH {R2, R3, R4, R5, R6, R7}    ; Restore registers and return

    ; Initialize result
    MOV R3, #0          ; Quotient
    MOV R4, R0          ; Dividend
    MOV R5, R1          ; Divisor

    CMP R5, #0
    BEQ DivByZero

DivmodLoop:
    CMP R4, R5          ; Compare dividend and divisor
    BLT EndDivmod       ; If dividend < divisor, division is done
    SUB R4, R4, R5      ; Subtract divisor from dividend
    ADD R3, R3, #1      ; Increment quotient
    B DivmodLoop

EndDivmod:
    MOV R0, R3          ; Store quotient in R0
    MOV R1, R4          ; Store remainder in R1

    POP {R2, R3, R4, R5, R6, R7}    ; Restore registers and return
    BX LR               ; Return

DivByZero:
    ; Handle division by zero (undefined behavior)
    MOV R0, #0
    MOV R1, #0
    POP {R2, R3, R4, R5, R6, R7}    ; Restore registers and return
    BX LR

;
;
;
;
;
;
;GLEN ASSEMBLY BELOW
;
;
;
;
;
;

;	.global ti_sysbios_knl_Event_post__E THIS IS NOT NEEDED
;	.ref Event_post

; GPT0AEventHandler
;
; Description:       This procedure is the event handler for the timer
;                    interrupt.  It posts a red LED event.
;
; Operation:         Posts a TIMEOUT_EVENT to the redLEDEvent event and
;                    returns.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  redLEDEvent - posts a TIMEOUT_EVENT to this event.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: None
; Stack Depth:       5+ words
;
; Revision History:  02/18/21   Glen George      initial revision
	;.include <ti/sysbios/knl/Event_defs.h>
GPT0AEventHandler:
        .def    GPT0AEventHandler


        ;external references
;        .ref    redLEDEvent                     ;the event to post to
;        .ref    ti_sysbios_knl_Event_post__E    ;the posting function
        .ref    ti_sysbios_knl_Event_post    ;the posting function



        PUSH    {R0 - R3, R9, R12, LR}  ;save the registers
                                        ;   don't know what Event_post trashes


SendTimeoutEvent:                       ;send the timeout event
;        MOVA    R1, redLEDEvent         ;get the event handle
        LDR     R0, [R1]
        MOV32   R1, TIMEOUT_EVENT       ;get the event to post and post it
;        BL      ti_sysbios_knl_Event_post__E
        BL      ti_sysbios_knl_Event_post
;        BL      Event_post

        ;B      ResetInt                ;and reset the interrupt


ResetInt:                               ;reset interrupt bit for GPT0A
        MOV32   R1, GPT0      ;get base address
        STREG   IRQ_TATO, R1, ICLR ;clear the interrupt
        ;B      DoneInterrupt           ;all done with interrupts


DoneInterrupt:                          ;done with interrupt
        POP     {R0 - R3, R9, R12, LR}  ;restore registers
        BX      LR                      ;return from interrupt



; InitLEDs
;
; Description:       This function initializes the red and green LEDs.  The
;                    red LED is turned on and the green LED is turned off.
;
; Operation:         The output pin for the red LED is set to turn it on and
;                    the output pin for the green LED is cleared to turn it
;                    off.
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
; Revision History:  02/18/21   Glen George      initial revision

;InitLEDs:
;        .def    InitLEDs


 ;       MOV32   R1, GPIO_BASE_ADDR      ;get base for GPIO registers

        ;turn on the red LED
  ;      STREG   (1 << REDLED_IO_BIT), R1, GPIO_DSET31_0_OFF

        ;turn off the green LED
   ;     STREG   (1 << GREENLED_IO_BIT), R1, GPIO_DCLR31_0_OFF


    ;    BX      LR                              ;done so return




; ToggleGreenLED
;
; Description:       This function toggles the green LED.
;
; Operation:         The output pin for the green LED is toggled.
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
; Revision History:  02/18/21   Glen George      initial revision

ToggleGreenLED:
        .def    ToggleGreenLED


        MOV32   R1, GPIO      ;get base for GPIO registers

        ;toggle the green LED
        STREG   (1 << GREENLED_IO_BIT), R1, DTGL31_0


        BX      LR                      ;done so return




; ToggleRedLED
;
; Description:       This function toggles the red LED.
;
; Operation:         The output pin for the red LED is toggled.
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
; Revision History:  02/18/21   Glen George      initial revision

ToggleRedLED:
        .def    ToggleRedLED


        MOV32   R1, GPIO      ;get base for GPIO registers

        ;toggle the red LED
        STREG   (1 << REDLED_IO_BIT), R1, DTGL31_0


        BX      LR                      ;done so return
