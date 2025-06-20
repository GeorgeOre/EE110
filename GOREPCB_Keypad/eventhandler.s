;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                              ;
;             GOREPCB Keypad Demo Event Handler Functions                      ;
;                              George Ore                                      ;
;                                                                              ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description: This file includes functions that handle interrupt driven code.
; Goal: The goal of these functions is to define keypad debouncing driven by
;       interrupts to have precision.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           Required Constant Files
    .include "constants.inc"        ; contains misc. constants
    .include "macros.inc"           ; contains all macros
    .include "configPWR&CLK.inc"    ; contains power config constants
    .include "configGPIO.inc"       ; contains GPIO config constants
    .include "GPIO.inc"             ; contains GPIO control constants
    .include "GPT.inc"              ; contains GPT control constants
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           Required Functions
;   None
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                               Table of Contents
;       Function Name       |   Purpose
    .def    EnqueueEvent    ; Set a flag indicating that an event has occurred
    .def    GPT0EventHandler; Debounce the keypad every interrupt cycle
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Revision History:   02/04/24 George Ore   Created format
;                     05/28/24 George Ore   Ported to EE110a HW2
;                     06/20/25 George Ore   Modified for GOREPCB and github
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;*******************************************************************************
;*                              FUNCTIONS                                       *
;*******************************************************************************
.text                           ; program memory space start
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

    LDR     R0, [R1]    ;Load R0 with the key value
    LDR     R1, [R2]    ;Load R1 with the buffer index value

    ADD     R1, #BYTES_PER_WORD    ;Increment the buffer index value
    STR     R1, [R2]    ;Save the buffer index

    SUB     R1, #BYTES_PER_WORD    ;Restore the buffer index value

    ; Use buffer index value as a counter for calculating the desired buffer
    ; address
    MOV32   R2, COUNT_DONE    ;Load calc-finished condition

BAddressLoop:
    CMP     R1, R2     ;Test index counter
    BEQ     Enqueue    ;Start enqueue if done
    ; If not...
    ADD     R3, #BYTES_PER_WORD     ;Add [] for every value of index
    SUB     R1, #BYTES_PER_WORD   ;Decrement index counter

    B       BAddressLoop   ;Keep looping until done

Enqueue:
    STR     R0, [R3]    ;Put keyValue in the calculated buffer address

    MOVA    R0, dbnceFlag    ;Reset status of dbnceFlag
    MOV32   R1, DBNCE_FLAG_RESET
    STR     R1, [R0]

    CPSIE   I   ;Enable interrupts again

    POP     {R0, R1, R2, R3}    ;Pop registers
    BX      LR  ;Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GPT0EventHandler:
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
GPT0EventHandler:
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
    MOV32   R1, GPT0            ;Load base into R1
    STREG   IRQ_TATO, R1, ICLR  ;clear timer A timeout interrupt
    POP     {R4, R5, R6}        ;restore registers
    BX      LR                  ;return from interrupt

.end
