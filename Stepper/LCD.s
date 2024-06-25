;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                              ;
;                          EE110a General LCD Functions                        ;
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
;Reference LCD helper functions
    .ref    Wait_1ms         ;   Wait 1 ms
    .ref    LowestLevelWrite ;   Handles an LCD write cycle
    .ref    LowestLevelRead  ;   Handles an LCD read cycle
    .ref    WaitLCDBusy      ;   Waits until the LCD is not busy

	.global cRow
	.global cCol

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                               Table of Contents
;       Function Name   |   Purpose
    .def    Display     ;   Display a string to the LCD
    .def    DisplayChar ;   Display a char to the LCD
    .def    PrepLCD 	;   Prep the LCD to display a number
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Revision History:   02/04/24 George Ore   Created format
;                     05/30/24 George Ore   Ported to EE110a HW3
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

    MOVA    R2, SentenceStringTable ; Start at the beginning of sentence data table
    MOVA    R3, SStringAddressingTable ; and also the sentence addressing table

    LDRB    R0, [R3], #NEXT_BYTE    ; Get the next row index from table and post increment address
    LDRB    R1, [R3], #NEXT_BYTE    ; Get the next column index from table and post increment address
    LDRB    R4, [R3], #NEXT_BYTE    ; Get the address offset to the next word

	PUSH {LR}
    BL      Display                 ; Call the function
	POP {LR}

EndPrepLCD:
	POP {R0, R1, R2, R3, R4}
	BX LR

;PREAMBLE FOR PREPLCD vvvvvvvvvvv
    .align 1
SentenceStringTable:
    .byte       'S', 'T', 'E', 'P', 'P', 'E', 'R', 'P', 'O', 'S',  ':', STRING_END

    .align 1
SStringAddressingTable:    ; Row Col Offset
    .byte                  0,  0,  0xB

.end
