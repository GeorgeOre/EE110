;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           General Constants                                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description:       This file holds constants to be used in the main file
;
; Revision History:   10/27/23  George Ore      initial revision
;                     10/31/23  George Ore      fixed constant value bugs
;                     11/01/23  George Ore      made control registers more
;                                               general, modded to fit HW2
;                     11/08/23  George Ore      repurposed file, removed all
;                                               configuration contants to other
;                                               files, added system control
;                                               space registers.
;                     06/29/24  George Ore      generalized to all projects
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;General Constants;;;;;;

;Ubiquitous values
EMPTY           .EQU    0           ;Empty
ONE             .EQU    1           ;The number one

;Testing constants
INVALIDINPUT    .EQU    0xFFFFFFFF  ;Indicates an invalid input in GORE tests
FALSE           .EQU    0           ;False
TRUE            .EQU    1           ;True aka non-zero

;Counter values
ZERO_START      .EQU    0           ;Zero used for starting counts
COUNT_DONE      .EQU    0           ;Zero used for ending decrementing counts

;Indexing/Offset
SHIFT_BIT       .EQU    1           ;Used for shifting bits a single bit
SHIFT_NIBBLE    .EQU    2           ;Used for shifting bits a nibble
NEXT_BYTE       .EQU    1           ;Used for addressing to the next byte
NEXT_HALF       .EQU    2           ;Used for addressing to the next halfword
NEXT_WORD       .EQU    4           ;Used for addressing to the next word
BYTES_PER_WORD  .EQU    4           ;4 bytes in each word

;Data masks
BYTEMASK        .EQU    0x000000FF  ;Used to filter for first byte
LNIBBLE         .EQU    0x0000000F  ;Used to filter for lower nibble
HNIBBLE         .EQU    0x000000FF  ;Used to filter for higher nibble

;Ascii constants
ASCII_ZERO      .EQU    48          ;Represents a zero in ascii
ASCII_NEGATIVE  .EQU    45          ;Represents a '-' in ascii
STRING_END      .EQU    0xA0    ;Represents end of string condition

;Math constants
BASE10          .EQU    10          ;Contains base 10

;;;;;;Waiting Constants;;;;;;
WAIT1           .EQU    1   ;Constant for waiting 1 units of time
WAIT8           .EQU    8   ;Constant for waiting 8 units of time
WAIT30          .EQU    30  ;Constant for waiting 30 units of time
WAIT1000        .EQU    1000  ;Constant for waiting 1000 units of time
WAIT5000        .EQU    5000  ;Constant for waiting 5000 units of time
WAIT10000       .EQU   10000  ;Constant for waiting 10000 units of time
WAIT30000       .EQU   30000  ;Constant for waiting 30000 units of time

;;;;;;Interrupt Setup Constants;;;;;;

HANDLER_STACK_SIZE  .EQU    128     ;interrupt handler stack size

VEC_TABLE_SIZE      .EQU    54      ;number of interrupts in table

GPT0A_EX_NUM        .EQU    31      ;exception number for GPT0 Timer A
GPT0A_IRQ_NUM       .EQU    GPT0A_EX_NUM - 16 ;interrupt # for GPT0 Timer A
GPT1A_EX_NUM        .EQU    33      ;exception number for GPT1 Timer A
GPT1A_IRQ_NUM       .EQU    GPT1A_EX_NUM - 16 ;interrupt # for GPT1 Timer A
GPT2A_EX_NUM        .EQU    35      ;exception number for GPT2 Timer A
GPT2A_IRQ_NUM       .EQU    GPT2A_EX_NUM - 16 ;interrupt # for GPT2 Timer A
GPT3A_EX_NUM        .EQU    37      ;exception number for GPT3 Timer A
GPT3A_IRQ_NUM       .EQU    GPT3A_EX_NUM - 16 ;interrupt # for GPT3 Timer A

;;;;;;Stack Definition Constants;;;;;;
;PROCESS_STACK_SIZE .equ    256          ;main loop stack size
;TOTAL_STACK_SIZE   .equ    PROCESS_STACK_SIZE + HANDLER_STACK_SIZE

;;;;;;System Control Space;;;;;;

; CCR - configuration control register

STACK_ALIGN_4      .equ    0x00000000   ;keep stack on 4 byte alignment
STACK_ALIGN_8      .equ    0x00000100   ;keep stack on 8 byte alignment

;;;;;;System Control Space Register Addresses;;;;;;

; Base addresses
SCS         .EQU    0xE000E000   ;core system control space registers

; Register offsets

NVIC_ISER0  .EQU    0x0100       ;interrupt set enable (irq 0-31)
NVIC_ISER1  .EQU    0x0104       ;interrupt set enable (irq 32-63)
VTOR        .EQU    0x0D08       ;vector table offset register
CCR         .EQU    0x0D14       ;configuration control register
