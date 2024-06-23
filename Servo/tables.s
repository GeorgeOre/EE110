;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                              ;
;                              EE110a HW5 Tables                               ;
;                                 George Ore                                   ;
;                                                                              ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description: This file contains all tables needed to run the servo motor.
; Goal: The goal of these functions is to facilitate calculations.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           Required Constant Files
    .include "configPWR&CLK.inc"  ; contains power config constants
    .include "configGPIO.inc"     ; contains GPIO config constants
    .include "GPIO.inc"           ; contains GPIO control constants
    .include "GPT.inc"            ; contains GPT control constants
    .include "constants.inc"      ; contains misc. constants
    .include "macros.inc"         ; contains all macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           Required Functions
;   None
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                               Table of Contents
;       Function Name   |   Purpose
    .def	PWMTable
    .def	EndPWMTable

    .def	SampleTable
    .def	EndSampleTable

    .def	ErrorCorrectionTable
    .def	EndErrorCorrectionTable
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Revision History:   02/04/24 George Ore   Created format
;                     05/30/24 George Ore   Ported to EE110a HW3
;					  06/23/24 George Ore	Refactored and turned in
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;*******************************************************************************
;*                              FUNCTIONS                                      *
;*******************************************************************************
.text                           ; program memory space start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;Calculation Tables;;;;;;
	.align 4
PWMTable:
	.word		0x000CC7E0, 0x000CC9E8, 0x000CCBF0, 0x000CCDF8, 0x000CD000
	.word		0x000CD208, 0x000CD410, 0x000CD618, 0x000CD820, 0x000CDA28
	.word		0x000CDC30, 0x000CDE38, 0x000CE040, 0x000CE248, 0x000CE450
	.word		0x000CE658, 0x000CE860, 0x000CEA68, 0x000CEC70, 0x000CEE78
	.word		0x000CF080, 0x000CF288, 0x000CF490, 0x000CF698, 0x000CF8A0
	.word		0x000CFAA8, 0x000CFCB0, 0x000CFEB8, 0x000D00C0, 0x000D02C8
	.word		0x000D04D0, 0x000D06D8, 0x000D08E0, 0x000D0AE8, 0x000D0CF0
	.word		0x000D0EF8, 0x000D1100, 0x000D1308, 0x000D1510, 0x000D1718
	.word		0x000D1920, 0x000D1B28, 0x000D1D30, 0x000D1F38, 0x000D2140
	.word		0x000D2348, 0x000D2550, 0x000D2758, 0x000D2960, 0x000D2B68
	.word		0x000D2D70, 0x000D2F78, 0x000D3180, 0x000D3388, 0x000D3590
	.word		0x000D3798, 0x000D39A0, 0x000D3BA8, 0x000D3DB0, 0x000D3FB8
	.word		0x000D41C0, 0x000D43C8, 0x000D45D0, 0x000D47D8, 0x000D49E0
	.word		0x000D4BE8, 0x000D4DF0, 0x000D4FF8, 0x000D5200, 0x000D5408
	.word		0x000D5610, 0x000D5818, 0x000D5A20, 0x000D5C28, 0x000D5E30
	.word		0x000D6038, 0x000D6240, 0x000D6448, 0x000D6650, 0x000D6858
	.word		0x000D6A60, 0x000D6C68, 0x000D6E70, 0x000D7078, 0x000D7280
	.word		0x000D7488, 0x000D7690, 0x000D7898, 0x000D7AA0, 0x000D7CA8
	.word		0x000D7EB0, 0x000D80B8, 0x000D82C0, 0x000D84C8, 0x000D86D0
	.word		0x000D88D8, 0x000D8AE0, 0x000D8CE8, 0x000D8EF0, 0x000D90F8
	.word		0x000D9300, 0x000D9508, 0x000D9710, 0x000D9918, 0x000D9B20
	.word		0x000D9D28, 0x000D9F30, 0x000DA138, 0x000DA340, 0x000DA548
	.word		0x000DA750, 0x000DA958, 0x000DAB60, 0x000DAD68, 0x000DAF70
	.word		0x000DB178, 0x000DB380, 0x000DB588, 0x000DB790, 0x000DB998
	.word		0x000DBBA0, 0x000DBDA8, 0x000DBFB0, 0x000DC1B8, 0x000DC3C0
	.word		0x000DC5C8, 0x000DC7D0, 0x000DC9D8, 0x000DCBE0, 0x000DCDE8
	.word		0x000DCFF0, 0x000DD1F8, 0x000DD400, 0x000DD608, 0x000DD810
	.word		0x000DDA18, 0x000DDC20, 0x000DDE28, 0x000DE030, 0x000DE238
	.word		0x000DE440, 0x000DE648, 0x000DE850, 0x000DEA58, 0x000DEC60
	.word		0x000DEE68, 0x000DF070, 0x000DF278, 0x000DF480, 0x000DF688
	.word		0x000DF890, 0x000DFA98, 0x000DFCA0, 0x000DFEA8, 0x000E00B0
	.word		0x000E02B8, 0x000E04C0, 0x000E06C8, 0x000E08D0, 0x000E0AD8
	.word		0x000E0CE0, 0x000E0EE8, 0x000E10F0, 0x000E12F8, 0x000E1500
	.word		0x000E1708, 0x000E1910, 0x000E1B18, 0x000E1D20, 0x000E1F28
	.word		0x000E2130, 0x000E2338, 0x000E2540, 0x000E2748, 0x000E2950
	.word		0x000E2B58, 0x000E2D60, 0x000E2F68, 0x000E3170, 0x000E3378
	.word		0x000E3580
EndPWMTable:

	.align 4
SampleTable:
	.word		0x000000FC, 0x00000105, 0x0000010F, 0x00000119, 0x00000122
	.word		0x0000012C, 0x00000136, 0x0000013F, 0x00000149, 0x00000153
	.word		0x0000015C, 0x00000166, 0x00000170, 0x0000017A, 0x00000183
	.word		0x0000018D, 0x00000197, 0x000001A0, 0x000001AA, 0x000001B4
	.word		0x000001BD, 0x000001C7, 0x000001D1, 0x000001DA, 0x000001E4
	.word		0x000001EE, 0x000001F8, 0x00000201, 0x0000020B, 0x00000215
	.word		0x0000021E, 0x00000228, 0x00000232, 0x0000023B, 0x00000245
	.word		0x0000024F, 0x00000259, 0x00000262, 0x0000026C, 0x00000276
	.word		0x0000027F, 0x00000289, 0x00000293, 0x0000029C, 0x000002A6
	.word		0x000002B0, 0x000002B9, 0x000002C3, 0x000002CD, 0x000002D7
	.word		0x000002E0, 0x000002EA, 0x000002F4, 0x000002FD, 0x00000307
	.word		0x00000311, 0x0000031A, 0x00000324, 0x0000032E, 0x00000337
	.word		0x00000341, 0x0000034B, 0x00000355, 0x0000035E, 0x00000368
	.word		0x00000372, 0x0000037B, 0x00000385, 0x0000038F, 0x00000398
	.word		0x000003A2, 0x000003AC, 0x000003B6, 0x000003BF, 0x000003C9
	.word		0x000003D3, 0x000003DC, 0x000003E6, 0x000003F0, 0x000003F9
	.word		0x00000403, 0x0000040D, 0x00000416, 0x00000420, 0x0000042A
	.word		0x00000434, 0x0000043D, 0x00000447, 0x00000451, 0x0000045A
	.word		0x00000464, 0x0000046E, 0x00000477, 0x00000481, 0x0000048B
	.word		0x00000494, 0x0000049E, 0x000004A8, 0x000004B2, 0x000004BB
	.word		0x000004C5, 0x000004CF, 0x000004D8, 0x000004E2, 0x000004EC
	.word		0x000004F5, 0x000004FF, 0x00000509, 0x00000513, 0x0000051C
	.word		0x00000526, 0x00000530, 0x00000539, 0x00000543, 0x0000054D
	.word		0x00000556, 0x00000560, 0x0000056A, 0x00000573, 0x0000057D
	.word		0x00000587, 0x00000591, 0x0000059A, 0x000005A4, 0x000005AE
	.word		0x000005B7, 0x000005C1, 0x000005CB, 0x000005D4, 0x000005DE
	.word		0x000005E8, 0x000005F1, 0x000005FB, 0x00000605, 0x0000060F
	.word		0x00000618, 0x00000622, 0x0000062C, 0x00000635, 0x0000063F
	.word		0x00000649, 0x00000652, 0x0000065C, 0x00000666, 0x00000670
	.word		0x00000679, 0x00000683, 0x0000068D, 0x00000696, 0x000006A0
	.word		0x000006AA, 0x000006B3, 0x000006BD, 0x000006C7, 0x000006D0
	.word		0x000006DA, 0x000006E4, 0x000006EE, 0x000006F7, 0x00000701
	.word		0x0000070B, 0x00000714, 0x0000071E, 0x00000728, 0x00000731
	.word		0x0000073B, 0x00000745, 0x0000074E, 0x00000758, 0x00000762
	.word		0x0000076C, 0x00000775, 0x0000077F, 0x00000789, 0x00000792
	.word		0x0000079C, 0x000007A6, 0x000007AF, 0x000007B9, 0x000007C3
	.word		0x000007CD, 0x00000FFF
EndSampleTable:

	.align 4
ErrorCorrectionTable:
	.word		-90, -89, -88, -87, -86
	.word		-85, -84, -83, -82, -81
	.word		-80, -79, -78, -77, -76
	.word		-75, -74, -73, -72, -71
	.word		-70, -69, -68, -67, -66
	.word		-65, -64, -63, -62, -61
	.word		-60, -59, -58, -57, -56
	.word		-55, -54, -53, -52, -51
	.word		-50, -49, -48, -47, -46
	.word		-45, -44, -43, -42, -41
	.word		-40, -39, -38, -37, -36
	.word		-35, -34, -33, -32, -31
	.word		-30, -29, -28, -27, -26
	.word		-25, -24, -23, -22, -21
	.word		-20, -19, -18, -17, -16
	.word		-15, -14, -13, -12, -11
	.word		-10, -9, -8, -7, -6
	.word		-5, -4, -3, -2, -1
	.word		0, 1, 2, 3, 4
	.word		5, 6, 7, 8, 9
	.word		10, 11, 12, 13, 14
	.word		15, 16, 17, 18, 19
	.word		20, 21, 22, 23, 24
	.word		25, 26, 27, 28, 29
	.word		30, 31, 32, 33, 34
	.word		35, 36, 37, 38, 39
	.word		40, 41, 42, 43, 44
	.word		45, 46, 47, 48, 49
	.word		50, 51, 52, 53, 54
	.word		55, 56, 57, 58, 59
	.word		60, 61, 62, 63, 64
	.word		65, 66, 67, 68, 69
	.word		70, 71, 72, 73, 74
	.word		75, 76, 77, 78, 79
	.word		80, 81, 82, 83, 84
	.word		85, 86, 87, 88, 89
	.word		90, 90
EndErrorCorrectionTable:


.end
