;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																			   ;
;						EE110b HW1 Initialization Functions					   ;
;								George Ore									   ;
;																			   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description:	This file includes all the initalization functions for HW1.
;
; Goal:			The goal of these functions is to facilitate initilization
;				by dedicating specific functions to initialize the power
;				domains, clocks, and modules of the CC2652R microcontroller
;				and also for the MPU-9250 and its internal AK8963.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;							Required Constant Files
	.include "constants.inc"	;contains misc. constants
	.include "macros.inc"		;contains all macros
	.include "configPWR&CLK.inc"	;contains power config constants
	.include "configGPIO.inc"	;contains GPIO config constants
	.include "GPIO.inc"			;contains GPIO control constants
	.include "GPT.inc"			;contains GPT control constants
	.include "SSI.inc"			;contains SSI control constants
	.include "IMU.inc"			;contains IMU control constants
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;							Required Functions
	.ref	SPIReadCycle
	.ref	SPIWriteCycle
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;								Table of Contents
;		Function Name	|	Purpose
	.def	InitPower	;	Initialize power domains
	.def	InitClocks	;	Initialize module clocks
	.def	InitGPIO	;	Initialize GPIO
	.def	InitGPTs	;	Initialize GPTs
	.def	InitSSI		;	Initialize SSI module
	.def	InitMPU9250	;	Initialize IMU
	.def	InitAK8963	;	Initialize magnetometer
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Revision History:	02/04/24	George Ore	Created format
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;*******************************************************************************
;*								FUNCTIONS									   *
;*******************************************************************************

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; InitPower:
;
; Description:	This function initalizes the peripheral and serial power.
;
; Operation:    Writes to the power control registers and waits until
;				the status is on.
;
; Arguments:        None.
; Return Values:    None.
;
; Local Variables:  None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   None.
;
; Registers Changed: Power control registers, R0, R1, R2
; Stack Depth:      2 words (Called in main)
;
; Algorithms:       None.
; Data Structures:  None.
; Known Bugs:       None.
;
; Limitations:      Is a blocking function and if there is an initialization
;					error it will block indefinitely.
;
;
; Revision History:	12/04/23	George Ore	Added documentation
;					01/10/24	George Ore	Added to EE110b HW1 and added serial
;					01/16/24	George Ore	Updated Pseudo code and realized
;											that the current code is good
;					02/02/24	George Ore	Added push and pops and updated
;											comments
;
; Pseudo Code
;	PDCTL0 = peripheral power domain turned on
;
;	while (PDSTAT0 != peripheral and serial power turned on)
;		wait
;
;	return
InitPower:
	PUSH	{R0, R1, R2}

;PDCTL0 is writen to in order to turn power on
	MOV32	R1, PRCM					;Load base address
	STREG   PER_SER_PWR_ON, R1, PDCTL0	;peripheral power turned on

;Wait until power is on
	MOV32 	R2, PER_SER_PWR_ON	;Load test constant

WaitPON:
	LDR		R0, [R1,#PDSTAT0]	;Load PDSTAT0 to check if power is on

	CMP 	R0, R2			;Compare ready condition with PDSTAT0
	BNE		WaitPON			;Keep looping if power is not on
	;BEQ	End_InitPower	;End when status confirms power is on

;End_InitPower:
	POP		{R0, R1, R2}
	BX		LR 				;Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; InitClocks:
;
; Description:	This function initalizes the GPIO, GPT, and SSI clocks.
;
; Operation:    Writes to the relevant clock control registers to turn on
;				clocks.
;
; Arguments:        None
; Return Values:    None.
;
; Local Variables:  None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   None.
;
; Registers Changed: Clock control registers, R0, R1, R2
; Stack Depth:      2 words (called in main)
;
; Algorithms:       None.
; Data Structures:  None.
; Known Bugs:       None.
;
; Limitations:		Is a blocking function and if there is an initialization
;					error it will block indefinitely.
;
; Revision History: 12/04/23	George Ore	Added documentation
;					01/10/24	George Ore	Added to EE110b HW1 and added serial
;					01/16/24	George Ore	Implemented actual code
;					01/24/24	George Ore
;					02/02/24	George Ore	Added push and pops and updated
;											comments
;
; Pseudo Code
;	GPIOCLKGR = prepare to turn on the GPIO clock power
;	GPTCLKGR = prepare to turn on the GPT clock power
;	SSICLKGR = prepare to turn on the SSI clock power
;	CLKLOADCTL = load start request of prepared clocks
;
;	while (CLKLOADCTL != Load success condition)
;		wait
;
;	return
InitClocks:
	PUSH		{R0, R1, R2}
	MOV32	R1, PRCM					;Load base address
	;Write to GPIOCLKGR to queue the GPIO clock power
	STREG   GPIO_CLOCK_ON, R1, GPIOCLKGR	;GPIO clock power on
	;Write to GPTCLKGR to queue the GPT clock power
	STREG   GPT01_CLK_ON, R1, GPTCLKGR	;GPT0 and GPT1 clocks power on
	;Write to GPTCLKGR to queue the SSI clock power
	STREG   SSI0_CLK_ON, R1, SSICLKGR	;SSI0 clock on
	;Write to CLKLOADCTL to turn on the above clocks
	STREG   LOAD_CLOCKS, R1, CLKLOADCTL		;Load clock settings

;Wait for clock status to be on
	MOV32 	R2, CLOCKS_LOADED	;Load success condition

WaitCLKPON:
	LDR	R0, [R1,#CLKLOADCTL]	;Read CLKLOADCTL to check if settings
								;have loaded successfully

	CMP 	R0, R2 				;Compare test condition with CLKLOADCTL
	BNE		WaitCLKPON			;Keep looping if still loading
	;BEQ	End_InitClock		;End when status confirms clocks are on

;End_InitClocks:
	POP		{R0, R1, R2}
	BX		LR					;Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; InitGPIO
;
; Description:	This function initalizes the GPIO pins to be used in the SPI.
;
; Operation:    Writes to the GPIO control registers.
;
; Arguments:        None
; Return Values:    None.
;
; Local Variables:  None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   None.
;
; Registers Changed: GPIO control registers, R0, R1
; Stack Depth:      1 word
;
; Algorithms:       None.
; Data Structures:  None.
; Known Bugs:       None.
;
; Limitations:      None.
;
; Revision History: 12/04/23	George Ore	Added documentation
; 				  	01/05/23	George Ore	Removed pins 16-17 from being used
;					01/10/24	George Ore	Added to EE110b HW1 and added serial
;					01/16/24	George Ore	Implemetnted code set in pseudo
;					02/02/24	George Ore	Added push and pops and updated
;											comments
;
; Pseudo Code
;
;	IOCFG0 = Set GPIO pin 0 in RX mode
;	IOCFG1 = Set GPIO pin 1 in TX mode
;	IOCFG2 = Set GPIO pin 2 in SSI clock mode
;	IOCFG3 = Set GPIO pin 3 in CS mode
;
;	return
InitGPIO:
	PUSH	{R0, R1}

	MOV32	R1, IOC	;Load base address

	;Write to IOCFG0 to be the RX pin of the SSI0 module
	STREG   IO_SSI0_RX, R1, IOCFG0	;Set GPIO pin 0 as the SSI0 RX

	;Write to IOCFG1 to be the TX pin of the SSI0 module
	STREG   IO_SSI0_TX, R1, IOCFG1	;Set GPIO pin 1 as the SSI0 TX

	;Write to IOCFG2 to be the FSS pin of the SSI0 module
	STREG   IO_SSI0_FSS, R1, IOCFG2	;Set GPIO pin 2 as the SSI0 FSS

	;Write to IOCFG3 to be the CLK pin of the SSI0 module
	STREG   IO_SSI0_CLK, R1, IOCFG3	;Set GPIO pin 3 as the SSI0 CLK

;End_InitGPIO:
	POP		{R0, R1}
	BX		LR							;Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; InitGPTs
;
; Description:	This function initalizes the GPT0 as 1ms clock with interrupts.
;
; Operation:    Writes to the GPT0 control registers.
;
;
; Arguments:        None.
; Return Values:    None.
;
; Local Variables:  None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   None.
;
; Registers Changed: GPT0 control registers, R0, R1
; Stack Depth:      1 word
;
; Algorithms:       None.
; Data Structures:  None.
; Known Bugs:       None.
;
; Limitations:      None.
;
; Revision History: 12/04/23	George Ore	Added documentation
; 					01/05/23	George Ore	Made timers interrupt tested
;					01/10/24	George Ore	Added to EE110b HW1 and added serial
;					02/02/24	George Ore	Added push and pops and updated
;											comments
;
; Pseudo Code
;	GPT0_CFG	= 32 bit timer
;	GPT0_TAMR	= Enable one-shot mode countdown mode
;	GPT0_TAILR	= Set timer duration to 1ms
;	GPT0_IMR	= Enable timeout interrupt
;
;	return
InitGPTs:
	PUSH	{R0, R1}

	;GPT0 will be our 1ms timer
	MOV32	R1, GPT0					;Load base address
	STREG   CFG_32x1, R1, CFG			;32 bit timer
	STREG   TAMR_D_ONE_SHOT, R1, TAMR	;Enable one-shot mode countdown mode
	STREG   TIMER32_1ms, R1, TAILR		;Set timer duration to 1ms
	STREG   IMR_TA_TO, R1, IMR			;Enable timeout interrupt

;End_InitGPTs:
	POP		{R0, R1}
	BX	LR							;Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; InitSSI:
;
; Description:	This function initalizes the SSI0 module to be in SPI mode with
;				a baud rate of 1 MHz with active clock polarity and phase.
;
; Operation:	Writes to the SSI0 control registers.
;
; Arguments:        None.
;
; Return Values:    None.
;
; Local Variables:  None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   None.
;
; Registers Changed: R0, R1
; Stack Depth:      2 words (called in main)
;
; Algorithms:       None.
; Data Structures:  None.
; Known Bugs:       None.
;
; Limitations:      None.
;
; Revision History:	01/10/24	George Ore	Created
; 					01/11/24	George Ore	Added pseudo code
; 					01/??/24	George Ore	Implemented code
; 					02/02/24	George Ore	Updated comments
;
; Pseudo Code
;	SSI:CR1 = serial enable bit reset
;	SSI:CR1 = master mode
;	SSI:CPSR = clock prescale register set to 0
;	SSI:CR0 = clock phase & polarity 1, SPI mode, 16 bit data packets, 1MHz baud
;	SSI:CR1 = serial enable bit set
;
;	return
InitSSI:
	PUSH    {R0, R1}	;Push registers

	MOV32	R1, SSI0					;Load base address
	STREG   SSI_M_DISABLE, R1, SSI_CR1	;Enable SSI
	STREG   SSI_PRE1MHz, R1, SSI_CPSR		;Dont prescale clock
	STREG   SSI_16b_SPI_11_1MHz, R1, SSI_CR0	;Configure SSI settings
	STREG   SSI_M_ENABLE, R1, SSI_CR1	;Enable SSI

;End_InitSSI:
	POP    	{R0, R1}	;Pop registers
	BX		LR			;Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; InitMPU9250:
;
; Description:	This function initializes the settings for the MPU9250 from the
;				CC2652 given it is connected and configured in SPI mode.
;
; Operation:    Writes to registers in the MPU9250 through the SPI.
;
; Arguments:         None.
;
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Registers Changed: R0, R1
; Stack Depth:       2 words (called by main)
;
; Algorithms:        None.
; Data Structures:   None.
; Known Bugs:        None.
;
; Limitations:       Must be called only after SPI has been initalized properly.
;
; Revision History:	01/10/24	George Ore	Created
; 					01/11/24	George Ore	Added pseudo code
; 					01/??/24	George Ore	Implemented
; 					02/02/24	George Ore	Updated comments
;
; Pseudo Code
;	SPICycle(USER_CTRL, Reset all signal paths)
;	SPICycle(USER_CTRL, Enable I2C master module)
;
;	return
InitMPU9250:
	PUSH    {R0, R1}	;Push registers

;Most of the settings are unnecessary but are left as comments for convenient
;and quick additions

;	MOV32		R0, MPU_CONFIG
;	MOV32		R1, CONFIG_DATA
;	PUSH{LR}		;Call SPIWriteCycle
;	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
;	POP{LR}			;Writes MPU9250 cconfiguration settings

;	MOV32		R0, MPU_GYRO_CONFIG
;	MOV32		R1, GYRO_HSENSITIVITY
;	PUSH{LR}		;Call SPIWriteCycle
;	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
;	POP{LR}			;Writes gyro configuration settings to the MPU9250

;	MOV32		R0, MPU_ACCEL_CONFIG
;	MOV32		R1, ACCEL_CONFIG_DATA
;	PUSH{LR}		;Call SPIWriteCycle
;	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
;	POP{LR}			;Writes accelerometer configuration settings to the MPU9250

;	MOV32		R0, MPU_ACCEL_CONFIG2
;	MOV32		R1, ACCEL_CONFIG2_DATA
;	PUSH{LR}		;Call SPIWriteCycle
;	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
;	POP{LR}			;Writes accelerometer configuration settings to the MPU9250

;	MOV32		R0, MPU_I2C_MST_CTRL
;	MOV32		R1, I2C_MST_CTL_DATA
;	PUSH{LR}		;Call SPIWriteCycle
;	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
;	POP{LR}			;Writes I2C master control settings to the MPU9250

;Reset all signal paths
	MOV32		R0, MPU_USER_CTRL
	MOV32		R1, MPU_SIG_PATH_RST
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
	POP{LR}			;Writes user control settings to the MPU9250

;Enable internal I2C master module in master mode
	MOV32		R0, MPU_USER_CTRL
	MOV32		R1, MPU_MASTER_EN
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
	POP{LR}			;Writes user control settings to the MPU9250

;	MOV32		R0, MPU_SMPLRT_DIV
;	MOV32		R1, SMPLRT_DIV_DATA
;	PUSH{LR}		;Call SPIWriteCycle
;	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
;	POP{LR}			;Writes clock settings to the MPU9250

;	MOV32		R0, MPU_I2C_MST_CTRL
;	MOV32		R1, I2C_MST_CTL_DATA
;	PUSH{LR}		;Call SPIWriteCycle
;	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
;	POP{LR}			;Writes I2C master control settings to the MPU9250

;	MOV32		R0, MPU_PWR_MGMT_1
;	MOV32		R1, PWR_MGMT_1_DATA
;	PUSH{LR}		;Call SPIWriteCycle
;	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
;	POP{LR}			;Writes power management settings to the MPU9250

;	MOV32		R0, MPU_PWR_MGMT_2
;	MOV32		R1, PWR_MGMT_2_DATA
;	PUSH{LR}		;Call SPIWriteCycle
;	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
;	POP{LR}			;Writes power management settings to the MPU9250

;End_InitMPU9250:
	POP    	{R0, R1}	;Pop registers
	BX		LR			;Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; InitAK8963:
;
; Description:	Initializes the magnometer AK8963 configurations and settings.
;
; Operation:    The row (r) is passed in R0 by value and the column (c) is
;				passed in R1 by value. The character (ch) is passed in R2 by
;				value.
;
; Arguments:         R0 - Row (-1 if cursor row)
;					 R1 - Column (-1 if cursor column)
;					 R2 - Char data
;
; Return Values:     None.
;
; Local Variables:   None.
; Shared Variables:  cRow, cCol
; Global Variables:  None.
;
; Input:             None (Data memory)
; Output:            LCD Output
;
; Error Handling:    Wraps column index if column is max value on same row
;					 Ignores invalid index inputs
;
; Registers Changed: R0, R1
; Stack Depth:       1 word
;
; Algorithms:        None.
; Data Structures:   None.
; Known Bugs:        None.
;
; Limitations:       None.
;
; Revision History:	01/10/24	George Ore	Created
; 					01/11/24	George Ore	Added pseudo code
;
; Pseudo Code
;	SPICycle(I2C_SVL0_CTRL, enable slave0 and read 16 bytes) *byte grouping or byte swapping?
;
;	SPICycle(I2C_SLV0_DO, CNTL1 settings: continuous mode 16 bit data output)
;	SPICycle(I2C_SLV0_REG, CNTL1 address)
;	SPICycle(I2C_SLV0_ADDR, I2C read into slave0 address) * maybe external regs?
;
;	return
InitAK8963:
	PUSH    {R0, R1}	;Push registers
;	The following code sets the magnometer AK8963 configurations

;Configure four slaves to read different Magnetometer AK8963 registers
;Slave 0 reads status register
	;Target magnetometer with a read command
	MOV32		R0, MPU_I2C_SLV0_ADDR
	MOV32		R1, AK8963
	ADD			R1, #MAG_READ_CMD
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
	POP{LR}			;Connects slave 0 to the magnetometer
					;and sets transfer read mode

	;Load address of targetted register
	MOV32		R0, MPU_I2C_SLV0_REG
	MOV32		R1, AK_ST1
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
	POP{LR}			;Points slave 0 to status register inside the magnetometer

	;Trigger I2C communication
	MOV32		R0, MPU_I2C_SLV0_CTRL
	MOV32		R1, I2C_EN_1BYTE
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
	POP{LR}			;Enables slave to write 1 byte where it was pointing

;Slave 1 reads X measurement register
	;Target magnetometer with a read command
	MOV32		R0, MPU_I2C_SLV1_ADDR
	MOV32	R1, AK8963
	ADD		R1, #MAG_READ_CMD
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
	POP{LR}			;Connects slave 1 to the magnetometer
					;and sets transfer read mode

	;Load address of targetted register
	MOV32		R0, MPU_I2C_SLV1_REG
	MOV32		R1, AK_HXL
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
	POP{LR}			;Points slave 1 to X data register inside the magnetometer

	;Preset byte allocation
	MOV32		R0, MPU_I2C_SLV1_CTRL
	MOV32		R1, I2C_DIS_2BYTE
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
	POP{LR}			;Enables slave to write 1 byte where it was pointing

;Slave 2 reads Y measurement register
	;Target magnetometer with a read command
	MOV32		R0, MPU_I2C_SLV2_ADDR
	MOV32	R1, AK8963
	ADD		R1, #MAG_READ_CMD
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
	POP{LR}			;Connects slave 2 to the magnetometer
					;and sets transfer read mode

	;Load address of targetted register
	MOV32		R0, MPU_I2C_SLV2_REG
	MOV32		R1, AK_HYL
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
	POP{LR}			;Points slave 2 to Y data register inside the magnetometer

	;Preset byte allocation
	MOV32		R0, MPU_I2C_SLV2_CTRL
	MOV32		R1, I2C_DIS_2BYTE
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
	POP{LR}			;Enables slave to write 1 byte where it was pointing

;Slave 3 reads Z measurement register
	;Target magnetometer with a read command
	MOV32		R0, MPU_I2C_SLV3_ADDR
	MOV32	R1, AK8963
	ADD		R1, #MAG_READ_CMD
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
	POP{LR}			;Connects slave 3 to the magnetometer
					;and sets transfer read mode

	;Load address of targetted register
	MOV32		R0, MPU_I2C_SLV3_REG
	MOV32		R1, AK_HZL
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
	POP{LR}			;Points slave 3 to Z data register inside the magnetometer

	;Preset byte allocation
	MOV32		R0, MPU_I2C_SLV3_CTRL
	MOV32		R1, I2C_DIS_2BYTE
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
	POP{LR}			;Enables slave to write 1 byte where it was pointing

;Prep slave 4 to be the module that triggers the magnetometer
	;Target magnetometer with a write command
	MOV32	R0, MPU_I2C_SLV4_ADDR
	MOV32	R1, AK8963
	ADD		R1, #MAG_WRITE_CMD
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
	POP{LR}			;Connects slave 0 to the magnetometer
					;and sets transfer write mode

	;Load address of targetted register
	MOV32		R0, MPU_I2C_SLV4_REG
	MOV32		R1, AK_CNTL
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
	POP{LR}			;Points slave 0 to control register inside the magnetometer

	;Load data to be sent
	MOV32		R0, MPU_I2C_SLV4_DO
	MOV32		R1, MAG_SINGLE_16b_MEASURMENT_MODE	;Single measurement mode
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
	POP{LR}			;Gives slave 0 data to write to the magnetometer

End_InitAK8963:
	POP    	{R0, R1}	;Pop registers
	BX		LR			;Return
