;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           GPT Control Constants                              ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description:       This file holds constants to be used in the main file
;
; Revision History:   11/08/23  George Ore      initial revision
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;   Interval Load Register TAILR/TBILR
;       Bits    Name                Code    Description
;       0-31    Interval Load   0xXXXXXXXX  Counter Value
;   Match Register TAMATCHR/TBMATCHR
;       Bits    Name                Code    Description
;       0-31    Interval Load   0xXXXXXXXX  Match Value

;   ASSUME 48MHz system clock
TIMER16_1us     .EQU    0x30
TIMER16_2us     .EQU    0x60
TIMER16_3us     .EQU    0x90
TIMER16_4us     .EQU    0xc0
TIMER16_5us     .EQU    0xf0
TIMER16_6us     .EQU    0x120
TIMER16_7us     .EQU    0x150
TIMER16_8us     .EQU    0x180
TIMER16_9us     .EQU    0x1b0
TIMER16_10us    .EQU    0x1e0
TIMER16_11us    .EQU    0x210
TIMER16_12us    .EQU    0x240
TIMER16_13us    .EQU    0x270
TIMER16_14us    .EQU    0x2a0
TIMER16_15us    .EQU    0x2d0
TIMER16_16us    .EQU    0x300
TIMER16_17us    .EQU    0x330
TIMER16_18us    .EQU    0x360
TIMER16_19us    .EQU    0x390
TIMER16_20us    .EQU    0x3c0
TIMER16_21us    .EQU    0x3f0
TIMER16_22us    .EQU    0x420
TIMER16_23us    .EQU    0x450
TIMER16_24us    .EQU    0x480
TIMER16_25us    .EQU    0x4b0
TIMER16_26us    .EQU    0x4e0
TIMER16_27us    .EQU    0x510
TIMER16_28us    .EQU    0x540
TIMER16_29us    .EQU    0x570
TIMER16_30us    .EQU    0x5a0
TIMER16_31us    .EQU    0x5d0
TIMER16_32us    .EQU    0x600
TIMER16_33us    .EQU    0x630
TIMER16_34us    .EQU    0x660
TIMER16_35us    .EQU    0x690
TIMER16_36us    .EQU    0x6c0
TIMER16_37us    .EQU    0x6f0
TIMER16_38us    .EQU    0x720
TIMER16_39us    .EQU    0x750
TIMER16_40us    .EQU    0x780
TIMER16_41us    .EQU    0x7b0
TIMER16_42us    .EQU    0x7e0
TIMER16_43us    .EQU    0x810
TIMER16_44us    .EQU    0x840
TIMER16_45us    .EQU    0x870
TIMER16_46us    .EQU    0x8a0
TIMER16_47us    .EQU    0x8d0
TIMER16_48us    .EQU    0x900
TIMER16_49us    .EQU    0x930
TIMER16_50us    .EQU    0x960
TIMER16_51us    .EQU    0x990
TIMER16_52us    .EQU    0x9c0
TIMER16_53us    .EQU    0x9f0
TIMER16_54us    .EQU    0xa20
TIMER16_55us    .EQU    0xa50
TIMER16_56us    .EQU    0xa80
TIMER16_57us    .EQU    0xab0
TIMER16_58us    .EQU    0xae0
TIMER16_59us    .EQU    0xb10
TIMER16_60us    .EQU    0xb40
TIMER16_61us    .EQU    0xb70
TIMER16_62us    .EQU    0xba0
TIMER16_63us    .EQU    0xbd0
TIMER16_64us    .EQU    0xc00
TIMER16_65us    .EQU    0xc30
TIMER16_66us    .EQU    0xc60
TIMER16_67us    .EQU    0xc90
TIMER16_68us    .EQU    0xcc0
TIMER16_69us    .EQU    0xcf0
TIMER16_70us    .EQU    0xd20
TIMER16_71us    .EQU    0xd50
TIMER16_72us    .EQU    0xd80
TIMER16_73us    .EQU    0xdb0
TIMER16_74us    .EQU    0xde0
TIMER16_75us    .EQU    0xe10
TIMER16_76us    .EQU    0xe40
TIMER16_77us    .EQU    0xe70
TIMER16_78us    .EQU    0xea0
TIMER16_79us    .EQU    0xed0
TIMER16_80us    .EQU    0xf00
TIMER16_81us    .EQU    0xf30
TIMER16_82us    .EQU    0xf60
TIMER16_83us    .EQU    0xf90
TIMER16_84us    .EQU    0xfc0
TIMER16_85us    .EQU    0xff0
;Need to fix here

TIMER16_86us    .EQU    0x1020
TIMER16_87us    .EQU    0x1050
TIMER16_88us    .EQU    0x1080
TIMER16_89us    .EQU    0x10b0
TIMER16_90us    .EQU    0x10e0
TIMER16_91us    .EQU    0x1110
TIMER16_92us    .EQU    0x1140
TIMER16_93us    .EQU    0x1170
TIMER16_94us    .EQU    0x11a0
TIMER16_95us    .EQU    0x11d0
TIMER16_96us    .EQU    0x1200
TIMER16_97us    .EQU    0x1230
TIMER16_98us    .EQU    0x1260
TIMER16_99us    .EQU    0x1290
TIMER16_100us   .EQU    0x12c0

;   Prescale Register TAPR/TBPR
;       Bits    Name        Code    Description
;       0-7     Prescale    0xXX    Number that must be counted before updating
;                                   the TAR & TAV registers
;       8-31    Reserved    0

