;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                              ;
;                          EE110a HW4 Utility Functions  	                   ;
;                                 George Ore                                   ;
;                                                                              ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description: This file contains functions that interface with the LCD module.
; Goal: The goal of these functions is to modularize LCD handling.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           Required Constant Files
    .include "configPWR&CLK.inc"  ; contains power config constants
    .include "configGPIO.inc"     ; contains GPIO config constants
    .include "GPIO.inc"           ; contains GPIO control constants
    .include "GPT.inc"            ; contains GPT control constants
    .include "constants.inc"      ; contains misc. constants
    .include "macros.inc"         ; contains all macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           Required Functions
;LCD functions
	.ref Display

;Reference LCD variables
	.global charbuffer
	.global angle

;Reference tables
	.ref PWMTable
	.ref EndPWMTable

    .ref SampleTable
    .ref EndSampleTable

    .ref ErrorCorrectionTable
    .ref EndErrorCorrectionTable

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                               Table of Contents
;       Function Name        |   Purpose
    .def    Wait_1ms         ;   Wait 1 ms
    .def    LowestLevelWrite ;   Handles an LCD write cycle
    .def    LowestLevelRead  ;   Handles an LCD read cycle
    .def    WaitLCDBusy      ;   Waits until the LCD is not busy
    .def	Int2Ascii		 ; 	 Converts an integer to ascii
    .def	DisplayServo 	 ; 	 Displays the servo angle on LCD
    .def	SetPWM		 	 ; 	 Displays the servo angle on LCD
    .def	CalculatePWMRate ; 	 Calculates the relevant PWM rate
   	.def 	ErrorCorrection
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Revision History:   02/04/24 George Ore   Created format
;                     05/30/24 George Ore   Ported to EE110a HW3
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;*******************************************************************************
;*                              FUNCTIONS                                      *
;*******************************************************************************
.text                           ; program memory space start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Wait_1ms:
;
; Description:   Waits in 1ms intervals. Takes how many ms as a parameter
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
; Revision History:  12/7/24   George Ore  created
;                    12/8/24   George Ore  formated, moved to HW5
;                    01/2/24   George Ore  made interrupt driven to fix
;                                           skipping error and moved to HW4
;
; Pseudo Code
;
;   while(counter!=0)
;       reset 1msTimer
;       while(1msTimerTimeoutInterrupt!=Set)
;           NOP
;       counter--
;   return
Wait_1ms:
    PUSH    {R0, R1, R2, R3, R4}    ; Push registers
    MOV     R1, R0       ; Relocate amount of ms into R1
    MOV32   R2, GPT0     ; Load GPT0 base address
    MOV32   R3, COUNT_DONE  ; Load ms count done condition
    MOV32   R4, IRQ_TATO ; Load NOT1ms timer doneNOT timeout interrupt condition

W_1ms_Cntr_Loop:
    CMP     R1, R3           ; Check if the ms counter is done
    BEQ     End_1ms_Wait     ; If it is, end wait
;   BNE     Reset_1ms_Timer  ; if not reset the 1ms timer

Reset_1ms_Timer:
    STREG   CTL_TA_STALL, R2, CTL   ; Enable timer with debug stall

W_1ms_Timr_Loop:
    LDR     R0, [R2, #MIS]  ; Get the masked interrupt status
    CMP     R0, R4          ; Check if timeout interrupt has happened
    BNE     W_1ms_Timr_Loop ; If 1ms hasn't passed, wait
;   BEQ     DecCounter      ; If 1ms passed, decrement the cntr

DecCounter:
    STREG   IRQ_TATO, R2, ICLR    ; Clear timer A timeout interrupt
    SUB     R1, #ONE    ; Decrement the counter and go back to
    B       W_1ms_Cntr_Loop  ; counter value check

End_1ms_Wait:
    POP     {R0, R1, R2, R3, R4}    ; Pop registers
    BX      LR                      ; Return

; LowestLevelWrite:
;
; Description:   This procedure places an inputed eventID into the keybuffer
;
; Operation:    Fetches dbnceFlag state and if set, it fetches the key value
;       and converts it into an EventID before passing it to EnqueueEvent
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
; Known Bugs:        None.
;
; Limitations:       Will be a blocking function for 1us for the tCycle
;
; Revision History:  12/6/23   George Ore  Created
;                    01/5/24   George Ore  Set GPIO with DSET31_0
;                                          instead of using DOUT
;                                          Added interrupt timer timeout
;
; Pseudo Code
;
;   while(counter!=0)
;       reset TAR
;       while(TAR!=0)
;           NOP
;       counter--
LowestLevelWrite:    ; R0 = 8 bit data busdata; R1 = RS value
    PUSH    {R0, R1, R2, R3}    ; Push registers

    MOV32   R3, EMPTY   ; We will store RS and databus values into R3 *MAYBE USE MOV
    ADD     R3, R0, R1

    MOV32   R1, GPIO    ; Load GPIO and GPT2 (tCycle timer) base addresses
    MOV32   R2, GPT2
    STR     R3, [R1, #DSET31_0] ; Write RS and databus onto LCD

; HandleSetupTime:
    ; Wait 280 ns setup time (must be at least 140 ns)
    MOV32   R0, DB_SETUP_TIME    ; Setup a counter

DataBusSetupTimeLoop:
    SUB     R0, #ONE    ; Decrement counter
    CBZ     R0, DataSetupDone ; Break loop when counter is finished
    B       DataBusSetupTimeLoop    ; Keep looping if not

DataSetupDone:
    ; assume that enable rise/fall is under 25 ns (1 cpu clock)
    STREG   LCD_ENABLE, R1, DSET31_0    ; Set LCD enable pin

    MOV32   R3, ENABLE_HOLD ; Load LCD Enable hold time condition

    STREG   CTL_TA_STALL, R2, CTL   ; Enable 1us timer with debug stall

tCycle_Loop1:               ; Wait the enable hold time
    LDR     R0, [R2, #TAR]  ; Get the 1us timer value
    MOV32   R2, GPT2		; Make sure that R2 still has the correct address
    CMP     R0, R3
    BGE     tCycle_Loop1    ; If LCD Enable hold time hasn't passed, wait
;   BNE     ResetLCDEnable ; if it passed, reset LCD Enable pin

ResetLCDEnable:
    STREG   LCD_ENABLE, R1, DCLR31_0    ; Reset LCD enable pin

    MOV32   R3, IRQ_TATO    ; 1us timer timeout condition

tCycle_Loop2:               ; Wait until tCycle is done
    LDR     R0, [R2, #MIS]  ; Get the 1us timer value
    MOV32   R2, GPT2		; Make sure that R2 still has the correct address
    CMP     R0, R3
    BNE     tCycle_Loop2    ; If LCD Enable hold time hasn't passed, wait
;   BEQ     HandleHoldTime ; if it passed, reset LCD Enable pin

; HandleHoldTime:
    ; Wait 280 ns for data hold time (must be at least 140 ns)
    MOV32   R0, DB_HOLD_TIME    ; Setup a counter

DataBusHoldTimeLoop:
    SUB     R0, #ONE    ; Decrement counter
    CBZ     R0, EndWrite ; Break loop when counter is finished
    B       DataBusHoldTimeLoop ; Keep looping if not

EndWrite:
    STREG   LCD_CMD_CLR, R1, DCLR31_0   ; Clear LCD command pins
    STREG   IRQ_TATO, R2, ICLR  ; Clear timer A timeout interrupt
    POP     {R0, R1, R2, R3}    ; Pop registers
    BX      LR          ; Return


; LowestLevelRead:
;
; Description:   This procedure places an inputed eventID into the keybuffer
;
; Operation:    Fetches dbnceFlag state and if set, it fetches the key value
;       and converts it into an EventID before passing it to EnqueueEvent
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
; Known Bugs:        None.
;
; Limitations:       Will be a blocking function for 1us for the tCycle
;
; Revision History:  12/6/23   George Ore  Created
;                    01/5/24   George Ore  Set GPIO with DSET31_0
;                                          instead of using DOUT
;                                          Added interrupt timer timeout
;
; Pseudo Code
;
;	Disable outputs
;	Wait for  a cycle
;	Read data
;	return data in R0
;
LowestLevelRead:    ; R0 = 8 bit data busdata; R1 = RS value
    PUSH    {R1, R2, R3}    ; Push registers
; ASSUMES THAT IT IS IN READ MODE
    MOV32   R1, GPIO    ; Load GPIO and GPT2 (tCycle timer) base addresses
    MOV32   R2, GPT2

; HandleSetupTimeR:
    ; Wait 280 ns setup time (must be at least 140 ns)
    MOV32   R0, DB_SETUP_TIME    ; Setup a counter

DataBusSetupTimeLoopR:
    SUB     R0, #ONE    ; Decrement counter
    CBZ     R0, DataSetupDoneR ; Break loop when counter is finished
    B       DataBusSetupTimeLoopR    ; Keep looping if not

DataSetupDoneR:
    ; assume that enable rise/fall is under 25 ns (1 cpu clock)
    STREG   LCD_ENABLE, R1, DSET31_0    ; Set LCD enable pin

;    MOV32   R3, ENABLE_HOLD ; Load LCD Enable hold time condition
    MOV32   R3, IRQ_TATO ; Load timeout interrupt condition

    MOV32   R2, GPT2
    STREG   CTL_TA_STALL, R2, CTL   ; Enable 1us timer with debug stall

tCycle_Loop1R:               ; Wait the enable hold time
    LDR     R0, [R2, #MIS]  ; Get the 1us timer interrupt status
    MOV32   R2, GPT2		; Make sure that R2 still has the correct address
    CMP     R0, R3
    BGE     tCycle_Loop1R   ; If LCD Enable hold time hasn't passed, wait
;   BNE     ResetLCDEnableR ; if it passed, reset LCD Enable pin

ResetLCDEnableR:
    MOV32   R2, GPT2
    STREG   IRQ_TATO, R2, ICLR    ; Clear timer A timeout interrupt

    LDR     R0, [R1, #DIN31_0]         ; Fetch read data in R0
    PUSH    {R0}                       ; Store data in stack
    STREG   LCD_ENABLE, R1, DCLR31_0   ; Reset LCD enable pin


    MOV32   R2, GPT2
    STREG   CTL_TA_STALL, R2, CTL   ; Enable 1us timer with debug stall

    MOV32   R3, IRQ_TATO    ; 1us timer timeout condition

tCycle_Loop2R:               ; Wait until tCycle is done
    LDR     R0, [R2, #MIS]  ; Get the 1us timer value
    MOV32   R2, GPT2		; Make sure that R2 still has the correct address
    CMP     R0, R3
    BNE     tCycle_Loop2R   ; If LCD Enable hold time hasn't passed, wait
;   BEQ     HandleHoldTimeR ; if it passed, reset LCD Enable pin

; HandleHoldTimeR:
    ; Wait 280 ns for data hold time (must be at least 140 ns)
    MOV32   R0, DB_HOLD_TIME    ; Setup a counter

DataBusHoldTimeLoopR:
    SUB     R0, #ONE                ; Decrement counter
    CBZ     R0, EndRead             ; Break loop when counter is finished
    B       DataBusHoldTimeLoopR    ; Keep looping if not

EndRead:
    STREG   IRQ_TATO, R2, ICLR  ; Clear timer A timeout interrupt
    POP     {R0}                ; Pop read data
    POP     {R1, R2, R3}        ; Pop registers
    BX      LR                  ; Return

; WaitLCDBusy:
;
; Description:   Waits (blocking) until the LCD is not longer busy
;
; Operation:    Reads LCD with read command until it sends a ready signal
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
; Known Bugs:        None.
;
; Limitations:       None.
;
; Revision History:  12/6/23   George Ore  Created
;
; Pseudo Code
;
;	Set data pin 7 as an input
;	Make sure to adjust output enables
;	Keep reading until LCD is no longer busy
;	Return
WaitLCDBusy:    ; R0 = 8 bit data busdata; R1 = RS value
    PUSH    {R0, R1}    ; Push registers

    ; Disable output pins
    MOV32   R1, GPIO                    ; Load base address
    STREG   NOT_LCD_DATA_PINS, R1, DOE31_0   ; Disable LCD data pins as outputs

    ; Configure LCD data pin 7 as an input
    MOV32   R1, IOC                     ; Load base address
    STREG   IO_IN_CTRL,  R1, IOCFG15    ; Set LCD Data7 (GPIO pin 15) as an input
;   B       CheckBusyFlag

CheckBusyFlag:
    MOV32   R1, GPIO                    ; Load base address
    STREG   LCD_READ, R1, DSET31_0      ; Set read mode

CheckBusyFlagLoop:
    PUSH    {LR}    ; Call LowestLevelRead
    BL      LowestLevelRead
    POP     {LR}    ; Will read into R0

    AND     R0, #LCD_BUSYFLAG   ; Filter to busy flag bit
    CBZ     R0, LCDNotBusy      ; Break loop when busy flag is reset
    B       CheckBusyFlagLoop   ; Keep looping if not

LCDNotBusy:
    STREG   LCD_READ, R1, DCLR31_0      ; Disable read mode

; Reconfigure LCD data pin 7 as an output
	MOV32   R1, IOC                     ; Load base address
	STREG   IO_OUT_CTRL,  R1, IOCFG15   ; Set LCD Data7 (GPIO pin 15) as an output

; Disable output pins
	MOV32   R1, GPIO                    ; Load base address
	STREG   LCD_SRVO_OUTPUT_EN, R1, DOE31_0  ; Reenable all LCD pins as outputs

; B    EndWaitLCDBusy

EndWaitLCDBusy:
	POP     {R0, R1}    ; Pop registers
	BX      LR          ; Return

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


; CalculatePWMRate:
;
; Description:	The function is passed the position in degrees (pos) to which to
;				set the servo. The position (pos) is passed in R0 by value. It
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
; Registers Changed: R0, R1
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
;	(ARGS: R0 = angle)
;
;	R0 = PWMTable(angle)
;
;	return R0 (timer match), R1 (match prescale)
CalculatePWMRate:
;	PUSH    {}	;No registers to push

	MOV32	R1, LNIBBLE	;Preprocess angle for 16 bit operation
	AND		R0, R1

	MOV32	R1, ANGLE_INPUT_OFFSET	;Add 90 to get rid of negative values
	SADD16	R0, R0, R1

	MOVA	R1,	PWMTable	;Load base addresses of tables

	LSL		R0, #PWM_SHIFT_OFFSET	;Adjust input to become address offset

	ADD		R1, R0		;Add offset to addresses

	LDRH	R0, [R1]	;Load R0 with the duty cycle match value
    LDR		R1, [R1]	;and R1 with the prescale match value
    LSR		R1, #PWM_PRESCALE_SHIFT

EndCalculatePWMRate:
;	POP    	{}	;No registers to pop
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
;	(ARGS: R0 = TAMATCHR, R1 = TAPMR)
;	TAMATCHR  = R0
;	TAPMR	  = R1
;	return
SetPWM:
	PUSH    {R0, R1, R2, R3}	;Push registers

	MOV32	R2, GPT1		;Load base address


	CPSID	I	;Disable interrupts to avoid critical code


	PUSH	{R0}
	STREG   GPT_CTL_TA_PWM_STALL, R2, CTL	;Disable timer
	POP		{R0}



	MOV32	R3, TAPMR
	STR   	R1, [R2, R3] 	;Set timer match preset

	MOV32	R3, TAMATCHR 	;Set timer match duration
	STR   	R0, [R2, R3]

	STREG   GPT_CTL_EN_TA_PWM_STALL, R2, CTL	;Enable timer

	CPSIE	I	;Enable interrupts again


ENDSetPWM:
	POP    	{R0, R1, R2, R3}	;Pop registers
	BX		LR			;Return



; ErrorCorrection:
;
; Description:	Corrects the raw ADC input into an intger value and returns it into R0
;
; Operation:    Searches a table for the corresponding angle and fetches the first
;				threshold match.
;
; Arguments:         R0 - Raw ADC sample
; Return Values:     R0 - Corresponding integer
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
;
; Pseudo Code
;
;	(ARGS: R0 = sample data)
;	R0 = CorrectionTable(R0)
;	return R0
ErrorCorrection:
	PUSH    {R1, R2, R3}	;Push registers

	MOVA 	R2, SampleTable ;start at the beginning of table
	MOV32	R3, ZERO_START	;load a counter variable to count search offset

LookupTableLoop:
	LDR		R1, [R2], #NEXT_WORD 	;Get the next sample in sample table

TestSampleLoop: 			;Check if sample is less than the RAW ADC data in R0
	CMP 	R1, R0 			;Compare sample with table data
	BGE 	GetCorrectData	;When threshold is supassed, get the correct data
	ADD		R3, R3, #NEXT_WORD	;Add one byte of distance to the counter
	B 	LookupTableLoop 	;Keep traversing the sample table until the threshold is surpassed

GetCorrectData:
	MOVA	R2, ErrorCorrectionTable ;Start at the beginning of error correction table
	LDR		R0, [R2, R3]	;Load corrected angle

EndErrorCorrection:
	POP    	{R1, R2, R3}	;Pop registers
	BX		LR			;Return


; DisplayServo:
;
; Description:	Displays the servo's position onto the LCD.
;
; Operation:    Fetches angle, converts it to ascii, stores it into the
;				charbuffer, and displays it to the LCD.
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
;	Fetch angle
;	Convert angle to ascii and store into buffer
;	Display buffer into LCD
;
;	return
DisplayServo:
	PUSH    {R0, R1, R2, R3}	;Push registers

	MOVA	R1, angle	;Fetch angle address
	LDR	R0, [R1]	;Fetch the angle

; Prep the ascii buffer
	MOVA	R1, charbuffer
	PUSH    {LR}
	BL Int2Ascii	; Returns
	POP     {LR}

; Display the value
	MOV32	R0, DISPLAY_LCD_ROW	; Set the default display position
	MOV32	R1, DISPLAY_LCD_COL
    MOVA    R2, charbuffer     	; Start at the beginning of word data table

	PUSH    {LR}
    BL      Display                 ; Call the function (should increment R2 address)
	POP     {LR}

EndDisplayServo:
	POP    	{R0, R1, R2, R3}	;Pop registers
	BX		LR			;Return

.end
