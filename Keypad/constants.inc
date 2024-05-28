;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           Other Constants                                    ;
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
;                     12/04/23  George Ore      added constants
;                     12/05/23  George Ore      added constants for first
;                                               working version
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;General Constants;;;;;;

;Ubiquitous Values
ZERO_START      .EQU    0           ;Zero used for starting counts
COUNT_DONE      .EQU    0           ;Zero used for ending decrementing counts
FALSE           .EQU    0           ;False
TRUE            .EQU    1           ;True aka non-zero
BYTES_PER_WORD  .EQU    4           ;4 bytes in each word
ONE             .EQU    1           ;The number one

;;;;;;Variable Constants;;;;;;
;Variable Initial Values
;DBNCE_CNTR_RESET   .EQU    0x0000BB80  ;dbnceCntr initial value maxed at 65535
;DBNCE_FLAG_RESET   .EQU    0           ;dbnceFlag initial value is reset
;NOT_PRESSED        .EQU    0x000000F0  ;prev initial value is not pressed

;Debounce Flag Values
DBNCE_FLAG_SET      .EQU    1       ;dbnceFlag value set
DBNCE_FLAG_RESET    .EQU    0       ;dbnceFlag value reset

;Debounce Counter Values
DBNCE_CNTR_RESET   .EQU    20  ;Debounce counter lasts 20ms

;;;;;;Interrupt Setup Constants;;;;;;

HANDLER_STACK_SIZE  .EQU    128     ;interrupt handler stack size

VEC_TABLE_SIZE      .EQU    54      ;number of interrupts in table

GPT0A_EX_NUM        .EQU    31      ;exception number for GPT0 Timer A
GPT0A_IRQ_NUM       .EQU    GPT0A_EX_NUM - 16 ;interrupt # for GPT0 Timer A

;;;;;;Buffer Constants;;;;;;

BOFFSET             .EQU    8     ;offset between every buffer address value

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
