;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																			   ;
;							Initalization Functions							   ;
;																			   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
; Description:       This file contains functions that initalize the power, GPT,
;					 GPIO, and clocks
;
;Table of Contents (also defining labels to be used in other files)
;	.def	InitPower
;	.def	InitClocks
;	.def	InitGPIO
;	.def	InitGPT0

;Include constant and macro files
	.include "configPWR&CLK.inc"	;contains power config constants
	.include "configGPIO.inc"	;contains GPIO config constants
	.include "GPIO.inc"			;contains GPIO control constants
	.include "GPT.inc"			;contains GPT control constants
	.include "constants.inc"	;contains misc. constants

	.include "macros.inc"		;contains all macros

