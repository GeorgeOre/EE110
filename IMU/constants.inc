;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           Other Constants                                    ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description:       This file holds constants to be used in the main file
;
; Revision History: 10/27/23    George Ore  Initial revision
;                   10/31/23    George Ore  Fixed constant value bugs
;                   11/01/23    George Ore  Made control registers more
;                                           general, modded to fit 110a HW2
;                   11/08/23    George Ore  Repurposed file, removed all
;                                           configuration contants to other
;                                           files, added system control
;                                           space registers.
;                   02/04/24    George Ore  Revised
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;General Constants;;;;;;

;Ubiquitous Values
ZERO_START      .EQU    0           ;Zero used for starting counts
COUNT_DONE      .EQU    0           ;Zero used for ending decrementing counts
FALSE           .EQU    0           ;False
EMPTY           .EQU    0           ;Empty
TRUE            .EQU    1           ;True aka non-zero
BYTES_PER_WORD  .EQU    4           ;4 bytes in each word
ONE             .EQU    1           ;The number one
NEXT_BYTE       .EQU    1           ;Used for addressing to the next byte
NEXT_HWORD      .EQU    2           ;Used for addressing to the next half word
NEXT_WORD       .EQU    4           ;Used for addressing to the next word
BYTE_SHIFT      .EQU    8           ;Used for LSLing to the next byte
HWORD_SHIFT     .EQU    16          ;Used for LSLing to the next half word
WORD_SHIFT      .EQU    32          ;Used for LSLing to the next word
BYTEMASK        .EQU    0x000000FF  ;Used to filter for first byte

;;;;;;Waiting Constants;;;;;;
WAIT1           .EQU    1   ;Constant for waiting 1 units of time
WAIT8           .EQU    8   ;Constant for waiting 8 units of time
WAIT30          .EQU    30  ;Constant for waiting 30 units of time
WAIT1000        .EQU  1000  ;Constant for waiting 1000 units of time
WAIT3000        .EQU  3000  ;Constant for waiting 3000 units of time
WAIT5000        .EQU  5000  ;Constant for waiting 5000 units of time
WAIT10000       .EQU 10000  ;Constant for waiting 10000 units of time

;;;;;;Interrupt Setup Constants;;;;;;

HANDLER_STACK_SIZE  .EQU    128     ;interrupt handler stack size

VEC_TABLE_SIZE      .EQU    54      ;number of interrupts in table

GPT0A_EX_NUM        .EQU    31      ;exception number for GPT0 Timer A
GPT0A_IRQ_NUM       .EQU    GPT0A_EX_NUM - 16 ;interrupt # for GPT0 Timer A
GPT1A_EX_NUM        .EQU    33      ;exception number for GPT1 Timer A
GPT1A_IRQ_NUM       .EQU    GPT1A_EX_NUM - 16 ;interrupt # for GPT1 Timer A

;;;;;;Buffer Constants;;;;;;
NEXTBINDEX  .EQU    12   ;Indicates the distance to the next empty buffer index

;;;;;;Stack Definition Constants;;;;;;

PROCESS_STACK_SIZE .equ    256          ;main loop stack size
TOTAL_STACK_SIZE   .equ    PROCESS_STACK_SIZE + HANDLER_STACK_SIZE

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
