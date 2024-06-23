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
BYTEMASK        .EQU    0x000000FF  ;Used to filter for first byte
INVALIDINPUT    .EQU    0xFFFFFFFF  ;Indicates an invalid input

;;;;;;Waiting Constants;;;;;;
WAIT1           .EQU    1   ;Constant for waiting 1 units of time
WAIT8           .EQU    8   ;Constant for waiting 8 units of time
WAIT30          .EQU    30  ;Constant for waiting 30 units of time
WAIT1000        .EQU    1000  ;Constant for waiting 1000 units of time

;;;;;;Stepper Constants;;;;;;
;Stepping constants
CW      .EQU    0   ;Represents clockwise stepping mode
CCW     .EQU    1   ;Represents counterclockwise stepping mode
STEPCW  .EQU    4   ;Value that offsets towards a CW step
STEPCCW .EQU    -4  ;Value that offsets towards a CCW step
DPOS    .EQU    6   ;The motor will increment 6 degrees at a time
MAXSTEP .EQU    20  ;Maximum amount of steps in a motor cycle
MINSTEP .EQU    0   ;Minimum amount of steps in a motor cycle
HROT_STEPS .EQU 30  ;Represents how many steps are in half a rotation
FROT_STEPS .EQU 60  ;Represents how many steps in a full rotation
POS_OVERFLOW    .EQU    360 ;Represents a pos overflow
POS_UNDERFLOW   .EQU    -1  ;Represents a pos underflow
POS_WRAP    .EQU    359 ;Value to wrap to in case of a pos step underflow

STEP_OVERFLOW .EQU    60 ;Upper limit of a step overflow
STEP_WRAP    .EQU    59 ;Value to wrap to in case of a pos step underflow

;Full step
FULLSTEP1    .EQU   0x14000000 ;Pins to toggle for 1st step
FULLSTEP2    .EQU   0x09000000 ;Pins to toggle for 2nd step
FULLSTEP3    .EQU   0x14000000 ;Pins to toggle for 3rd step
FULLSTEP4    .EQU   0x09000000 ;Pins to toggle for 4th step

;PWM output constants
PWM_PIN1        .EQU    0x01000000  ;Used to toggle pin 24 with PWM
PWM_NPIN1       .EQU    0x08000000  ;Used to toggle pin 27 with PWM
PWM_PIN2        .EQU    0x04000000  ;Used to toggle pin 26 with PWM
PWM_NPIN2       .EQU    0x10000000  ;Used to toggle pin 28 with PWM
NOT_PINS        .EQU    0x18000000  ;Maps to the two inverted PWM pins
READY           .EQU    0   ;Status of PWM is ready
SET             .EQU    1   ;Status of PWM is set

;Angle Input Testing Values
MAXPOS      .EQU    354     ;Maximum angle value allowed in program with 6 angle increment
MINPOS      .EQU    0       ;Minimum angle value allowed in program with 6 angle increment
MAXANGIN    .EQU    359     ;Maximum value allowed in SetAngle function
MINANGIN    .EQU    0       ;Minimum value allowed in SetAngle function
MAXRELANGIN .EQU    180     ;Maximum value allowed in SetRelAngle function UPDATE LATER WITH ACTUAL REASONING
MINRELANGIN .EQU    -180    ;Minimum value allowed in SetRelAngle function

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
