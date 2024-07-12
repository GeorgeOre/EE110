;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                              ;
;                          	EE110 Keypad Functions                        	   ;
;                                 George Ore                                   ;
;                                                                              ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description: This file contains functions that interface with the Keypad.
; Goal: The goal of these functions is to modularize Keypad handling to be
;	easily imported into any project with this simple file.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           Required Constant Files
    .include "prototype.inc"      ; contains project specific macros
    .include "configPWR&CLK.inc"  ; contains power config constants
    .include "configGPIO.inc"     ; contains GPIO config constants
    .include "GPIO.inc"           ; contains GPIO control constants
    .include "GPT.inc"            ; contains GPT control constants
    .include "Keypad.inc"         ; contains keypad interface constants
    .include "general.inc"        ; contains misc general constants
    .include "macros.inc"         ; contains all macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           Required Functions
    .ref    Wait_1ms        ;   Wait 1 ms
	.ref	Int2Ascii		;	Stores an integer's value into ascii (buffer)
	.ref	PrepLCD			;	Prepares the LCD to be written to
	.ref	Display			;	Writes a string to the LCD
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           Required Tables
    .ref    ButtonDataTable ;   Contains button press event string data
    .ref    ButtonDataAddressingTable ; Addressing interface for ButtonDataTable
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           Required Variables
    .global TopOfStack  	;	Address of the top of the stack
    .global VecTable  		;	Address of the user defined vector table
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                               Table of Contents
;       Function Name   |   Purpose
    .def    Debounce    ; Checks if the zero flag was set which detects a debounce

    .def    EnqueueEvent; Set a flag indicating that an event has occurred
    .def    DequeueEvent; Set a flag indicating that an event has occurred

    .def    EnqueueCheck; Set a flag indicating that an event has occurred
    .def    DequeueCheck; Set a flag indicating that an event has occurred

    .def    GPT2AEventHandler; Debounce the keypad every interrupt cycle
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Revision History:   02/04/24 George Ore   Created format
;                     05/30/24 George Ore   Ported to EE110a HW3
;                     06/02/24 George Ore   Ported to EE110b HW5 and refactored
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;*******************************************************************************
;*                              FUNCTIONS                                      *
;*******************************************************************************
.text                           ; program memory space start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Debounce:
; Description:      This program configures the CC2652R LaunchPad to connect to
;                   a 4x4 keypad on the Glen George TM wire wrap board. When a
;                   button is pressed, the program registers the input's keyID
;                   inside a data memory buffer.
;
; Operation:        The program constantly checks a debounce flag for "permission"
;                   to store the identifier of the corresponding debounced button
;                   in a data memory buffer.
;
; Arguments:        NA
; Return Values:    NA
; Local Variables:  eventID (passed into EnqueueEvent to be placed in the buffer)
; Shared Variables: bOffset, dbnceCntr, dbnceFlag, keyValue, prev0-3
; Global Variables: ResetISR (required)
; Input:            Keypad columns (DIN31_0 register bits 3-7)
; Output:           Keypad rows (DOUT31_0 register bits 0-3)
; Error Handling:   NA
; Registers Changed: flags, R0, R1, R2,
; Stack Depth:       0 words
; Algorithms:        NA
; Data Structures:   NA
; Known Bugs:        NA
; Limitations:       Does not support multiple simultaneous keypresses
; Revision History:
;   11/06/23  George Ore      initial version
;   11/07/23  George Ore      finished initial version
;   12/04/23  George Ore      fixed bugs, start testing
;   12/05/23  George Ore      finished
;
; Pseudo Code:
;   includeconstants()
;   includemacros()
;   global ResetISR
;   initstack()
;   initpower()
;   initclocks()
;   movevectortable()
;   installGPT0handler()
;   initGPT0()
;   initGPIO()
;   keyValue = NOT_PRESSED
;   prev0, prev1, prev2, prev3 = NOT_PRESSED
;   dbnceFlag = DBNCE_FLAG_RESET
;   dbnceCntr = DBNCE_CNTR_RESET
;   bIndex = ZERO_START
;   DOUT31-0 = ALL_OFF
;   while(1)
;       if dbnceFlag == DBNCE_FLAG_SET:
;           eventID = KeypadID & keyValue
;           EnqueueEvent(eventID)
;           dbnceFlag = DBNCE_FLAG_RESET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Debounce:   ;Loop goes on forever
	PUSH	{R0, R1}	;Push registers

    MOVA    R1, dbnceFlag   ;Load dbnceFlag address into R1

    CPSID   I   ;Disable interrupts to avoid critical code
    LDR     R0, [R1]    ;Load dbnceFlag data onto R0

    MOV32   R1, DBNCE_FLAG_SET  ;Load R1 with the event pressed condition
    CMP     R0, R1
    BNE     SkipEvent       ;If dbnceFlag != SET, skip EnqueueEvent
    BL      EnqueueEvent    ;If debounce flag == set, enqueue event

SkipEvent: ;This label is only used in the != case
    CPSIE   I   ;Enable interrupts again

EndDebounce:
    POP		{R0, R1}	;Pop registers
    BX LR  ;Return for now but this will run forever

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EnqueueEvent:
; Description: This procedure places an inputted eventID into the keybuffer
; Operation: Fetches dbnceFlag state and if set, it fetches the key value and
;            converts it into an EventID before passing it to EnqueueEvent
; Arguments: R0 - eventID
; Return Values: None, instead writes to buffer
; Local Variables: None
; Shared Variables: buffer, bIndex
; Global Variables: None
; Input: None
; Output: None
; Error Handling: None
; Registers Changed: R0, R1, R2, R3
; Stack Depth: 1 word
; Algorithms: None
; Data Structures: None
; Revision History: 12/4/23 George Ore added documentation
; Pseudo Code:
;   buffer(bIndex) = keyValue
;   bIndex++
;   return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
EnqueueEvent:
    PUSH    {R0, R1, R2, R3}    ;Push registers

    ; To avoid critical code, preload addresses
    MOVA    R1, keyValue
    MOVA    R2, bIndex
    MOVA    R3, buffer  ;Fetch buffer address on R3

    CPSID   I   ;Disable interrupts to avoid critical code

    LDRB    R0, [R1]    ;Load R0 with the key value
    LDRB    R1, [R2]    ;Load R1 with the buffer index value

    ADD     R1, #ONE    ;Increment the buffer index value
    STRB    R1, [R2]    ;Save the buffer index

    SUB     R1, #ONE    ;Restore the buffer index value

; Use buffer index value to traverse the buffer into the next empty buffer address
    ADD		R3, R3, R1

    STRB     R0, [R3]    ;Put keyValue in the calculated buffer address

    MOVA    R0, dbnceFlag    ;Reset status of dbnceFlag
    MOV32   R1, DBNCE_FLAG_RESET
    STRB    R1, [R0]

    CPSIE   I   ;Enable interrupts again

    POP     {R0, R1, R2, R3}    ;Pop registers
    BX      LR  ;Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; DequeueEvent:
; Description: 	This procedure takes an eventID from the keybuffer and uses it
;				to display the corresponding items on the display
; Operation: Fetches dbnceFlag state and if set, it fetches the key value and
;            converts it into an EventID before passing it to EnqueueEvent
; Arguments: None.
; Return Values: None.
; Local Variables: None.
; Shared Variables: buffer, bIndex
; Global Variables: None.
; Input: None.
; Output: None.
; Error Handling: None.
; Registers Changed: R0, R1, R2, R3
; Stack Depth: 1 word
; Algorithms: None.
; Data Structures: None.
; Revision History: 12/4/23 George Ore added documentation
; Pseudo Code:
;	string str_to_display = buffer(0)
;   Display(str_to_display)
;	for (int i = 1; i < bIndex; i++) {
;		buffer(i-1) = buffer(i);
;	}
;   bIndex--
;   return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DequeueEvent:
    PUSH    {R0, R1, R2, R3}    ;Push registers

    MOVA    R1, buffer	;Fetch the buffer address
    LDRB	R0, [R1]	;Load the first byte in the buffer

	;Display the string corresponding to that byte
	;Possible codes:
	;	77	(0, 0)	-	Option 1
	;	B7	(1, 0)	-	Option 2
	;	D7	(2, 0)	-	Option 3
	;	E7	(3, 0)	-	Option 4
	;	7B	(0, 1)	-	Option 5
	;	BB	(1, 1)	-	Option 6
	;	DB	(2, 1)	-	Option 7
	;	EB	(3, 1)	-	Option 8
	;	7D	(0, 2)	-	Option 9
	;	BD	(1, 2)	-	Option 10
	;	DD	(2, 2)	-	Option 11
	;	ED	(3, 2)	-	Option 12
	;	7E	(0, 3)	-	Option 13
	;	BE	(1, 3)	-	Option 14
	;	DE	(2, 3)	-	Option 15
	;	EE	(3, 3)	-	Option 16
	;Table matching code
	;Table will be a 2D array indexed by the bit position of each option
	MVN	R0, R0	;Perform a logical NOT to convert the key byte code into two one-hot nibble codes
	AND	R1, R0, #HNIBBLE	;Fetch the row indexing variable from the upper nibble
	AND	R0, R0, #LNIBBLE	;Fetch the row indexing variable from the lower nibble

	;Calculate the correct menu offset based on the row and column positions in R0 and R1
	MOV32	R2, ZERO_START
DequeueRowOffsetLoop:
	LSR		R0, #SHIFT_BIT	;Logical shift the row one-hot bit right one bit

;If it is gone, then the correct row offset has been added to R2
	CBZ		R0, DequeueColumnOffsetPrep	;Now the column offset must be handled

;If it is not gone, then add some row offset to R2 and repeat the loop
	ADD		R2, R2, #ROW_4x4_OFFSET
	B	DequeueRowOffsetLoop

DequeueColumnOffsetPrep:
;Logical shift the column one-hot bit right to align it to the lower nibble
	LSR		R1, #SHIFT_NIBBLE

DequeueColumnOffsetLoop:
	LSR		R1, #SHIFT_BIT	;Logical shift the column one-hot bit right one bit

;If it is gone, then the correct column offset has been added to R2
	CBZ		R1, DisplayDequeuedData	;Display data at the correct offset

;If it is not gone, then add some column offset to R2 and repeat the loop
	ADD		R2, R2, #COLUMN_4x4_OFFSET
	B		DequeueColumnOffsetLoop

DisplayDequeuedData:
;Use the calculated offset to index the button data addressing table
	MOVA	R3, ButtonDataAddressingTable
	ADD		R3, R2	;R3 contains the ADDRESS for the OFFSET for the BUTTON DATA TABLE

;Now get the correct offset for the intended button string data in R3
	LDR		R3, [R3]	;R3 contains the OFFSET for the BUTTON DATA TABLE

	MOVA	R2, ButtonDataTable		; Fetch the button data table address
	ADD		R2, R3	; Add the base and the offset for the correct string data in R2

    MOV32   R0, 0    ; Set the column and row of the data to (0, 0)
    MOV32   R1, 0

	PUSH	{LR}	;Prep LCD to be written on
	BL	PrepLCD
	POP		{LR}

	PUSH	{LR}	;Write the button's data
    BL	Display
	POP		{LR}

;AT THIS POINT, THE DEQUEUE ACTION HAS BEEN MADE BUT THE STATE STILL NEEDS UPDATING
    MOVA    R1, bIndex	;Fetch state variable addresses to be updated

    CPSID   I   ;Disable interrupts to avoid critical code

    LDR     R0, [R1]    ;Load R0 with the buffer index value

;If the buffer index is 0, then nothing needs to be updated
	CBZ		R0, EndDequeueEvent

;If not, then there is buffer data to update
    MOVA    R2, buffer

	ADD		R3, R4, R1	;Add the buffer index value to get the next empty address in the buffer
;*** This is saved in R3 and is the end condition for the buffer update loop
;	R0, R1 - Swapping temp registers
;	R2 - Buffer address pointer (will be incremented)
;	R3 - End of the buffer address
DequeueBufferLoop:
    LDRB    R0, [R2], #1    ;Load R0 and R1 with the unmodified data values
    LDRB    R1, [R2], #1    ;for the first two bytes of data in the buffer

	EOR		R0, R1	; Swap the two values with the XOR swap technique
	EOR		R1, R0
	EOR		R0, R1

	STRB    R0, [R2, #-2], #1	; Save the swapped values
    STRB    R1, [R2]

	CMP		R2, R3	;Check if the address has reached the end
	BEQ		DequeueUpdatebIndex	;Update the bIndex if so

    B	DequeueBufferLoop	;Keep looping until done

DequeueUpdatebIndex:
    MOVA    R1, bIndex	;Fetch bIndex
    LDR     R0, [R1]
    SUB		R0, R0, #1	;Decrement
    STR		R0, [R1]		;And save

	;B	EndDequeueEvent

EndDequeueEvent:
    CPSIE   I   ;Enable interrupts again

    POP     {R0, R1, R2, R3}    ;Pop registers
    BX      LR  ;Return


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EnqueueCheck:
; Description: This procedure places an inputted eventID into the keybuffer
; Operation: Fetches dbnceFlag state and if set, it fetches the key value and
;            converts it into an EventID before passing it to EnqueueEvent
; Arguments: R0 - eventID
; Return Values: None, instead writes to buffer
; Local Variables: None
; Shared Variables: buffer, bIndex
; Global Variables: None
; Input: None
; Output: None
; Error Handling: None
; Registers Changed: R0, R1, R2, R3
; Stack Depth: 1 word
; Algorithms: None
; Data Structures: None
; Revision History: 12/4/23 George Ore added documentation
; Pseudo Code:
;   buffer(bIndex) = keyValue
;   bIndex++
;   return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
EnqueueCheck:
    PUSH    {R1}    ;Push registers

    MOVA    R1, dbnceFlag   ;Load dbnceFlag address into R1

    CPSID   I   ;Disable interrupts to avoid critical code
    LDR     R0, [R1]    ;Load dbnceFlag data onto R0

    MOV32   R1, DBNCE_FLAG_SET  ;Load R1 with the event pressed condition
    CMP     R0, R1
    BNE     FalseEvent	;If dbnceFlag != SET, return false
    ;B      TrueEvent   ;If debounce flag == set, return true

TrueEvent:
	MOV32	R0, TRUE
	B	EndEnqueueCheck

FalseEvent:
	MOV32	R0, FALSE
;	B	EndEnqueueCheck

EndEnqueueCheck:
    CPSIE   I   ;Enable interrupts again
    POP     {R1}    ;Pop registers
    BX      LR  ;Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; DequeueCheck:
; Description: 	This procedure takes an eventID from the keybuffer and uses it
;				to display the corresponding items on the display
; Operation: Fetches dbnceFlag state and if set, it fetches the key value and
;            converts it into an EventID before passing it to EnqueueEvent
; Arguments: None.
; Return Values: None.
; Local Variables: None.
; Shared Variables: buffer, bIndex
; Global Variables: None.
; Input: None.
; Output: None.
; Error Handling: None.
; Registers Changed: R0, R1, R2, R3
; Stack Depth: 1 word
; Algorithms: None.
; Data Structures: None.
; Revision History: 12/4/23 George Ore added documentation
; Pseudo Code:
;	string str_to_display = buffer(0)
;   Display(str_to_display)
;	for (int i = 1; i < bIndex; i++) {
;		buffer(i-1) = buffer(i);
;	}
;   bIndex--
;   return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DequeueCheck:
    PUSH    {R0, R1, R2, R3}    ;Push registers

    MOVA    R1, bIndex	;Fetch the buffer Index value
    LDRB	R0, [R1]

	CBNZ	R0, FalseDequeue
	;CBZ	R0, TrueDequeue
TrueDequeue:
	MOV32	R0, TRUE
	B	EndDequeueCheck

FalseDequeue:
	MOV32	R0, FALSE
;	B	EndDequeueCheck

EndDequeueCheck:
    CPSIE   I   ;Enable interrupts again

    POP     {R0, R1, R2, R3}    ;Pop registers
    BX      LR  ;Return


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GPT2AEventHandler:
; Description: This procedure is called through the GPIO vector table interrupt.
;              It debounces keypresses and updates the dbnceFlag and keyValue
;              variables.
; Operation: Updates output row. Then tests if input indicates nothing is
;            pressed and returns if so.
; Arguments: None
; Return Values: None
; Local Variables: R0: temp, R1: input, R2: output, R3: prevAddress, R4:
;                  cntrAddress, R5: temp2, R6: temp3
; Shared Variables: bOffset, dbnceCntr, dbnceFlag, keyValue, prev0-prev3
; Global Variables: None
; Input: None
; Output: None
; Error Handling: Does not set dbnceFlag again until previous event has been
;                 handled.
; Registers Changed: R0, R1, R2, R3, R4, R5, R6
; Stack Depth: 1-2 words
; Algorithms: None
; Data Structures: None
; Revision History: 12/4/23 George Ore added documentation and fixed bugs
; Pseudo Code:
;   fetch input state
;   mask the 32bit value to only get the 4 relevant values
;   Get current output state (keep in a reg for later)
;   Test to see which row it is
;   if(row0):
;       keep prev0 address in a register for later
;       update to start outputting row 1
;   else if(row1):
;       keep prev1 address in a register for later
;       update to start outputting row 2
;   else if(row2):
;       keep prev2 address in a register for later
;       update to start outputting row 3
;   else(row3):
;       keep prev3 address in a register for later
;       update to start outputting row 0
;   if input == NOTHINGPRESSED:
;       reset debouncecounter
;       end debounce test
;   else:
;       if debounceCounter = 0:
;           if dbnceFlag == reset:
;               reset debouncecounter
;               end debounce test
;           else:
;               end debounce test
;       else:
;           if inputstate == previnputstate:
;               dec debounce counter
;               if debounce counter finished (0):
;                   keyvalue = outputstate+inputstate
;                   dbnceFlag = SET
;                   return
;               else:
;                   return
;           else:
;               reset dbcounter
;               store inputstate in prevstate
;               return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GPT2AEventHandler:
    PUSH    {R4, R5, R6}        ;save the registers (R0-R3 are autosaved)

GetCurrentRowInput:
    MOV32   R5, GPIO            ;Load base address into R5

    LDR     R1, [R5, #DIN31_0]  ;Load current input state in R1
    MOV32   R0, INPUT_MASK
    AND     R1, R0              ;Mask to only receive relevant input bits

GetCurrentRowOutput:
    LDR     R2, [R5, #DOUT31_0] ;Load state of outputs in R2
    MOV32   R0, OUTPUT_MASK
    AND     R2, R0              ;Mask to only receive output bits

R0Test:
    MOV32   R0, R0_TEST     ;See if the output is row 0
    CMP     R2, R0
    BNE     R1Test          ;if not, test row 1

R0Update:
    MOVA    R3, prev0       ;if it is, save the address of prev0 in R3 for later
    MOVA    R4, dbnceCntr0  ;save the address of dbnceCntr0 in R4 for later
    STREG   R1_TEST, R5, DOUT31_0    ;and update output to test row 1
    B       DebounceTest    ;start debounce test

R1Test:
    MOV32   R0, R1_TEST     ;See if it is row 1
    CMP     R2, R0
    BNE     R2Test          ;if not, test row 2

R1Update:
    MOVA    R3, prev1       ;if it is, save the address of prev1 in R3 for later
    MOVA    R4, dbnceCntr1  ;save the address of dbnceCntr1 in R4 for later
    STREG   R2_TEST, R5, DOUT31_0    ;and update output to test row 2
    B       DebounceTest    ;start debounce test

R2Test:
    MOV32   R0, R2_TEST     ;See if it is row 2
    CMP     R2, R0          ;if not, it means row three is being tested
    BNE     R3Update        ;branch to handle a row 3 update

R2Update:
    MOVA    R3, prev2       ;if it is, save the address of prev2 in R3 for later
    MOVA    R4, dbnceCntr2  ;save the address of dbnceCntr2 in R4 for later
    STREG   R3_TEST, R5, DOUT31_0    ;and update output to test row 3
    B       DebounceTest    ;start debounce test

R3Update:
    MOVA    R3, prev3       ;if it is, save the address of prev3 in R3 for later
    MOVA    R4, dbnceCntr3  ;save the address of dbnceCntr3 in R4 for later
    STREG   R0_TEST, R5, DOUT31_0    ;update to test row 0

DebounceTest:
; The debounce test section has many conditions to test. Here is a quick
; conditional map:
;   if input == NOTHINGPRESSED:
;       reset debouncecounter
;       end debounce test
;   else:
;       if debounceCounter = 0:
;           if dbnceFlag == reset:
;               reset debouncecounter
;               end debounce test
;           else:
;               end debounce test
;       else:
;           if inputstate == previnputstate:
;               dec debounce counter
;               if debounce counter finished (dbncecntr == 0):
;                   keyvalue = outputstate+inputstate
;                   dbnceFlag = SET
;                   return
;               else:
;                   return
;           else:
;               reset dbcounter
;               store inputstate in prevstate
;               return

TestUnpressed:
    ; Reminder that R1 contains the masked input state
    MOV32   R0, NOT_PRESSED ;Test if the input pattern is not pressed
    CMP     R1, R0

    BNE     DbnceCntrTest    ;If something is pressed, start the dbnceCntr test

ResetDbnceCntr:
    ; Reminder that R4 contains the relevant debounce counter address
    MOV32   R0, DBNCE_CNTR_RESET    ;Reset relevant debounce counter
    STR     R0, [R4]

    B       EndDbnceTest    ;End debounce test

; The following code executes only if there is pressed input
DbnceCntrTest:
    ; Reminder that R4 contains the relevant debounce counter address
    LDR     R5, [R4]        ;Load relevant debounce counter value
    MOV32   R0, COUNT_DONE  ;Load counter-finished test condition
    CMP     R5, R0
    BNE     PrevTest    ;If the count is not done, test input with prev state

FlagTest:
    MOVA    R5, dbnceFlag   ;Load debounce flag value onto R6
    LDR     R6, [R5]
    MOV32   R0, DBNCE_FLAG_SET   ;Load flag set test condition
    CMP     R6, R0
    BNE     ResetDbnceCntr  ;If the flag is not set, reset the dbnceCntr
    B       EndDbnceTest    ;If the flag is set, end debounce test

; The following code executes only when dbnceCntr tested a >0 value
PrevTest:
    ; Reminder that R1 contains the masked input state and that R3 contains the
    ; relevant prev variable address
    LDR     R0, [R3]        ;Load relevant prev state value

    CMP     R1, R0          ;Compare the input and the prev input values
    BEQ     DecCounterTest  ;If equal, start the decremented counter test

UpdatePrev:
    ; Reminder that R1 contains the masked input state & that R3 contains the
    ; relevant prev variable address
    STR     R1, [R3]        ;Update relevant prev variable
    B       ResetDbnceCntr  ;Reset debounce counter

; The following code executes only when input == previnput
DecCounterTest:
    ; Reminder that the address of the relevant dbnceCntr is in R4
    LDR     R5, [R4]    ;Decrement and save the counter
    SUB     R5, #ONE
    STR     R5, [R4]

    MOV32   R0, COUNT_DONE  ;Load counter-finished test condition
    CMP     R5, R0          ;Test decremented counter
    BNE     EndDbnceTest    ;If the count is not done, end the debounce test

SetKeyVars:
    ; Reminder that R1 contains the masked input state and that R2 contains the
    ; masked output state
    ADD     R1, R2          ;Calculate keyValue ID (inputstate+outputstate)
    MOVA    R5, keyValue    ;Save keyValue
    STR     R1, [R5]

    MOV32   R0, DBNCE_FLAG_SET   ;Set dbnceFlag
    MOVA    R5, dbnceFlag
    STR     R0, [R5]

EndDbnceTest:
    MOV32   R1, GPT2            ;Load base into R1
    STREG   IRQ_TATO, R1, ICLR  ;clear timer A timeout interrupt
    POP     {R4, R5, R6}        ;restore registers
    BX      LR                  ;return from interrupt

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; EnqueueCheck:
; Description: This procedure places an inputted eventID into the keybuffer
; Operation: Fetches dbnceFlag state and if set, it fetches the key value and
;            converts it into an EventID before passing it to EnqueueEvent
; Arguments: R0 - eventID
; Return Values: None, instead writes to buffer
; Local Variables: None
; Shared Variables: buffer, bIndex
; Global Variables: None
; Input: None
; Output: None
; Error Handling: None
; Registers Changed: R0, R1, R2, R3
; Stack Depth: 1 word
; Algorithms: None
; Data Structures: None
; Revision History: 07/08/24 George Ore added documentation
; Pseudo Code:
;   buffer(bIndex) = keyValue
;   bIndex++
;   return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; CHECK TO ENQUEUE THE EVENT
;EnqueueCheck:   ;Loop goes on forever
;    MOVA    R1, dbnceFlag   ;Load dbnceFlag address into R1

;    CPSID   I   ;Disable interrupts to avoid critical code
;    LDR     R0, [R1]    ;Load dbnceFlag data onto R0

;    MOV32   R1, DBNCE_FLAG_SET  ;Load R1 with the event pressed condition
;    CMP     R0, R1
;    BNE     SkipEvent       ;If dbnceFlag != SET, skip EnqueueEvent
;    BL      EnqueueEvent    ;If debounce flag == set, enqueue event

;SkipEvent: ;This label is only used in the != case
;    CPSIE   I   ;Enable interrupts again

;	BX		LR	;RETURN!!

;    B       EnqueueCheck        ;Repeat forever


;*******************************************************************************
;*                              VARIABLES                                      *
;*******************************************************************************
	.data

    .global prev0
    .global prev1
    .global prev2
    .global prev3

    .global dbnceCntr0
    .global dbnceCntr1
    .global dbnceCntr2
    .global dbnceCntr3

    .global buffer
    .global bIndex
    .global dbnceFlag
    .global keyValue

; Variable Declaration
; prev0-3 will store previous states of the IO inputs for each row
	.align 4
prev0:      .space 1    ;will store previous value of row 0
    .align 4
prev1:      .space 1    ;will store previous value of row 1
     .align 4
prev2:      .space 1    ;will store previous value of row 2
	.align 4
prev3:      .space 1    ;will store previous value of row 3

; dbnceCntr0-3 will function as debounce counters for each row
	.align 4
dbnceCntr0: .space 4    ;dbnceCntr is a 32-bit one-shot decrementer
	.align 4
dbnceCntr1: .space 4    ;dbnceCntr is a 32-bit one-shot decrementer
	.align 4
dbnceCntr2: .space 4    ;dbnceCntr is a 32-bit one-shot decrementer
	.align 4
dbnceCntr3: .space 4    ;dbnceCntr is a 32-bit one-shot decrementer

	.align 4
keyValue:   .space 1    ;keyValue will have codes unique to each button. The
                        ;high nibble represents the rows and the low nibble
                        ;represents the columns

	.align 4
dbnceFlag:  .space 1    ;flag indicates if a button is successfully debounced

	.align 4
bIndex:     .space 1    ;stores index of the next empty buffer address

; Buffer Declaration
	.align 4                ;buffer will store the 2-byte key identification numbers
buffer:     .space 160  ;has enough space to store 160 key presses (16keys*10times)


.end
