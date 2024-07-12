;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                              ;
;                          	  EE110 LCD Functions	                           ;
;                                 George Ore                                   ;
;                                                                              ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description: This file contains functions that interface with the LCD module.
; Goal: The goal of these functions is to modularize LCD handling to be easily.
;	imported into any project with this simple file
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           Required Constant Files
    .include "configPWR&CLK.inc"  ; contains power config constants
    .include "configGPIO.inc"     ; contains GPIO config constants
    .include "GPIO.inc"           ; contains GPIO control constants
    .include "GPT.inc"            ; contains GPT control constants
    .include "LCD.inc"            ; contains LCD interface constants
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
;User oriented functions
    .def    Display     ;   Display a string to the LCD
    .def    DisplayChar ;   Display a char to the LCD
    .def    PrepLCD 	;   Prep the LCD to display a number
	.def	InitLCD		;	Initalize LCD
;*** ^^^^ Prep LCD has a modifiable character string and cursor parameters ***

;Internal Helper Functions
    .def    LowestLevelWrite ;   Handles an LCD write cycle
    .def    LowestLevelRead  ;   Handles an LCD read cycle
    .def    WaitLCDBusy      ;   Waits until the LCD is not busy
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
; Display:
;
; Description:   The function is passed a <null=0x00> terminated string (str) to
;                output to the LCD at the passed row (r) and column (c). If the
;                row and column are both -1, the string is output starting at
;                the current cursor position. The cursor position is always
;                updated to the position after the last character in the string.
;
; Operation:    The string is passed by reference in R2 (i.e. the address of the
;                string is R2). The row (r) is passed in R0 by value and the
;                column (c) is passed in R1 by value. First the amount of
;                characters in the string is counted. Then the function calls
;                DisplayChar for every char in the string.
;
; Arguments:         R0 - Row (-1 if cursor row)
;                    R1 - Column (-1 if cursor column)
;                    R2 - Data address of the string
;
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None
; Output:            None
;
; Error Handling:    String row wraps - Done inside DisplayChar
;                    Invalid indexes are ignored - Done inside DisplayChar
;
; Registers Changed: R0, R1, R2, R3, R4, R5, R6
; Stack Depth:       2 words
;
; Algorithms:        None.
; Data Structures:   None.
; Known Bugs:        Strings longer than 16 chars will write onto themselves
;
; Limitations:       Can only display 16 char strings on only one row at a time
;
; Revision History:  12/6/23   George Ore  created
;                    12/7/23   George Ore  fixed bugs
;                    12/8/23   George Ore  fixed bugs & format
;
; Pseudo Code
;
;   (ARGS: R0 = rowindex, R1 = colindex, R2 = stringaddress)
;   counter = 0
;   for char in string
;       counter++
;   while(counter!=0)
;       displayChar(R0 = rowindex, R1 = colindex, R2 = stringaddress))
;       counter--
Display:
    PUSH    {R0, R1, R2, R3, R4, R5, R6}    ; Push registers

    MOV32   R3, ZERO_START  ; Start a counter to count chars
    MOV     R5, R2          ; Copy address in R5
    LDRSB   R4, [R5], #NEXT_CHAR    ; Get first char data
                                    ; then post increment to next char address
    MOV32   R6, STRING_END  ; Load end of string condition

CountChars:
    CMP     R4, R6          ; Test if string has ended
    BEQ     CharsCounted    ; If string ended, go to chars counted label
;   BNE     AddChar         ; If not, increment char counter

AddChar:
    ADD     R3, #ONE                ; Increment char counter
    LDRB    R4, [R5], #NEXT_CHAR    ; Load next char and update address
    B       CountChars              ; Keep counting chars

CharsCounted:   ; All chars in string have been counted. Result is in R3
    ; We will now handle each char individually and count down until finished
    MOV32   R6, COUNT_DONE  ; Load count down done condition
    MOV     R5, R2          ; Save address in R5 again

DisplayLoop:
    CMP     R3, R6          ; Test if all chars in string have been handled
    BEQ     End_Display     ; If they have, end Display
;   BNE     DispCurChar     ; If not, display current char

DispCurChar:
    LDRSB   R2, [R5], #ONE  ; Load char data onto R2 for DisplayChar
                            ; then post increment R5 by one byte
    PUSH    {LR}            ; Calling function inside function requires PUSH LR
    BL      DisplayChar     ; Display current char
    POP     {LR}            ; POP LR

    SUB     R3, #ONE        ; Decrement char count

    MOV32   R0, CINDEX      ; Set row and column to follow newly set cursor pos
    MOV32   R1, CINDEX

    B       DisplayLoop

End_Display:
    POP     {R0, R1, R2, R3, R4, R5, R6}    ; Pop registers
    BX      LR            ; Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; DisplayChar:
;
; Description:   The function is passed a character (ch) to output to the LCD at
;                the passed position (row r and column c). If the row and column
;                are both -1, the character is output at the current cursor
;                position. The cursor position is always updated to the position
;                after the character.
;
; Operation:    The row (r) is passed in R0 by value and the column (c) is
;                passed in R1 by value. The character (ch) is passed in R2 by
;                value.
;
; Arguments:         R0 - Row (-1 if cursor row)
;                    R1 - Column (-1 if cursor column)
;                    R2 - Char data
;
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:  cRow, cCol
; Global Variables:  None.
;
; Input:             None (Data memory)
; Output:            LCD Output
;
; Error Handling:    Wraps column index if column is max value on same row
;                    Ignores invalid index inputs
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
; Revision History:  12/6/23   George Ore  created
;                    12/7/23   George Ore  fixed bugs
;                    12/8/23   George Ore  fixed bugs and format
;                    01/5/24   George Ore  revamped input testing
;
; Pseudo Code
;
;   (ARGS: R0 = row, R1 = col, R2 = char)
;   if (row, col, or char) in {invalid args}
;       return
;   if row == -1
;       row = cRow
;   if col == -1
;       col = cCol
;
;   LowestLevelWrite(SetDDRAM, calcaddress(row, col))
;   LowestLevelWrite(WriteDDRAM, char)
;
;   cRow = row
;   if col == maxColIndex
;       cCol = Col0    ; wrap
;   else
;       cCol++
DisplayChar:
    PUSH    {R0, R1, R2, R3, R4}    ; Push registers

; Handle cursor indexing first before running valid input tests
; CRowTest:
    MOV32   R3, CINDEX  ; Load cursor index test value
    CMP     R0, R3
    BNE     CColTest    ; If the row input did not index the cursor, test the column
;   BEQ     CRowSet     ; If not, set row index as the cursor value

; CRowSet:
    MOVA    R4, cRow    ; Set R0 with cursor row index
    LDR     R0, [R4]
;   B       CColTest

CColTest:
    ; R3 still contains the cursor index test value
    CMP     R1, R3
    BNE     MinIndexTest    ; If the column input did not index the cursor, start validation tests
;   BEQ     CColSet         ; If not, set column index as the cursor value

; CColSet:
    MOVA    R4, cCol        ; Set R1 with cursor column index
    LDR     R1, [R4]
;   B       MinIndexTest    ; Proceed to set the character on the LCD

; Invalid input error handling
;   Error handling is to not set the character and return
; 1. Test lower input limits
;   - Test row input (R0), column input (R1), and char value input (R2) for
;     values lower than the minimum valid input
; 2. Test upper input limits
;   - Test row input (R0), column input (R1), and char value input (R2) for
;     values higher than the maximum valid input
; 3. Character invalid midband
;   - Besides having an upper and lower limit, char values also have a band
;     between 01111111-10100000 non-inclusive that is invalid

MinIndexTest:
    MOV32   R3, MIN_INDEX    ; Load minimum index value (for both row & col)
    CMP     R0, R3           ; The row index input is invalid if row < minimum index
    BLT     End_DisplayChar  ; If row input is invalid, simply return as error handling

    CMP     R1, R3           ; The column index input is invalid if col < minimum index
    BLT     End_DisplayChar  ; If column input is invalid, simply return as error handling

    MOV32   R3, MIN_CHAR     ; Load minimum character value
    CMP     R2, R3           ; The character value is invalid if char < minimum index
    BLT     End_DisplayChar  ; If character value is invalid, simply return as error handling

;   B       MaxIndexTest     ; If tests are passed, test for max indexes

; MaxIndexTest:
    MOV32   R3, MAX_RINDEX   ; Load maximum row index value
    CMP     R0, R3           ; The row index input is invalid if row > maximum index
    BGT     End_DisplayChar  ; If row input is invalid, simply return as error handling

    MOV32   R3, MAX_CINDEX   ; Load maximum column index value
    CMP     R1, R3           ; The column index input is invalid if col > maximum index
    BGT     End_DisplayChar  ; If column input is invalid, simply return as error handling

    MOV32   R3, MAX_CHAR     ; Load maximum character value
    CMP     R2, R3           ; The character value is invalid if char > maximum index
    BGT     End_DisplayChar  ; If character value is invalid, simply return as error handling

;   B       LowerBandTest    ; If tests are passed, test the character band

; LowerBandTest:
    MOV32   R3, LOW_CHARBAND ; Load lower character band limit
    CMP     R2, R3           ; Test character against lower band limit
    BLE     ValidInputs      ; If the character <= lower character band limit, it is valid
;   BGT     UpperBandTest    ; If not, test it against the upper band limit

; UpperBandTest:
    MOV32   R3, HIGH_CHARBAND    ; Load upper character band limit
    CMP     R2, R3           ; Test character against upper band limit
    BLT     End_DisplayChar  ; If the character < upper character band limit,
                            ; then the character value is inside the invalid
                            ; character band and is invalid, simply return as
                            ; error handling
;   BGE     ValidInputs      ; If not, it is valid

ValidInputs:
; Cursor index handling
;   This section assumes cRow and cCol now contain valid data

SetChar:
    PUSH    {R0, R1}        ; Save indexes for later
    ; The LCD only takes in 0x00 or 0x40 (index 0 or 1) for row addressing
    LSL     R0, #ROWADDRESSSHIFT    ; Shifting our index left can accommodate
    ; LCD addresses columns directly as indexes from 0-15
    ADD     R0, R1           ; Simply add to row addressing to combine address
    LSL     R0, #GPIOSHIFT   ; Shift address to align with corresponding GPIOs
    ADD     R0, #SETDDRAMBIT ; Add the addressing function DDRAM bit to address
    MOV32   R1, SETDDRAM_RS  ; Prepare the addressing function RS value
    PUSH    {LR}             ; Call WaitLCDBusy
    BL      WaitLCDBusy
    POP     {LR}             ; Will make sure that LCD is ready to receive a command
    PUSH    {LR}             ; Call LowestLevelWrite
    BL      LowestLevelWrite ; (ARGS: R0 = FunctionData R1 = FunctionRS)
    POP     {LR}             ; Will set the correct address to the LCD register

    MOV     R0, R2           ; Prepare the character data input for LowestLevelWrite
    LSL     R0, #GPIOSHIFT   ; Shift character data to align with corresponding GPIOs
    MOV32   R1, WRITEDDRAM_RS ; Prepare the writing function RS value
    PUSH    {LR}             ; Call WaitLCDBusy
    BL      WaitLCDBusy
    POP     {LR}             ; Will make sure that LCD is ready to receive a command
    PUSH    {LR}             ; Call LowestLevelWrite
    BL      LowestLevelWrite ; (ARGS: R0 = FunctionData R1 = FunctionRS)
    POP     {LR}             ; Will write the character data to the set LCD address
;   B       UpdateCursor     ; Proceed to update cursor index

; UpdateCursor:
    POP     {R0, R1}        ; Fetch indexes from earlier

; UpdateCCurTest:
    MOV32   R3, MAX_CINDEX  ; Test if cursor column index is at the boundary
    CMP     R1, R3
    BNE     UpdateCCur      ; If it is not, do an incremental cursor update
;   BEQ     WrapCCur        ; if it is, wrap the cursor column to initial index

WrapCCur:
    MOV32   R1, CCOL0       ; Prepare column to be set to initial
    B       UpdateCurVars

UpdateCCur:
    ADD     R1, #ONE
;   B       UpdateCurVars

UpdateCurVars:
    MOVA    R3, cRow
    STR     R0, [R3]
    MOVA    R3, cCol
    STR     R1, [R3]

End_DisplayChar:
    POP     {R0, R1, R2, R3, R4}    ; Pop registers
    BX      LR                      ; Return

; PrepLCD:
;
; Description:   Clears the display and presets the preamble "SERVO POS: ".
;
; Operation:    Sends a clear screen command to the LCD and then displays the
;				preamble using the Display function.
;
; Arguments:         None.
;
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
; Stack Depth:       2 words
;
; Algorithms:        None.
; Data Structures:   None.
; Known Bugs:        None.
;
; Limitations:       None.
;
; Revision History:  12/6/23   George Ore  created
;                    12/7/23   George Ore  fixed bugs
;                    12/8/23   George Ore  fixed bugs & format
;
; Pseudo Code
;
;	Clear LCD screen
;
;	Write preamble to LCD
;
;	return
PrepLCD:
	PUSH {R0, R1, R2, R3, R4}

	PUSH {LR}
	BL      WaitLCDBusy
	POP {LR}
    MOV32   R0, CLR_LCD            ; Write clear display command
    MOV32   R1, CLR_LCD_RS
	PUSH {LR}
    BL      LowestLevelWrite
	POP {LR}
	PUSH {LR}
	BL      WaitLCDBusy
	POP {LR}

; Write the preamble to the LCD

;NO PREAMBLE THIS TIME
;    MOVA    R2, SentenceStringTable ; Start at the beginning of sentence data table
;    MOVA    R3, SStringAddressingTable ; and also the sentence addressing table
;
;    LDRB    R0, [R3], #NEXT_BYTE    ; Get the next row index from table and post increment address
;    LDRB    R1, [R3], #NEXT_BYTE    ; Get the next column index from table and post increment address
;    LDRB    R4, [R3], #NEXT_BYTE    ; Get the address offset to the next word
;
;	PUSH {LR}
;    BL      Display                 ; Call the function
;	POP {LR}

EndPrepLCD:
	POP {R0, R1, R2, R3, R4}
	BX LR

;PREAMBLE FOR PREPLCD vvvvvvvvvvv
;    .align 1
;SentenceStringTable:
;    .byte       'S', 'T', 'E', 'P', 'P', 'E', 'R', 'P', 'O', 'S',  ':', STRING_END

;    .align 1
;SStringAddressingTable:    ; Row Col Offset
;    .byte                  0,  0,  0xB

; InitLCD:
;
; Description:	Initalizes the LCD.
;
; Operation:    Sends SPI commands to initalize the LCD. Has
;				delays as specified by the datasheet.
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
;	Function commands and delay font and lines
;
;	Turn LCD off
;	Clear LCD command
;	Entry mode set command
;	Write command
;
;	return
InitLCD:    ; The following is LCD function set/startup
    MOV32   R0, WAIT30             ; Wait 30 ms (15 ms min)
    PUSH {LR}
    BL      Wait_1ms
	POP {LR}
;    PUSH {LR}
;    BL      WaitLCDBusy
;	POP {LR}
    MOV32   R0, FSET_2LINES_DFONT  ; Write function set command
    MOV32   R1, FSET_RS
    PUSH {LR}
    BL      LowestLevelWrite
	POP {LR}

    MOV32   R0, WAIT8              ; Wait 8 ms (4.1 ms min)
    PUSH {LR}
    BL      Wait_1ms
	POP {LR}

    MOV32   R0, FSET_2LINES_DFONT  ; Write function set command
    MOV32   R1, FSET_RS
    PUSH {LR}
    BL      LowestLevelWrite
	POP {LR}

    MOV32   R0, WAIT1              ; Wait 1 ms (100 us min)
    PUSH {LR}
    BL      Wait_1ms
	POP {LR}

    MOV32   R0, FSET_2LINES_DFONT  ; Write function set command
    MOV32   R1, FSET_RS
    PUSH {LR}
    BL      LowestLevelWrite
	POP {LR}

; From here we need to wait until the busy flag is reset before executing the next command
    PUSH {LR}
    BL      WaitLCDBusy
   	POP {LR}
    MOV32   R0, FSET_2LINES_DFONT  ; Write function set command
    MOV32   R1, FSET_RS
    PUSH {LR}
    BL      LowestLevelWrite
	POP {LR}

    PUSH {LR}
    BL      WaitLCDBusy
	POP {LR}
    MOV32   R0, LCD_OFF            ; Write display off command
    MOV32   R1, LCD_OFF_RS
    PUSH {LR}
    BL      LowestLevelWrite
	POP {LR}

    PUSH {LR}
    BL      WaitLCDBusy
	POP {LR}
    MOV32   R0, CLR_LCD            ; Write clear display command
    MOV32   R1, CLR_LCD_RS
    PUSH {LR}
    BL      LowestLevelWrite
	POP {LR}

    PUSH {LR}
    BL      WaitLCDBusy
	POP {LR}
    MOV32   R0, FWD_INC            ; Write entry mode set command
    MOV32   R1, ENTRY_RS
    PUSH {LR}
    BL      LowestLevelWrite
	POP {LR}

    PUSH {LR}
    BL      WaitLCDBusy
	POP {LR}
    MOV32   R0, CUR_BLINK          ; Write display on command
    MOV32   R1, LCD_ON_RS
    PUSH {LR}
    BL      LowestLevelWrite
	POP {LR}

	BX	LR	;Return



; DisplayStepper:
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
;
; Pseudo Code
;
;	(ARGS: R0 = TAMATCHR, R1 = TAMPR)
;	TAMATCHR  = R0
;	TAMPR = R1
;
;	return
DisplayStepper:
	PUSH    {R0, R1, R2, R3}	;Push registers

;	MOVA	R1, pos	;Fetch angle address
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


ENDDisplayStepper:
	POP    	{R0, R1, R2, R3}	;Pop registers
	BX		LR			;Return

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

    MOV32   R1, GPIO    ; Load GPIO and GPT1 (tCycle timer) base addresses
    MOV32   R2, GPT1
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

;    MOV32   R3, ENABLE_HOLD ; Load LCD Enable hold time condition
    MOV32   R3, IRQ_TBTO    ; 1us timer timeout condition

    STREG   CTL_TB_AB_STALL, R2, CTL   ; Enable 1us timer with debug stall

    MOV32   R2, GPT1		; Make sure that R2 still has the correct address
;    MOV32   R0, 0x30    ; Setup a counter
tCycle_Loop1:               ; Wait the enable hold time
    ; Wait 0x30 clock cycle time time
;    SUB     R0, #ONE    ; Decrement counter
 ;   CBZ     R0, ResetLCDEnable ; Break loop when counter is finished
  ;  B       tCycle_Loop1    ; Keep looping if not

    LDR     R0, [R2, #MIS]  ; Get the 1us timer value
    MOV32   R2, GPT1		; Make sure that R2 still has the correct address
    CMP     R0, R3
    BNE     tCycle_Loop1    ; If LCD Enable hold time hasn't passed, wait
;   BEQ     ResetLCDEnable ; if it passed, reset LCD Enable pin

ResetLCDEnable:
    STREG   IRQ_TBTO, R2, ICLR  ; Clear timer B timeout interrupt

    STREG   LCD_ENABLE, R1, DCLR31_0    ; Reset LCD enable pin

    MOV32   R3, IRQ_TBTO    ; 1us timer timeout condition

    STREG   CTL_TB_AB_STALL, R2, CTL   ; Enable 1us timer with debug stall

;    MOV32   R0, 0x30    ; Setup a counter
tCycle_Loop2:               ; Wait until tCycle is done
    ; Wait 0x30 clock cycle time time
 ;   SUB     R0, #ONE    ; Decrement counter
  ;  CBZ     R0, HandleHoldTime ; Break loop when counter is finished
   ; B       tCycle_Loop2    ; Keep looping if not


    LDR     R0, [R2, #MIS]  ; Get the 1us timer value
    MOV32   R2, GPT1		; Make sure that R2 still has the correct address
    CMP     R0, R3
    BNE     tCycle_Loop2    ; If LCD Enable hold time hasn't passed, wait
;   BEQ     HandleHoldTime ; if it passed, reset LCD Enable pin

HandleHoldTime:
    ; Wait 280 ns for data hold time (must be at least 140 ns)
    MOV32   R0, DB_HOLD_TIME    ; Setup a counter

DataBusHoldTimeLoop:
    SUB     R0, #ONE    ; Decrement counter
    CBZ     R0, EndWrite ; Break loop when counter is finished
    B       DataBusHoldTimeLoop ; Keep looping if not

EndWrite:
    STREG   LCD_CMD_CLR, R1, DCLR31_0   ; Clear LCD command pins
    STREG   IRQ_TBTO, R2, ICLR  ; Clear timer B timeout interrupt
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
    MOV32   R1, GPIO    ; Load GPIO and GPT1 (tCycle timer) base addresses
    MOV32   R2, GPT1

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
    MOV32   R3, IRQ_TBTO ; Load timeout interrupt condition
;    MOV32   R3, CTL_TB_AB_STALL ; Load timeout interrupt condition

    MOV32   R2, GPT1
    STREG   CTL_TB_AB_STALL, R2, CTL   ; Enable 1us timer with debug stall

tCycle_Loop1R:               ; Wait the enable hold time
    LDR     R0, [R2, #MIS]  ; Get the 1us timer interrupt status
    MOV32   R2, GPT1		; Make sure that R2 still has the correct address
    CMP     R0, R3
    BNE     tCycle_Loop1R   ; If LCD Enable hold time hasn't passed, wait
;   BEQ     ResetLCDEnableR ; if it passed, reset LCD Enable pin

ResetLCDEnableR:
    MOV32   R2, GPT1
    STREG   IRQ_TBTO, R2, ICLR    ; Clear timer A timeout interrupt

    LDR     R0, [R1, #DIN31_0]         ; Fetch read data in R0
    PUSH    {R0}                       ; Store data in stack
    STREG   LCD_ENABLE, R1, DCLR31_0   ; Reset LCD enable pin

    MOV32   R2, GPT1
    STREG   CTL_TB_AB_STALL, R2, CTL   ; Enable 1us timer with debug stall

    MOV32   R3, IRQ_TBTO    ; 1us timer timeout condition
;    MOV32   R3, CTL_TB_AB_STALL ; Load timeout interrupt condition

tCycle_Loop2R:               ; Wait until tCycle is done
    LDR     R0, [R2, #MIS]  ; Get the 1us timer value
    MOV32   R2, GPT1		; Make sure that R2 still has the correct address
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
    STREG   IRQ_TBTO, R2, ICLR  ; Clear timer A timeout interrupt
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
	LDR		R0, [R1, #DOE31_0]	;Get currently enabled pin
	MOV32	R1, OUTPUT_ENABLE_LCD
	ORR		R0, R1
	MOV32   R1, GPIO                    ; Load base address
	STR   	R0, [R1, #DOE31_0]  ; Reenable all LCD pins as outputs

; B    EndWaitLCDBusy

EndWaitLCDBusy:
	POP     {R0, R1}    ; Pop registers
	BX      LR          ; Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                              ;
;                            Data Section                                      ;
;                                                                              ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    .data

	.global cRow
	.global cCol

;;;;;; Variable Declaration ;;;;;;
	.align 4
charbuffer: .space 12       ; Buffer to store ASCII characters (including negative sign and null terminator)

    .align 4
cRow:   .space 1    ; cRow holds the index of the cursor

    .align 4
cCol:   .space 1    ; cCol holds the index of the column


.end
