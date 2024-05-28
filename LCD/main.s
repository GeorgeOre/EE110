;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																			   ;
;							EE110 HW3 George Ore							   ;
;																			   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
; Description:      This program configures the CC2652R LaunchPad to connect to
;					a 2x16 LCD on the Glen George TM wire wrap board. It uses
;					table driven code to display some text.
;
; Operation:        The program indexes the address from several tables in order
;					to fetch display function parameters. It feeds all the
;					parameters to the display functions and displays them on
;					LCD. After going through all tables program repeats
;
; Arguments:        None.
;
; Return Values:    None.
;
; Local Variables:  eventID (passed into EnqueueEvent to b placed in the buffer)
;
; Shared Variables: None.
;
; Global Variables: ResetISR (required)
;
; Input:            None.	(but kinda the table data)
;
; Output:           LCD output
;
; Error Handling:   None.
;
; Registers Changed: flags, R0, R1, R2
;
; Stack Depth:       3 words
;
; Algorithms:        None.
;
; Data Structures:   Data tables
;
; Known Bugs:        None.
;
; Limitations:       None.
;
; Revision History:   12/02/23  George Ore      initial version
;                     12/04/23  George Ore      finished inital version
;					  12/05/23	George Ore		fixed bugs
;					  12/06/23	George Ore		fixed bugs, start testing
;					  12/07/23	George Ore		finished launchpad only testing,
;												started testing on wire wrap
;												board but got a loud pop,
;												polished up formatting
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
;	initGPTs()
;   initGPIO()
;
;	LCD_GPIOs = ALL_LOW
;	cRow = ZERO_START
;	cCol = ZERO_START
;
;	initLCD()
;
;	while(1)
;		for CharTable in CharTables
;			for (row, col, charaddress) in CharTable
;				DisplayChar(row, col, charaddress)
;				Wait_1ms(1000)
;		for StringTable in StringTables
;			for (row, col, stringaddress) in StringTable
;				Display(row, col, stringaddress)
;				Wait_1ms(1000)
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Include constant, and macro files
	.include "configPWR&CLK.inc"	;contains power config constants
	.include "configGPIO.inc"	;contains GPIO config constants
	.include "GPIO.inc"			;contains GPIO control constants
	.include "GPT.inc"			;contains GPT control constants
	.include "constants.inc"	;contains misc. constants

	.include "macros.inc"		;contains all macros

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

;;;;;;Init Register Values;;;;;;
;InitRegisters:
	MOV32	R1, GPIO		;Load base address

	STREG   LCD_OUTPUT_EN, R1, DCLR31_0	;Clear all GPIO pins

;;;;;;Init Variable Values;;;;;;
;InitVariables:
	MOVA    R1, cRow	;set starting cursor row index to 0
	MOV32   R0, ZERO_START
	STR     R0, [R1]

	MOVA    R1, cCol	;set starting cursor column index to 0
	MOV32   R0, ZERO_START
	STR     R0, [R1]

;;;;;;Init LCD;;;;;;
;InitLCD:	;The following is LCD function set/startup
	MOV32	R0, WAIT30	;Wait 30 ms (15 ms min)
	BL		Wait_1ms
	BL	WaitLCDBusy
	MOV32	R0, FSET_2LINES_DFONT	;Write function set command
	MOV32	R1, FSET_RS
	BL	LowestLevelWrite

	MOV32	R0, WAIT8	;Wait 8 ms (4.1 ms min)
	BL		Wait_1ms

	MOV32	R0, FSET_2LINES_DFONT	;Write function set command
	MOV32	R1, FSET_RS
	BL	LowestLevelWrite

	MOV32	R0, WAIT1	;Wait 1 ms (100 us min)
	BL		Wait_1ms

	MOV32	R0, FSET_2LINES_DFONT	;Write function set command
	MOV32	R1, FSET_RS
	BL	LowestLevelWrite

;From here we need to wait until the busy flag is reset before excecuting the next command
	BL	WaitLCDBusy
	MOV32	R0, FSET_2LINES_DFONT	;Write function set command
	MOV32	R1, FSET_RS
	BL	LowestLevelWrite

	BL	WaitLCDBusy
	MOV32	R0, LCD_OFF		;Write display off command
	MOV32	R1, LCD_OFF_RS
	BL	LowestLevelWrite

	BL	WaitLCDBusy
	MOV32	R0, CLR_LCD		;Write clear display command
	MOV32	R1, CLR_LCD_RS
	BL	LowestLevelWrite

	BL	WaitLCDBusy
	MOV32	R0, FWD_INC		;Write entry mode set command
	MOV32	R1, ENTRY_RS
	BL	LowestLevelWrite

	BL	WaitLCDBusy
	MOV32	R0, CUR_BLINK	;Write display on command
	MOV32	R1, LCD_ON_RS
	BL	LowestLevelWrite

;;;;;;Main Program;;;;;;
Main:

TestDisplayChar:	;Test the DisplayChar function
;Table of Contents:
;	HWCharTable 	- 	HELLOWORLD
;	WSCharTable		-	WHALESHARK
;	EYVCharTable	-	EATYOURVEGGIES

	MOVA	R3, HWCharTable			;Start at the beginning of table

HWCharTableLoop:
	LDRB	R0, [R3], #NEXT_BYTE	;Get the next row index from table and post increment address
	LDRB	R1, [R3], #NEXT_BYTE	;Get the next column index from table and post increment address
	LDRB	R2, [R3], #NEXT_BYTE	;Get the next char value from table and post increment address
	BL 	DisplayChar 				;Call the function (should increment R2 address)

;	MOV32	R0, WAIT1000	;Wait 1s
;	BL		Wait_1ms

HWCheckDoneTest: ;check if tests done
	MOVA 	R0, EndHWCharTable	;check if at end of table
	CMP 	R3, R0
	BNE 	HWCharTableLoop		;not done with chars, keep looping
	;BEQ 	DoneHWCharTable 	;otherwise done displaying chars

DoneHWCharTable: ;Done testing HWCharTable

	MOV32	R0, WAIT5000	;Wait 5s
	BL		Wait_1ms

	BL	WaitLCDBusy			;Write clear display command
	MOV32	R0, CLR_LCD
	MOV32	R1, CLR_LCD_RS
	BL	LowestLevelWrite

	MOVA	R3, WSCharTable	;Start at the beginning of table

WSCharTableLoop:
	LDRB	R0, [R3], #NEXT_BYTE	;Get the next row index from table and post increment address
	LDRB	R1, [R3], #NEXT_BYTE	;Get the next column index from table and post increment address
	LDRB	R2, [R3], #NEXT_BYTE	;Get the next char value from table and post increment address
	BL 	DisplayChar 				;Call the function (should increment R2 address)

;	MOV32	R0, WAIT1000	;Wait 1s
;	BL		Wait_1ms

WSCheckDoneTest: ;check if tests done
	MOVA 	R0, EndWSCharTable	;check if at end of table
	CMP 	R3, R0
	BNE 	WSCharTableLoop		;not done with chars, keep looping
	;BEQ 	DoneWSCharTable 	;otherwise done displaying chars

DoneWSCharTable: ;Done testing WSCharTable

	MOV32	R0, WAIT5000	;Wait 5s
	BL		Wait_1ms

	BL	WaitLCDBusy			;Write clear display command
	MOV32	R0, CLR_LCD
	MOV32	R1, CLR_LCD_RS
	BL	LowestLevelWrite

	MOVA	R3, EYVCharTable			;Start at the beginning of table

EYVCharTableLoop:
	LDRB	R0, [R3], #NEXT_BYTE	;Get the next row index from table and post increment address
	LDRB	R1, [R3], #NEXT_BYTE	;Get the next column index from table and post increment address
	LDRB	R2, [R3], #NEXT_BYTE	;Get the next char value from table and post increment address
	BL 	DisplayChar 				;Call the function (should increment R2 address)

;	MOV32	R0, WAIT1000	;Wait 1s
;	BL		Wait_1ms

EYVCheckDoneTest: ;check if tests done
	MOVA 	R0, EndEYVCharTable	;check if at end of table
	CMP 	R3, R0
	BNE 	EYVCharTableLoop		;not done with chars, keep looping
	;BEQ 	DoneEYVCharTable 	;otherwise done displaying chars

DoneEYVCharTable: ;Done testing EYVCharTable

	MOV32	R0, WAIT5000	;Wait 5s
	BL		Wait_1ms

	BL	WaitLCDBusy			;Write clear display command
	MOV32	R0, CLR_LCD
	MOV32	R1, CLR_LCD_RS
	BL	LowestLevelWrite

TestDisplay:	;Test the Display function
;Table of Contents:
;	WordStringTable 	-	'WELCOME', 'TO', 'GORE_OS', 'PLEASE', 'SELECT', 'A', 'FUNCTION', 'WITH', 'THE', 'KEYPAD'
;		^^WStringAddressingTable
;	SentenceStringTable	-	'WELCOME TO', 'GORE_OS', 'PLEASE SELECT A', 'FUNCTION WITH', 'THE KEYPAD'
;		^^SStringAddressingTable
;	MenuDisplayDataTable	-	'SNAKE', 'MUSICALSNAKE', 'SNAKE2'

	MOVA	R2, WordStringTable	;Start at the beginning of word data table
	MOVA	R3, WStringAddressingTable	;and also the word addressing table

WStringTableLoop:
	LDRB	R0, [R3], #NEXT_BYTE	;Get the next row index from table and post increment address
	LDRB	R1, [R3], #NEXT_BYTE	;Get the next column index from table and post increment address
	LDRB	R4, [R3], #NEXT_BYTE	;Get the address offset to the next word

	BL 	Display 				;Call the function (should increment R2 address)

	ADD		R2, R4					;Add offset to the string address

	MOV32	R0, WAIT1000	;Wait 1s
	BL		Wait_1ms

WStrCheckDoneTest: ;check if tests done
	MOVA 	R0, EndWStringAddressingTable	;check if at end of table
	CMP 	R3, R0
	BNE 	WStringTableLoop	;not done with strings, keep looping
	;BEQ 	DoneWStringTable 	;otherwise done displaying strings

DoneWStringTable: ;Done testing WStringTable

	MOV32	R0, WAIT5000	;Wait 5s
;	BL		Wait_1ms

	BL	WaitLCDBusy			;Write clear display command
	MOV32	R0, CLR_LCD
	MOV32	R1, CLR_LCD_RS
	BL	LowestLevelWrite

	MOVA	R2, SentenceStringTable	;Start at the beginning of sentence data table
	MOVA	R3, SStringAddressingTable	;and also the sentence addressing table

SStringTableLoop:
	LDRB	R0, [R3], #NEXT_BYTE	;Get the next row index from table and post increment address
	LDRB	R1, [R3], #NEXT_BYTE	;Get the next column index from table and post increment address
	LDRB	R4, [R3], #NEXT_BYTE	;Get the address offset to the next word

	BL 		Display 				;Call the function

	ADD		R2, R4					;Add offset to index the next string address

	MOV32	R0, WAIT1000	;Wait 5s
	BL		Wait_1ms

SStrCheckDoneTest: ;check if tests done
	MOVA 	R0, EndSStringAddressingTable	;check if at end of table
	CMP 	R3, R0
	BNE 	SStringTableLoop	;not done with strings, keep looping
	;BEQ 	DoneSStringTable 	;otherwise done displaying strings

DoneSStringTable: ;Done testing SStringTable

	MOV32	R0, WAIT5000	;Wait 5s
	BL		Wait_1ms

	BL	WaitLCDBusy			;Write clear display command
	MOV32	R0, CLR_LCD
	MOV32	R1, CLR_LCD_RS
	BL	LowestLevelWrite

;Add menu table driven code here

	B	Main	;Loop forever



;*******************************************************************************
;*							USED FUNCTIONS									   *
;*******************************************************************************
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Display:
;
; Description:	The function is passed a <null=0x00> terminated string (str) to
;				output to the LCD at the passed row (r) and column (c). If the
;				row and column are both -1, the string is output starting at
;				the current cursor position. The cursor position is always
;				updated to the position after the last character in the string.
;
; Operation:    The	string is passed by reference in R2 (i.e. the address of the
;				string is R2). The row (r) is passed in R0 by value and the
;				column (c) is passed in R1 by value. First the amount of
;				characters in the string is counted. Then the function calls
;				DisplayChar for every char in the string.
;
; Arguments:         R0 - Row (-1 if cursor row)
;					 R1 - Column (-1 if cursor column)
;					 R2 - Data address of the string
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
;					 Invalid indexes are ignored - Done inside DisplayChar
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
; Revision History:  12/6/23	George Ore	 created
;					 12/7/23	George Ore	 fixed bugs
;					 12/8/23	George Ore	 fixed bugs & format
;
; Pseudo Code
;
;	(ARGS: R0 = rowindex, R1 = colindex, R2 = stringaddress)
;	counter = 0
;	for char in string
;		counter++
;	while(counter!=0)
;		displayChar(R0 = rowindex, R1 = colindex, R2 = stringaddress))
;		counter--
Display:
	PUSH    {R0, R1, R2, R3, R4, R5, R6}	;Push registers

	MOV32	R3, ZERO_START	;Start a counter to count chars
	MOV		R5, R2			;Copy address in R5
	LDRSB	R4, [R5], #NEXT_CHAR	;Get first char data
							;then post increment to next char address
	MOV32	R6, STRING_END	;Load end of string condition

CountChars:
	CMP		R4, R6			;Test if string has ended
	BEQ		CharsCounted	;If string ended, go to chars counted label
	;BNE	AddChar			;If not, increment char counter

AddChar:
	ADD		R3, #ONE				;Increment char counter
	LDRB	R4, [R5], #NEXT_CHAR	;Load next char and update address
	B		CountChars				;Keep counting chars

CharsCounted:	;All chars in string have been counted. Result is in R3
	;We will now handle each char individually and count down until finished
	MOV32	R6, COUNT_DONE	;Load count down done condition
	MOV		R5, R2			;Save address in R5 again

DisplayLoop:
	CMP		R3, R6			;Test if all chars in string have been handled
	BEQ		End_Display		;If they have, end Display
	;BNE	DispCurChar		;If not, display current char

DispCurChar:
	LDRSB	R2, [R5], #ONE	;Load char data onto R2 for DisplayChar
							;then post increment R5 by one byte
	PUSH	{LR}		;Calling function inside function requires PUSH LR
	BL		DisplayChar	;Display current char
	POP		{LR}		;POP LR

	SUB		R3, #ONE	;Decrement char count

	MOV32	R0, CINDEX	;Set row and column to follow newly set cursor pos
	MOV32	R1, CINDEX

	B		DisplayLoop

End_Display:
	POP    	{R0, R1, R2, R3, R4, R5, R6}	;Pop registers
	BX		LR			;Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; DisplayChar:
;
; Description:	The function is passed a character (ch) to output to the LCD at
;				the passed position (row r and column c). If the row and column
;				are both -1, the character is output at the current cursor
;				position. The cursor position is always updated to the position
;				after the character.
;
; Operation:    The row (r) is passed in R0 by value and the column (c) is
;				passed in R1 by value. The character (ch) is passed in R2 by
;				value.
;
; Arguments:         R0 - Row (-1 if cursor row)
;					 R1 - Column (-1 if cursor column)
;					 R2 - Char data
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
;					 Ignores invalid index inputs
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
; Revision History:  12/6/23	George Ore	 created
; 					 12/7/23	George Ore	 fixed bugs
; 					 12/8/23	George Ore	 fixed bugs and format
; 					 01/5/24	George Ore	 revamped input testing
;
; Pseudo Code
;
;	(ARGS: R0 = row, R1 = col, R2 = char)
;	if (row, col, or char) in {invalid args}
;		return
;	if row == -1
;		row = cRow
;	if col == -1
;		col = cCol
;
;	LowestLevelWrite(SetDDRAM, calcaddress(row, col))
;	LowestLevelWrite(WriteDDRAM, char)
;
;	cRow = row
;	if col == maxColIndex
;		cCol = Col0	;wrap
;	else
;		cCol++
DisplayChar:
	PUSH    {R0, R1, R2, R3, R4}	;Push registers

;Handle cursor indexing first before running valid input tests
;CRowTest:
	MOV32	R3, CINDEX	;Load cursor index test value
	CMP		R0, R3
	BNE	  CColTest	;If the row input did not index the cursor, test the column
	;BEQ	CRowSet	;If not, set row index as the cursor value

;CRowSet:
	MOVA	R4, cRow	;Set R0 with cursor row index
	LDR		R0, [R4]
	;B		CColTest

CColTest:
	;R3 still contains the cursor index test value
	CMP		R1, R3
	BNE	  	MinIndexTest	;If the column input did not index the cursor, start validation tests
	;BEQ	CColSet			;If not, set column index as the cursor value

;CColSet:
	MOVA	R4, cCol		;Set R1 with cursor column index
	LDR		R1, [R4]
	;B		MinIndexTest	;Proceed to set the character on the LCD

;Invalid input error handling
;	Error handling is to not set the character and return
;1. Test lower input limits
;	- Test row input (R0), column input (R1), and char value input (R2) for
;	  values lower than the minimum valid input
;2. Test upper input limits
;	- Test row input (R0), column input (R1), and char value input (R2) for
;	  values higher than the maximum valid input
;3. Character invalid midband
;	- Besides having an upper and lower limit, char values also have a band
;	  between 01111111-10100000 non-inclusive that is invalid

MinIndexTest:
	MOV32	R3, MIN_INDEX	;Load minimum index value (for both row & col)

	CMP		R0, R3	;The row index input is invalid if row < minimum index
	BLT		End_DisplayChar	;If row input is invalid, simply return as error handling

	CMP		R1, R3	;The column index input is invalid if col < minimum index
	BLT		End_DisplayChar	;If column input is invalid, simply return as error handling

	MOV32	R3, MIN_CHAR	;Load minimum character value

	CMP		R2, R3	;The character value is invalid if char < minimum index
	BLT		End_DisplayChar	;If character value is invalid, simply return as error handling

	;B		MaxIndexTest	;If tests are passed, test for max indexes

;MaxIndexTest:
	MOV32	R3, MAX_RINDEX	;Load maximum row index value
	CMP		R0, R3	;The row index input is invalid if row > maximum index
	BGT		End_DisplayChar	;If row input is invalid, simply return as error handling

 	MOV32	R3, MAX_CINDEX	;Load maximum column index value
	CMP		R1, R3	;The column index input is invalid if col > maximum index
	BGT		End_DisplayChar	;If column input is invalid, simply return as error handling

 	MOV32	R3, MAX_CHAR	;Load maximum character value
	CMP		R2, R3	;The character value is invalid if char > maximum index
	BGT		End_DisplayChar	;If character value is invalid, simply return as error handling

	;B		LowerBandTest	;If tests are passed, test the character band

;LowerBandTest:
 	MOV32	R3, LOW_CHARBAND	;Load lower character band limit
	CMP		R2, R3	;Test character against lower band limit
	BLE		ValidInputs	;If the character <= lower character band limit, it is valid
	;BGT		UpperBandTest	;If not, test it against the upper band limit

;UpperBandTest:
 	MOV32	R3, HIGH_CHARBAND	;Load upper character band limit
	CMP		R2, R3	;Test character against upper band limit
	BLT		End_DisplayChar	;If the character < upper character band limit,
							;then the character value is inside the invalid
							;character band and is invalid, simply return as
							;error handling
	;BGE	ValidInputs		;If not, it is valid

ValidInputs:
;Cursor index handling
;	This section assumes cRow and cCol now contain valid data

SetChar:
	PUSH	{R0, R1}	;Save indexes for later

;The LCD only takes in 0x00 or 0x40 (index 0 or 1) for row addressing
	LSL		R0, #ROWADDRESSSHIFT	;Shifting our index left can accommodate
;LCD addresses columns directly as indexes from 0-15
	ADD		R0, R1	;Simply add to row addressing to combine address

	LSL		R0, #GPIOSHIFT	;Shift address to align with corresponding GPIOs
	ADD		R0, #SETDDRAMBIT	;Add the addressing function DDRAM bit to address
	MOV32	R1, SETDDRAM_RS	;Prepare the addressing function RS value
	PUSH	{LR}	;Call WaitLCDBusy
	BL	WaitLCDBusy
	POP		{LR}	;Will make sure that LCD is ready to receive a command
	PUSH	{LR}	;Call LowestLevelWrite
	BL LowestLevelWrite	;(ARGS: R0 = FunctionData R1 = FunctionRS)
	POP		{LR}	;Will set the correct address to the LCD register

	MOV		R0, R2	;Prepare the character data input for LowestLevelWrite
	LSL		R0, #GPIOSHIFT	;Shift character data to align with corresponding GPIOs
	MOV32	R1, WRITEDDRAM_RS	;Prepare the writing function RS value
	PUSH	{LR}	;Call WaitLCDBusy
	BL	WaitLCDBusy
	POP		{LR}	;Will make sure that LCD is ready to receive a command
	PUSH	{LR}	;Call LowestLevelWrite
	BL LowestLevelWrite	;(ARGS: R0 = FunctionData R1 = FunctionRS)
	POP		{LR}	;Will write the character data to the set LCD address

	;B		UpdateCursor	;Proceed to update cursor index

;UpdateCursor:
	POP		{R0, R1}	;Fetch indexes from earlier

;UpdateCCurTest:
	MOV32	R3, MAX_CINDEX	;Test if cursor column index is at the boundary
	CMP		R1, R3
	BNE		UpdateCCur	;If it is not, do an incremental cursor update
	;BEQ	WrapCCur	;if it is, wrap the cursor column to initial index

WrapCCur:
	MOV32	R1, CCOL0	;Prepare column to be set to initial
	B UpdateCurVars

UpdateCCur:
	ADD		R1, #ONE
	;B UpdateCurVars

UpdateCurVars:
	MOVA	R3, cRow
	STR		R0, [R3]
	MOVA	R3, cCol
	STR		R1, [R3]

End_DisplayChar:
	POP    	{R0, R1, R2, R3, R4}	;Pop registers
	BX		LR			;Return

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
; Revision History:  12/7/24	George Ore	 created
;					 12/8/24	George Ore	 formated, moved to HW5
;					 01/2/24	George Ore	 made interrupt driven to fix
;											 skipping error and moved to HW4
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
	MOV32	R4, IRQ_TATO	;Load NOT1ms timer doneNOT timeout interrupt condition

W_1ms_Cntr_Loop:
	CMP		R1, R3			;Check if the ms counter is done
	BEQ		End_1ms_Wait	;If it is, end wait
	;BNE	Reset_1ms_Timer	;if not reset the 1ms timer

Reset_1ms_Timer:
	STREG   CTL_TA_STALL, R2, CTL	;Enable timer with debug stall

W_1ms_Timr_Loop:
	LDR		R0, [R2, #MIS]	;Get the masked interrupt status
	CMP		R0, R4			;Check if timeout interrupt has happened
	BNE		W_1ms_Timr_Loop	;If 1ms hasn't passed, wait
	;BEQ	DecCounter		;If 1ms passed, decrement the cntr

DecCounter:
	STREG   IRQ_TATO, R2, ICLR  	;Clear timer A timeout interrupt
	SUB		R1, #ONE	;Decrement the counter and go back to
	B		W_1ms_Cntr_Loop	;counter value check

End_1ms_Wait:
	POP    	{R0, R1, R2, R3, R4}	;Pop registers
	BX		LR			;Return

; LowestLevelWrite:
;
; Description:	This procedure places an inputed eventID into the keybuffer
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
; Known Bugs:        None.
;
; Limitations:       Will be a blocking function for 1us for the tCycle
;
; Revision History:  12/6/23	George Ore	 Created
; 					 01/5/24	George Ore	 Set GPIO with DSET31_0
;											 instead of using DOUT
;											 Added interrupt timer timeout
;
; Pseudo Code
;
;	while(counter!=0)
;		reset TAR
;		while(TAR!=0)
;			NOP
;		counter--
LowestLevelWrite:	;R0 = 8 bit data busdata; R1 = RS value
	PUSH {R0, R1, R2, R3}		;Push registers

	MOV32	R3, EMPTY	;We will store RS and databus values into R3 *MAYBE USE MOV
	ADD		R3, R0, R1

	MOV32	R1, GPIO	;Load GPIO and GPT1 (tCycle timer) base addresses
	MOV32	R2, GPT1
	STR   	R3, [R1, #DSET31_0]	;Write RS and databus onto LCD

;HandleSetupTime:
	;Wait 280 ns setup time (must be at least 140 ns)
	MOV32	R0, DB_SETUP_TIME	;Setup a counter

DataBusSetupTimeLoop:
	SUB		R0, #ONE	;Decrement counter
	CBZ		R0, DataSetupDone	;Break loop when counter is finished
	B		DataBusSetupTimeLoop	;Keep looping if not

DataSetupDone:
	;assume that enable rise/fall is under 25 ns (1 cpu clock)
	STREG   LCD_ENABLE, R1, DSET31_0	;Set LCD enable pin

	MOV32	R3, ENABLE_HOLD	;Load LCD Enable hold time condition

	STREG   CTL_TA_STALL, R2, CTL	;Enable 1us timer with debug stall

tCycle_Loop1:				;Wait the enable hold time
	LDR		R0, [R2, #TAR]	;Get the 1us timer value
	CMP		R0, R3
	BGE		tCycle_Loop1	;If LCD Enable hold time hasn't passed, wait
	;BNE	ResetLCDEnable	;if it passed, reset LCD Enable pin

ResetLCDEnable:
	STREG	LCD_ENABLE, R1, DCLR31_0	;Reset LCD enable pin

	MOV32	R3, IRQ_TATO	;1us timer timeout condition

tCycle_Loop2:				;Wait until tCycle is done
	LDR		R0, [R2, #MIS]	;Get the 1us timer value
	CMP		R0, R3
	BNE		tCycle_Loop2	;If LCD Enable hold time hasn't passed, wait
	;BEQ	HandleHoldTime	;if it passed, reset LCD Enable pin

;HandleHoldTime:
	;Wait 280 ns for data hold time (must be at least 140 ns)
	MOV32	R0, DB_HOLD_TIME	;Setup a counter

DataBusHoldTimeLoop:
	SUB		R0, #ONE	;Decrement counter
	CBZ		R0, EndWrite	;Break loop when counter is finished
	B		DataBusHoldTimeLoop	;Keep looping if not

EndWrite:
	STREG LCD_CMD_CLR, R1, DCLR31_0	;Clear LCD command pins
	STREG IRQ_TATO, R2, ICLR	;Clear timer A timeout interrupt
	POP {R0, R1, R2, R3}	;Pop registers
	BX	LR		;Return


; LowestLevelRead:
;
; Description:	This procedure places an inputed eventID into the keybuffer
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
; Known Bugs:        None.
;
; Limitations:       Will be a blocking function for 1us for the tCycle
;
; Revision History:  12/6/23	George Ore	 Created
; 					 01/5/24	George Ore	 Set GPIO with DSET31_0
;											 instead of using DOUT
;											 Added interrupt timer timeout
;
; Pseudo Code
;
;	while(counter!=0)
;		reset TAR
;		while(TAR!=0)
;			NOP
;		counter--
LowestLevelRead:	;R0 = 8 bit data busdata; R1 = RS value
	PUSH {R1, R2, R3}		;Push registers
;ASSUMES THAT IT IS IN READ MODE
	MOV32	R1, GPIO	;Load GPIO and GPT1 (tCycle timer) base addresses
	MOV32	R2, GPT1

;	MOV32	R3, LCD_READ	;Enable read mode
;	STR   	R3, [R1, #DSET31_0]

;HandleSetupTimeR:
	;Wait 280 ns setup time (must be at least 140 ns)
	MOV32	R0, DB_SETUP_TIME	;Setup a counter

DataBusSetupTimeLoopR:
	SUB		R0, #ONE	;Decrement counter
	CBZ		R0, DataSetupDoneR	;Break loop when counter is finished
	B		DataBusSetupTimeLoopR	;Keep looping if not

DataSetupDoneR:
	;assume that enable rise/fall is under 25 ns (1 cpu clock)
	STREG   LCD_ENABLE, R1, DSET31_0	;Set LCD enable pin

	MOV32	R3, ENABLE_HOLD	;Load LCD Enable hold time condition

	STREG   CTL_TA_STALL, R2, CTL	;Enable 1us timer with debug stall

tCycle_Loop1R:				;Wait the enable hold time
	LDR		R0, [R2, #TAR]	;Get the 1us timer value
	CMP		R0, R3
	BGE		tCycle_Loop1R	;If LCD Enable hold time hasn't passed, wait
	;BNE	ResetLCDEnableR	;if it passed, reset LCD Enable pin

ResetLCDEnableR:
	LDR		R0, [R1, #DIN31_0]			;Fetch read data in R0
	PUSH {R0}							;Store data in stack
	STREG	LCD_ENABLE, R1, DCLR31_0	;Reset LCD enable pin

	MOV32	R3, IRQ_TATO	;1us timer timeout condition

tCycle_Loop2R:				;Wait until tCycle is done
	LDR		R0, [R2, #MIS]	;Get the 1us timer value
	CMP		R0, R3
	BNE		tCycle_Loop2R	;If LCD Enable hold time hasn't passed, wait
	;BEQ	HandleHoldTimeR	;if it passed, reset LCD Enable pin

;HandleHoldTimeR:
	;Wait 280 ns for data hold time (must be at least 140 ns)
	MOV32	R0, DB_HOLD_TIME	;Setup a counter

DataBusHoldTimeLoopR:
	SUB		R0, #ONE				;Decrement counter
	CBZ		R0, EndRead				;Break loop when counter is finished
	B		DataBusHoldTimeLoopR	;Keep looping if not

EndRead:
	STREG IRQ_TATO, R2, ICLR	;Clear timer A timeout interrupt
	POP {R0}	;Pop read data
	POP {R1, R2, R3}	;Pop registers
	BX	LR		;Return

; WaitLCDBusy:
;
; Description:	This procedure places an inputed eventID into the keybuffer
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
; Known Bugs:        None.
;
; Limitations:       Will be a blocking function for 1us for the tCycle
;
; Revision History:  12/6/23	George Ore	 Created
; 					 01/5/24	George Ore	 Set GPIO with DSET31_0
;											 instead of using DOUT
;											 Added interrupt timer timeout
;
; Pseudo Code
;
;	while(counter!=0)
;		reset TAR
;		while(TAR!=0)
;			NOP
;		counter--
WaitLCDBusy:	;R0 = 8 bit data busdata; R1 = RS value
	PUSH {R0, R1}		;Push registers

	;Disable output pins
	MOV32	R1, GPIO					;Load base address
	STREG   NOT_LCD_DATA_PINS, R1, DOE31_0	;Disable LCD data pins as outputs

	;Configure LCD data pin 7 as an input
	MOV32	R1, IOC						;Load base address
;	STREG   IO_IN_CTRL,  R1, IOCFG8		;Set LCD Data7 (GPIO pin 15) as an input
;	STREG   IO_IN_CTRL,  R1, IOCFG9		;Set LCD Data7 (GPIO pin 15) as an input
;	STREG   IO_IN_CTRL,  R1, IOCFG10	;Set LCD Data7 (GPIO pin 15) as an input
;	STREG   IO_IN_CTRL,  R1, IOCFG11	;Set LCD Data7 (GPIO pin 15) as an input
;	STREG   IO_IN_CTRL,  R1, IOCFG12	;Set LCD Data7 (GPIO pin 15) as an input
;	STREG   IO_IN_CTRL,  R1, IOCFG13	;Set LCD Data7 (GPIO pin 15) as an input
;	STREG   IO_IN_CTRL,  R1, IOCFG14	;Set LCD Data7 (GPIO pin 15) as an input
	STREG   IO_IN_CTRL,  R1, IOCFG15	;Set LCD Data7 (GPIO pin 15) as an input
	;B	CheckBusyFlag

CheckBusyFlag:
	MOV32	R1, GPIO					;Load base address
	STREG   LCD_READ, R1, DSET31_0		;Set read mode
;	STREG   LCD_ENABLE, R1, DSET31_0	;Enable read

CheckBusyFlagLoop:
	PUSH	{LR}	;Call LowestLevelRead
	BL	LowestLevelRead
	POP		{LR}	;Will read into R0

	AND		R0, #LCD_BUSYFLAG	;Filer to busy flag bit
	CBZ		R0, LCDNotBusy	;Break loop when busy flag is reset
	B	CheckBusyFlagLoop	;Keep looping if not

LCDNotBusy:
;	STREG   LCD_ENABLE, R1, DCLR31_0	;Disable read
	STREG   LCD_READ, R1, DCLR31_0		;Disable read mode

	;Reconfigure LCD data pin 7 as an output
	MOV32	R1, IOC						;Load base address
;	STREG   IO_OUT_CTRL,  R1, IOCFG8		;Set LCD Data7 (GPIO pin 15) as an input
;	STREG   IO_OUT_CTRL,  R1, IOCFG9		;Set LCD Data7 (GPIO pin 15) as an input
;	STREG   IO_OUT_CTRL,  R1, IOCFG10	;Set LCD Data7 (GPIO pin 15) as an input
;	STREG   IO_OUT_CTRL,  R1, IOCFG11	;Set LCD Data7 (GPIO pin 15) as an input
;	STREG   IO_OUT_CTRL,  R1, IOCFG12	;Set LCD Data7 (GPIO pin 15) as an input
;	STREG   IO_OUT_CTRL,  R1, IOCFG13	;Set LCD Data7 (GPIO pin 15) as an input
;	STREG   IO_OUT_CTRL,  R1, IOCFG14	;Set LCD Data7 (GPIO pin 15) as an input
	STREG   IO_OUT_CTRL,  R1, IOCFG15	;Set LCD Data7 (GPIO pin 15) as an output

	;Disable output pins
	MOV32	R1, GPIO				;Load base address
	STREG   LCD_OUTPUT_EN, R1, DOE31_0	;Reenable all LCD pins as outputs

	;B	EndWaitLCDBusy

EndWaitLCDBusy:
	POP {R0, R1}	;Pop registers
	BX	LR		;Return

; InitPower:
;
;
; Description:	This function initalizes the peripheral power.
;
; Operation:    Writes to the power control registers and waits until status on
;
; Arguments:         None
; Return Values:     None.
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
; Registers Changed: Power control registers, R0, R1
; Stack Depth:       1 word
;
; Algorithms:        None.
; Data Structures:   None.
;
; Revision History:  12/4/23	George Ore	 added documentation
;
; Pseudo Code
;
;	PDCTL0 is writen to in order to turn power on
;	peripheral power turned on
;
;	Wait until power is on
;	test = poweron		;Load test constant
;
;	Load PDSTAT0 to check if power is on
;	stat = PDSTAT0
;
;	while(test!=stat) 	;Compare test constant with PDSTAT0
;		stat = PDSTAT0	;Keep looping if power is not on
;	BX		LR 				;Return
InitPower:
	;PDCTL0 is writen to in order to turn power on
	MOV32	R1, PRCM					;Load base address
	STREG   PERIF_PWR_ON, R1, PDCTL0	;peripheral power turned on

WaitPON:					;Wait until power is on
	MOV32 	R0, PERIF_STAT_ON	;Load test constant

	MOV32	R2, PRCM		;Load PDSTAT0 to check if power is on
	LDR		R1, [R2,#PDSTAT0]

	SUB   	R0, R1 			;Compare test constant with PDSTAT0
	CMP 	R0, #0
	BNE		WaitPON			;Keep looping if power is not on
	BX		LR 				;Return

; InitClocks:
;
; Description:	This function initalizes the required clocks.
;
; Operation:    Writes to the clock control registers.
;
;
; Arguments:         None
; Return Values:     None.
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
; Registers Changed: Clock control registers, R0, R1
; Stack Depth:       1 word
;
; Algorithms:        None.
; Data Structures:   None.
;
; Revision History:  12/4/23	George Ore	 Added documentation
;
; Pseudo Code
;
;	Write to GPIOCLKGR to turn on the GPIO clock power
;	Write to GPTCLKGR to turn on the GPT clock power
;	Write to CLKLOADCTL to turn on GPIO clock
;
;	;Wait for clock settings to be set
;	test =  CLOCKS_LOADED	;Load success condition
;
;	;Load CLKLOADCTL to check if settings have loaded successfully
;	stat = PDSTAT0
;
;	while(test!=stat) 		;Compare test constant with PDSTAT0
;		stat = CLKLOADCTL	;Keep looping if loading
;	BX		LR 				;Return
InitClocks:
	MOV32	R1, PRCM					;Load base address
	;Write to GPIOCLKGR to turn on the GPIO clock power
	STREG   GPIO_CLOCK_ON, R1, GPIOCLKGR	;GPIO clock power on
	;Write to GPTCLKGR to turn on the GPT clock power
	STREG   GPT01_CLK_ON, R1, GPTCLKGR	;GPT0 and GPT1 clocks power on
	;Write to CLKLOADCTL to turn on GPIO clock
	STREG   LOAD_CLOCKS, R1, CLKLOADCTL		;Load clock settings

WaitCLKPON:						;Wait for clock settings to be set
	MOV32 	R0, CLOCKS_LOADED	;Load success condition

	MOV32	R2, PRCM			;Read CLKLOADCTL to check if settings
	LDR		R1, [R2,#CLKLOADCTL];have loaded successfully

	SUB   	R0, R1 				;Compare test condition with CLKLOADCTL
	CMP 	R0, #0
	BNE	WaitCLKPON				;Keep looping if still loading

	BX		LR					;Return

; InitGPIO
;
; Description:	This function initalizes the GPIO pins.
;
; Operation:    Writes to the GPIO control registers.
;
;
; Arguments:         None
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             Constants defining GPIO controls
; Output:            Writes to GPIO control registers
;
; Error Handling:    None.
;
; Registers Changed: GPIO control registers, R0, R1
; Stack Depth:       1 word
;
; Algorithms:        None.
; Data Structures:   None.
;
; Revision History:  12/4/23	George Ore	 added documentation
; 				  	 01/5/23	George Ore	 removed pins 16-17 from being used
;
; Pseudo Code
;
;	Write to IOCFG0-3 to be row testing outputs
;	Load base address
;	Set GPIO pin 0 as an output
;	Set GPIO pin 1 as an output
;	Set GPIO pin 2 as an output
;	Set GPIO pin 3 as an output
;
;	Write to IOCFG4-7 to be column testing inputs
;	Set GPIO pin 4 as an input with pullup resistor
;	Set GPIO pin 5 as an input with pullup resistor
;	Set GPIO pin 6 as an input with pullup resistor
;	Set GPIO pin 7 as an input with pullup resistor
;
;	Write to DOE31_0 to enable the LED outputs
;	Load base address
;	Enable pins 0-3 as outputs
;	BX		LR			;Return
InitGPIO:
	;Write to IOCFG8-15 to be databus outputs
	MOV32	R1, IOC						;Load base address
	STREG   IO_OUT_CTRL, R1, IOCFG8		;Set GPIO pin 8 as an output
	STREG   IO_OUT_CTRL, R1, IOCFG9		;Set GPIO pin 9 as an output
	STREG   IO_OUT_CTRL, R1, IOCFG10	;Set GPIO pin 10 as an output
	STREG   IO_OUT_CTRL, R1, IOCFG11	;Set GPIO pin 11 as an output
	STREG   IO_OUT_CTRL, R1, IOCFG12	;Set GPIO pin 12 as an output
	STREG   IO_OUT_CTRL, R1, IOCFG13	;Set GPIO pin 13 as an output
	STREG   IO_OUT_CTRL, R1, IOCFG14	;Set GPIO pin 14 as an output
	STREG   IO_OUT_CTRL, R1, IOCFG15	;Set GPIO pin 15 as an output

;***AVOID GPIO 16 and 17 because they are used for debugging

	;Write to IOCFG18 to be chip enable (E) output
	STREG   IO_OUT_CTRL, R1, IOCFG18	;Set GPIO pin 18 as an output

	;Write to IOCFG19 to be register select (RW) output
	STREG   IO_OUT_CTRL, R1, IOCFG19	;Set GPIO pin 19 as an output

	;Write to IOCFG20 to be register select (RS) output
	STREG   IO_OUT_CTRL, R1, IOCFG20	;Set GPIO pin 20 as an output

	;Write to DOE31_0 to enable pins 8-15 and 18-19 as outputs
	MOV32	R1, GPIO					;Load base address
	STREG   LCD_OUTPUT_EN, R1, DOE31_0	;Enable LCD control pins as outputs

	BX		LR							;Return

; InitGPTs
;
; Description:	This function initalizes the GPT0 and GPT1 with interrupts.
;
; Operation:    Writes to the GPT0, GPT1, and SCS control registers.
;
;
; Arguments:         None
; Return Values:     None.
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
; Registers Changed: GPT0, GPT1, and SCS control registers, R0, R1
; Stack Depth:       1 word
;
; Algorithms:        None.
; Data Structures:   None.
;
; Revision History:  12/4/23	George Ore	 added documentation
; 					 01/5/23	George Ore	 made timers interrupt tested
;
; Pseudo Code
;
;	Load base address
;	32 bit timer
;	Enable timer with debug stall
;	Enable timeout interrupt
;	Enable periodic mode
;	Set timer duration to 1ms
;	BX	LR			;Return
InitGPTs:
	;GPT0 will be our 1ms timer
	MOV32	R1, GPT0					;Load base address
	STREG   CFG_32x1, R1, CFG			;32 bit timer
	STREG   TAMR_D_ONE_SHOT, R1, TAMR	;Enable one-shot mode countdown mode
	STREG   TIMER32_1ms, R1, TAILR		;Set timer duration to 1ms
	STREG   IMR_TA_TO, R1, IMR			;Enable timeout interrupt

	;GPT1 will be our 1us tCycle timer (for write operation timing)
	MOV32	R1, GPT1					;Load base address
	STREG   CFG_16x2, R1, CFG			;32 bit timer
	STREG 	TAMR_D_ONE_SHOT, R1, TAMR	;Enable timer one-shot countdown mode
	STREG   TIMER32_1us, R1, TAILR		;Set timer duration to 1us
	STREG   IMR_TA_TO, R1, IMR			;Enable timeout interrupt

	BX	LR							;Return


;;;;;;Testing Tables;;;;;;
	.align 1
CharTable:
	.byte		'H', 'E', 'L', 'L', 'O', 'W', 'O', 'R', 'L', 'D', STRING_END
;	.byte		W, H, A, L, E, S, H, A, R, K
;	.byte		E, A, T, Y, O, U, R, V, E, G, G, I, E, S
ENDCharTable:


	.align 1
HWCharTable:	;Row Col Char	Row Col Char	Row Col Char	Row Col Char
	.byte		-1,	-1,	'H', 	-1,	-1,	'E', 	-1,	-1,	'L', 	-1,	-1,	'L'
	.byte		-1,	-1,	'O', 	-1,	-1,	'W', 	-1,	-1,	'O', 	-1,	-1,	'R'
	.byte		-1,	-1,	'L', 	-1,	-1,	'D'
EndHWCharTable:

	.align 1
WSCharTable:	;Row Col Char	Row Col Char	Row Col Char	Row Col Char
	.byte		0,	0,	'W',	0,	1,	'H',	0,	2,	'A',	0,	3,	'L'
	.byte		0,	4,	'E',	1,	0,	'S',	1,	2,	'H',	1,	4,	'A'
	.byte		1,	6,	'R',	1,	8,	'K'
EndWSCharTable:

	.align 1
EYVCharTable:	;Row Col Char	Row Col Char	Row Col Char	Row Col Char
	.byte		0,	2,	'E',	-1,	-1,	'A',	-1,	-1,	'T',	0,	7,	'Y'
	.byte		-1,	-1,	'O',	-1,	-1,	'U',	-1,	-1,	'R',	1,	3,	'V'
	.byte		-1,	-1,	'E',	-1,	-1,	'G',	-1,	-1,	'G',	-1,	-1,	'I'
	.byte		-1,	-1,	'E',	-1,	-1,	'I',	-1,	-1,	'E',	-1,	-1,	'S'
EndEYVCharTable:

	.align 1
WordStringTable:
	.byte		'W', 'E', 'L', 'C', 'O', 'M', 'E', STRING_END, 'T', 'O', STRING_END, 'G', 'O'
	.byte		'R', 'E', '_', 'O', 'S', STRING_END, 'P', 'L', 'E', 'A', 'S', 'E', STRING_END
	.byte		'S', 'E', 'L', 'E', 'C', 'T', STRING_END, 'A', STRING_END, 'F', 'U', 'N', 'C'
	.byte		'T', 'I', 'O', 'N', STRING_END, 'W', 'I', 'T', 'H', STRING_END, 'T', 'H', 'E'
	.byte		STRING_END, 'K', 'E', 'Y', 'P', 'A', 'D', STRING_END
EndWordStringTable:

	.align 1
WStringAddressingTable:	;Row Col Offset	Row Col	Offset	Row Col	Offset
	.byte				 0,	 0,	 0x8,	0,	8,	0x3,	1,	0,	0x8
	.byte				 0,	 0,  0x7,	0,	7,	0x7,	0,	14,	0x2
	.byte				 1,	 0,	 0x9,	1,	9,  0x5,	0,	0,	0x4
	.byte				 0,	 4,  0x7
EndWStringAddressingTable:

	.align 1
SentenceStringTable:
	.byte		'W', 'E', 'L', 'C', 'O', 'M', 'E', ' ', 'T', 'O', STRING_END, 'G', 'O'
	.byte		'R', 'E', '_', 'O', 'S', STRING_END, 'P', 'L', 'E', 'A', 'S', 'E', ' '
	.byte		'S', 'E', 'L', 'E', 'C', 'T', ' ', 'A', STRING_END, 'F', 'U', 'N', 'C'
	.byte		'T', 'I', 'O', 'N', ' ', 'W', 'I', 'T', 'H', STRING_END, 'T', 'H', 'E'
	.byte		' ', 'K', 'E', 'Y', 'P', 'A', 'D', STRING_END
EndSentenceStringTable:

	.align 1
SStringAddressingTable:	;Row Col Offset	Row Col	Offset	Row Col	Offset
	.byte				 0,	 0,	 0xB,	1,	0,	0x8,	0,	0,	0x10
	.byte				 1,	 0,	 0xE,	0,	0,	0xB
EndSStringAddressingTable:

	.align 1
MenuDisplayDataTable:
	.byte		'S', 'N', 'A', 'K', 'E', STRING_END, 'M', 'U', 'S', 'I', 'C', 'A', 'L'
	.byte		'S', 'N', 'A', 'K', 'E', STRING_END, 'S', 'N', 'A', 'K', 'E', '2', STRING_END
EndMenuDisplayDataTable:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																			   ;
; 							Data Section									   ;
;																			   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.data

;;;;;;Variable Declaration;;;;;;
	.align 4
cRow:	.space 1	;cRow holds the index of the cursor

	.align 4
cCol:	.space 1	;cCol holds the index of the column

;;;;;;Stack Declaration;;;;;;
	.align  8			;the stack (must be double-word aligned)
TopOfStack:     .bes    TOTAL_STACK_SIZE

;;;;;;Vector Table Declaration;;;;;;
        .align  512		;the interrupt vector table in SRAM
VecTable:       .space  VEC_TABLE_SIZE * BYTES_PER_WORD

.end
