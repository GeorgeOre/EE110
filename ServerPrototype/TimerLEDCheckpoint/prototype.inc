;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                 prototype.inc                              ;
;                          Server Functionality Demo                         ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the constants constants for the RTOS demonstration
; program for the EE110b HW6 assignment.
;
; Revision History:
;    02/17/22  Glen George  initial revision
;    02/18/22  Glen George  detabbed file
;    07/02/22  George Ore   Stole from Glen and repurposed for EE110b HW5


; system constants

HANDLER_STACK_SIZE .EQU    128          ;interrupt handler stack size
PROCESS_STACK_SIZE .EQU    256          ;main loop stack size
TOTAL_STACK_SIZE   .EQU    PROCESS_STACK_SIZE + HANDLER_STACK_SIZE

VEC_TABLE_SIZE     .EQU    54           ;number of interrupts in table

GPT0A_EX_NUM       .EQU    31           ;exception number for GPT0 Timer A
GPT0A_IRQ_NUM      .EQU    GPT0A_EX_NUM - 16    ;GPT0 Timer A interrupt number


; I/O constants

REDLED_IO_BIT      .EQU    6            ;red LED on bit 6
GREENLED_IO_BIT    .EQU    7            ;green LED on bit 7


; events

TIMEOUT_EVENT      .EQU    1            ;timeout event


; timing constants

MS_PER_BLINK       .EQU    1000         ;milliseconds for each blink
LOOPS_PER_BLINK    .EQU    100000       ;number of loops for blinking LED
GPT0A_MODE         .EQU    0x00000002   ;set timer A mode
CLK_PER_MS         .EQU    48000        ;timer clocks per millisecond
