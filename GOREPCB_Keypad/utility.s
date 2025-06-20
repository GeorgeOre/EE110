;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                              ;
;                 GOREPCB Keypad Demo Utility Functions                        ;
;                             George Ore                                       ;
;                                                                              ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description: This file contains utility functions for general use.
; Goal: The goal of these functions is to reduce the codebase and provide more
;       modularization.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           Required Constant Files
    .include "constants.inc"        ; contains misc. constants
    .include "macros.inc"           ; contains all macros
    .include "configPWR&CLK.inc"    ; contains power config constants
    .include "configGPIO.inc"       ; contains GPIO config constants
    .include "GPIO.inc"             ; contains GPIO control constants
    .include "GPT.inc"              ; contains GPT control constants
    .global VecTable
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           Required Functions
    .ref    GPT0EventHandler        ; Function to install
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                               Table of Contents
;       Function Name           |   Purpose
    .def    MoveVecTable        ; Replaces the default v-table with the custom
    .def    InstallGPT0Handler  ; Installs the GPT handler in custom v-table
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
; MoveVecTable:
; Description: This function moves the interrupt vector table from its current
;              location to SRAM at the location VecTable.
; Operation: The function reads the current location of the vector table from
;            the Vector Table Offset Register and copies the words from that
;            location to VecTable. It then updates the Vector Table Offset
;            Register with the new address of the vector table (VecTable).
; Arguments: None
; Return Values: None
; Local Variables: None
; Shared Variables: None
; Global Variables: None
; Input: VTOR.
; Output: VTOR.
; Error Handling: None.
; Registers Changed: flags, R0, R1, R2, R3
; Stack Depth: 0 word
; Algorithms: None.
; Data Structures: None.
; Revision History: 11/03/21 Glen George initial revision
;                   12/4/23  George Ore added to project
; Pseudo Code:
;   store necessary changed registers
;   start doing the copy
;   setup to move the vector table
;       get base for CPU SCS registers
;       get current vector table address
;       load address of new location
;       get the number of words to copy
;       now loop copying the table
;   loop copying the vector table
;       get value from original table
;       copy it to new table
;       update copy count
;       if not done, keep copying
;       otherwise done copying
;   done copying data, change VTOR
;       load address of new vector table
;       and store it in VTOR
;       and all done
;   done moving the vector table
;       restore registers and return
;       BX LR  ;return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MoveVecTable:
    PUSH    {R4}                    ;store necessary changed registers

MoveVecTableInit:                   ;setup to move the vector table
    MOV32   R1, SCS                 ;get base for CPU SCS registers
    LDR     R0, [R1, #VTOR]         ;get current vector table address

    MOVA    R2, VecTable            ;load address of new location
    MOV     R3, #VEC_TABLE_SIZE     ;get the number of words to copy

MoveVecCopyLoop:                    ;loop copying the vector table
    LDR     R4, [R0], #BYTES_PER_WORD   ;get value from original table
    STR     R4, [R2], #BYTES_PER_WORD   ;copy it to new table

    SUBS    R3, #1                  ;update copy count

    BNE     MoveVecCopyLoop         ;if not done, keep copying

MoveVecCopyDone:                    ;done copying data, change VTOR
    MOVA    R2, VecTable            ;load address of new vector table
    STR     R2, [R1, #VTOR]         ;and store it in VTOR

MoveVecTableDone:                   ;done moving the vector table
    POP     {R4}                    ;restore registers and return
    BX      LR                      ;return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; InstallGPT0Handler:
; Description: Install the event handler for the GPT0 timer interrupt.
; Operation: Writes the address of the timer event handler to the appropriate
;            interrupt vector.
; Arguments: None
; Return Value: None
; Local Variables: None
; Shared Variables: None
; Global Variables: None
; Input: None
; Output: None
; Error Handling: None
; Algorithms: None
; Data Structures: None
; Registers Changed: R0, R1
; Stack Depth: 0 words
; Revision History: 02/16/21 Glen George initial revision
;                   12/04/23 George Ore added to project
; Pseudo Code:
;   get handler address
;   get address of SCS registers
;   get table relocation address
;   store vector address
;   BX LR  ;all done, return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
InstallGPT0Handler:
    MOVA    R0, GPT0EventHandler        ;get handler address
    MOV32   R1, SCS                     ;get address of SCS registers
    LDR     R1, [R1, #VTOR]             ;get table relocation address
    STR     R0, [R1, #(4 * GPT0A_EX_NUM)]   ;store vector address
    BX      LR                          ;all done, return

	.data
.end
