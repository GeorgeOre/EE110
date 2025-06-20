;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                              ;
;                           GOREPCB Keypad Demo                                ;
;                                                                              ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
; Description:      This demo program tests the 4x4 keypad on the GOREPCB.
;                   When a button is pressed, the program registers the input's
;                   keyID inside a data memory buffer.
;
; Operation:        The program constantly checks a debounce flag for a sign to
;                   store the identifier of the corresponding debounced button
;                   in a data memory buffer. When detected, the button's ID is
;					stored in the memory space and can be viewed/verified.
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
;   11/06/23  George Ore   initial version
;   11/07/23  George Ore   finished initial version
;   12/04/23  George Ore   fixed bugs, start testing
;   12/05/23  George Ore   finished
;   06/20/25  George Ore   Modified for GOREPCB and github
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

; Include constant, and macro files
	.include "configPWR&CLK.inc"    ;contains power config constants
	.include "configGPIO.inc"       ;contains GPIO config constants
	.include "GPIO.inc"             ;contains GPIO control constants
	.include "GPT.inc"              ;contains GPT control constants
	.include "constants.inc"        ;contains misc. constants
	.include "macros.inc"           ;contains all macros

;Reference initialization functions
	.ref	InitPower
	.ref	InitClocks
	.ref	InitGPIO
	.ref	InitGPT0

;Reference event handler functions
	.ref	EnqueueEvent	;	Set a flag indicating that an event has occurred
	.ref	GPT0EventHandler;	Debounce the keypad every interrupt cycle

;Reference utility functions
	.ref	MoveVecTable		;	Replaces the default v-table with the custom
	.ref	InstallGPT0Handler	;	Installs the GPT handler in custom v-table

	.text                           ;program memory space start
	.global ResetISR                ;required global var

ResetISR:                       ;System required label

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                              ;
;                         Actual Program Code                                  ;
;                                                                              ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Initialize Stack
InitStack:
    MOVA    R0, TopOfStack
    MSR     MSP, R0
    SUB     R0, R0, #HANDLER_STACK_SIZE
    MSR     PSP, R0

; Initialize Power
    BL      InitPower

; Initialize Clocks
    BL      InitClocks

; Initialize Vector Table
    BL      MoveVecTable

; Install GPT0 Handler
    BL      InstallGPT0Handler

; Initialize GPIO
    BL      InitGPIO

; Init Variable Values
InitVariables:
    MOV32   R0, NOT_PRESSED ;load the not-pressed value

    ; set previous values of all rows to start with the not-pressed value
    MOVA    R1, prev0
    STR     R0, [R1]
    MOVA    R1, prev1
    STR     R0, [R1]
    MOVA    R1, prev2
    STR     R0, [R1]
    MOVA    R1, prev3
    STR     R0, [R1]

    MOV32   R0, DBNCE_CNTR_RESET    ;load the counter reset value

    ; reset values of all row debounce counters
    MOVA    R1, dbnceCntr0  ;reset row0 debounce counter
    STR     R0, [R1]
    MOVA    R1, dbnceCntr1  ;reset row0 debounce counter
    STR     R0, [R1]
    MOVA    R1, dbnceCntr2  ;reset row0 debounce counter
    STR     R0, [R1]
    MOVA    R1, dbnceCntr3  ;reset row0 debounce counter
    STR     R0, [R1]

    MOV32   R0, NOT_PRESSED ;load the not-pressed value
    MOVA    R1, keyValue    ;set the initial key value to not-pressed
    STR     R0, [R1]

    MOVA    R1, dbnceFlag   ;set debounce flag to start in the reset state
    MOV32   R0, DBNCE_FLAG_RESET
    STR     R0, [R1]

    MOVA    R1, bIndex  ;set starting buffer index to 0
    MOV32   R0, ZERO_START
    STR     R0, [R1]

; Init Register Values
InitRegisters:
    MOV32   R1, GPIO                ;Load base address

    STREG   R0_TEST, R1, DOUT31_0   ;Start testing row 0

; Initialize GPT0 to activate its associated timeout interrupt
    BL      InitGPT0


; Main Program
MainLoop:   ;Loop goes on forever
    MOVA    R1, dbnceFlag   ;Load dbnceFlag address into R1

    CPSID   I   ;Disable interrupts to avoid critical code
    LDR     R0, [R1]    ;Load dbnceFlag data onto R0

    MOV32   R1, DBNCE_FLAG_SET  ;Load R1 with the event pressed condition
    CMP     R0, R1
    BNE     SkipEvent       ;If dbnceFlag != SET, skip EnqueueEvent
    BL      EnqueueEvent    ;If debounce flag == set, enqueue event

SkipEvent: ;This label is only used in the != case
    CPSIE   I   ;Enable interrupts again

    B       MainLoop        ;Repeat forever

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                              ;
;                            Data Section                                      ;
;                                                                              ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

    .global TopOfStack
    .global VecTable


; Variable Declaration
; prev0-3 will store previous states of the IO inputs for each row
	.align 4
prev0:      .space 4    ;will store previous value of row 0
    .align 4
prev1:      .space 4    ;will store previous value of row 1
     .align 4
prev2:      .space 4    ;will store previous value of row 2
	.align 4
prev3:      .space 4    ;will store previous value of row 3

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
keyValue:   .space 4    ;keyValue will have codes unique to each button. The
                        ;high nibble represents the rows and the low nibble
                        ;represents the columns

	.align 4
dbnceFlag:  .space 4    ;flag indicates if a button is successfully debounced

	.align 4
bIndex:     .space 4    ;stores index of the next empty buffer address

; Buffer Declaration
	.align 4            ;buffer will store the word size key identification numbers
buffer:     .space 160  ;has enough space to store 160 key presses (16keys*10times)

; Stack Declaration
	.align  8               ;the stack (must be double-word aligned)
TopOfStack: .bes    TOTAL_STACK_SIZE

; Vector Table Declaration
	.align  512             ;the interrupt vector table in SRAM
VecTable:   .space  VEC_TABLE_SIZE * BYTES_PER_WORD

.end
