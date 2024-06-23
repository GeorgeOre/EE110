;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																			   ;
;								EE110b HW1 Functions						   ;
;									George Ore								   ;
;																			   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description:	This file includes the functions that are needed for the HW1
;				main loop.
; Goal:			The goal of these functions is to extract data from the
;				MPU-9250 IMU. It includes functions for the 3-axis
;				accelerometer, 3-axis gyroscope, and the 3-axis magnetometer.
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
	.ref	Wait_1ms
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;								Table of Contents
;		Function Name	|	Purpose
	.def	GetAccelX	;	Fetch accelerometer x-axis data
	.def	GetAccelY	;	Fetch accelerometer y-axis data
	.def	GetAccelZ	;	Fetch accelerometer z-axis data
	.def	GetGyroX	;	Fetch gyroscope x-axis data
	.def	GetGyroY	;	Fetch gyroscope y-axis data
	.def	GetGyroZ	;	Fetch gyroscope z-axis data
	.def	GetMagnetX	;	Fetch magnetometer x-axis data
	.def	GetMagnetY	;	Fetch magnetometer y-axis data
	.def	GetMagnetZ	;	Fetch magnetometer z-axis data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Revision History:	02/04/24	George Ore	Created format
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;*******************************************************************************
;*								FUNCTIONS									   *
;*******************************************************************************

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GetAccelX:
;
; Description:	The function is called with no arguments and returns the current
;				x-axis accelerometer value in R0. This is a 16-bit signed value.
;
; Operation:    Function waits until the serial sending condition is ready by
;				using SerialSendRdy. When ready, it sends a request for the
;				x-axis accelerometer data. Then waits until the serial receiving
;				condition is ready by using SerialGetRdy. When ready, it
;				receives the y-axis accelerometer data and stores it in R0.
;
; Arguments:		None.
;
; Return Values:    R0 = Accelerometer x-axis value
;
; Local Variables:  None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:	None.
;
; Registers Changed: R0, R1
; Stack Depth:      2 words (used in main function)
;
; Algorithms:       None.
; Data Structures:  None.
; Known Bugs:       None.
;
; Limitations:      None.
;
; Revision History:	01/10/24	George Ore	Created and added pseudo code
;					01/13/24	George Ore	Corrected pseudo code
;					01/16/24	George Ore	Started code implementation
;					01/24/24	George Ore	Reworked function
;					01/26/24	George Ore	Impelemented in lab
;
; Pseudo Code
;	R0 = SPIReadCycle(ACCEL_XOUT_L, fetches low x accel data first and then
;						the next address which is high)
;
;	return R0
GetAccelX:
	PUSH    {R1}	;Push registers

	MOV32	R0, ACCEL_XOUT_L	;Address of the lower accelerometer register

	PUSH{LR}
	BL SPIReadCycle
	POP{LR}

	AND	R0, #SSI_DATA_MASK
	MOV		R1, R0	;Store low byte in R1

	MOV32	R0, ACCEL_XOUT_H	;Address of the upper accelerometer register

	PUSH{LR}
	BL SPIReadCycle
	POP{LR}

	AND		R0, #SSI_DATA_MASK
	LSL		R0, #BYTE_SHIFT	;Shift high byte up
	ADD		R0, R1	;Add low byte into R0 before returning

End_GetAccelX:
	POP    	{R1}	;Pop registers
	BX		LR			;Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GetAccelY:
;
; Description:	The function is called with no arguments and returns the current
;				y-axis accelerometer value in R0. This is a 16-bit signed value.
;
; Operation:    Function waits until the serial sending condition is ready by
;				using SerialSendRdy. When ready, it sends a request for the
;				y-axis accelerometer data. Then waits until the serial receiving
;				condition is ready by using SerialGetRdy. When ready, it
;				receives the y-axis accelerometer data and stores it in R0.
;
; Arguments:		None.
;
; Return Values:    R0 = Accelerometer y-axis value
;
; Local Variables:  None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:	None.
;
; Registers Changed: R0, R1
; Stack Depth:      2 words (used in main function)
;
; Algorithms:       None.
; Data Structures:  None.
; Known Bugs:       None.
;
; Limitations:      None.
;
; Revision History:	01/10/24	George Ore	Created and added pseudo code
;					01/13/24	George Ore	Corrected pseudo code
;					01/16/24	George Ore	Started code implementation
;					01/24/24	George Ore	Reworked function
;					01/26/24	George Ore	Impelemented in lab
;
; Pseudo Code
;	R0 = SPIReadCycle(ACCEL_YOUT_L, fetches low Y accel data first and then
;						the next address which is high)
;	return R0
GetAccelY:
	PUSH    {R1}	;Push registers

	MOV32	R0, ACCEL_YOUT_L	;Address of the lower accelerometer register

	PUSH{LR}
	BL	SPIReadCycle
	POP{LR}

	AND	R0, #SSI_DATA_MASK
	MOV		R1, R0	;Store low byte in R1

	MOV32	R0, ACCEL_YOUT_H	;Address of the upper accelerometer register

	PUSH{LR}
	BL	SPIReadCycle
	POP{LR}

	AND	R0, #SSI_DATA_MASK
	LSL		R0, #BYTE_SHIFT	;Shift high byte up
	ADD		R0, R1	;Add low byte into R0 before returning

End_GetAccelY:
	POP    	{R1}	;Pop registers
	BX		LR			;Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GetAccelZ:
;
; Description:	The function is called with no arguments and returns the current
;				z-axis accelerometer value in R0. This is a 16-bit signed value.
;
; Operation:    Function waits until the serial sending condition is ready by
;				using SerialSendRdy. When ready, it sends a request for the
;				z-axis accelerometer data. Then waits until the serial receiving
;				condition is ready by using SerialGetRdy. When ready, it
;				receives the z-axis accelerometer data and stores it in R0.
;
; Arguments:		None.
;
; Return Values:    R0 = Accelerometer z-axis value
;
; Local Variables:  None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:	None.
;
; Registers Changed: R0, R1
; Stack Depth:      2 words (used in main function)
;
; Algorithms:       None.
; Data Structures:  None.
; Known Bugs:       None.
;
; Limitations:      None.
;
; Revision History:	01/10/24	George Ore	Created and added pseudo code
;					01/13/24	George Ore	Corrected pseudo code
;					01/16/24	George Ore	Started code implementation
;					01/24/24	George Ore	Reworked function
;					01/26/24	George Ore	Impelemented in lab
;
; Pseudo Code
;	R0 = SPIReadCycle(ACCEL_ZOUT_L, fetches low Z accel data first and then
;						the next address which is high)
;	return R0
GetAccelZ:
	PUSH    {R1}	;Push registers

	MOV32	R0, ACCEL_ZOUT_L	;Address of the lower accelerometer register

	PUSH{LR}
	BL	SPIReadCycle
	POP{LR}

	AND	R0, #SSI_DATA_MASK
	MOV		R1, R0	;Store low byte in R1

	MOV32	R0, ACCEL_ZOUT_H	;Address of the upper accelerometer register

	PUSH{LR}
	BL	SPIReadCycle
	POP{LR}

	AND	R0, #SSI_DATA_MASK
	LSL		R0, #BYTE_SHIFT	;Shift high byte up
	ADD		R0, R1	;Add low byte into R0 before returning

End_GetAccelZ:
	POP    	{R1}	;Pop registers
	BX		LR			;Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GetGyroX:
;
; Description:	The function is called with no arguments and returns the current
;				x-axis gyroscope value in R0. This is a 16-bit signed value.
;
; Operation:    Function waits until the serial sending condition is ready by
;				using SerialSendRdy. When ready, it sends a request for the
;				x-axis gyroscope data. Then waits until the serial receiving
;				condition is ready by using SerialGetRdy. When ready, it
;				receives the x-axis gyroscope data and stores it in R0.
;
; Arguments:		None.
;
; Return Values:    R0 = Gyro x-axis value
;
; Local Variables:  None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:	None.
;
; Registers Changed: R0, R1
; Stack Depth:      2 words (used in main function)
;
; Algorithms:       None.
; Data Structures:  None.
; Known Bugs:       None.
;
; Limitations:      None.
;
; Revision History:	01/10/24	George Ore	Created and added pseudo code
;					01/13/24	George Ore	Corrected pseudo code
;					01/16/24	George Ore	Started code implementation
;					01/24/24	George Ore	Reworked function
;					01/26/24	George Ore	Impelemented in lab
;
; Pseudo Code
;	R0 = SPIReadCycle(GYRO_XOUT_L, fetches low x gyro data first and then
;						the next address which is high)
;	return R0
GetGyroX:
	PUSH    {R1}	;Push registers

	MOV32	R0, GYRO_XOUT_L	;Address of the lower gyroscope register

	PUSH{LR}
	BL	SPIReadCycle
	POP{LR}

	AND	R0, #SSI_DATA_MASK
	MOV		R1, R0	;Store low byte in R1

	MOV32	R0, GYRO_XOUT_H	;Address of the upper gyroscope register

	PUSH{LR}
	BL	SPIReadCycle
	POP{LR}

	AND	R0, #SSI_DATA_MASK
	LSL		R0, #BYTE_SHIFT	;Shift high byte up
	ADD		R0, R1	;Add low byte into R0 before returning

End_GetGyroX:
	POP    	{R1}	;Pop registers
	BX		LR			;Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GetGyroY:
;
; Description:	The function is called with no arguments and returns the current
;				y-axis gyroscope value in R0. This is a 16-bit signed value.
;
; Operation:    Function waits until the serial sending condition is ready by
;				using SerialSendRdy. When ready, it sends a request for the
;				y-axis gyroscope data. Then waits until the serial receiving
;				condition is ready by using SerialGetRdy. When ready, it
;				receives the y-axis gyroscope data and stores it in R0.
;
; Arguments:		None.
;
; Return Values:    R0 = Gyro y-axis value
;
; Local Variables:  None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:	None.
;
; Registers Changed: R0, R1
; Stack Depth:      2 words (used in main function)
;
; Algorithms:       None.
; Data Structures:  None.
; Known Bugs:       None.
;
; Limitations:      None.
;
; Revision History:	01/10/24	George Ore	Created and added pseudo code
;					01/13/24	George Ore	Corrected pseudo code
;					01/16/24	George Ore	Started code implementation
;					01/24/24	George Ore	Reworked function
;					01/26/24	George Ore	Impelemented in lab
;
; Pseudo Code
;	R0 = SPIReadCycle(GYRO_YOUT_L, fetches low Y gyro data first and then
;						the next address which is high)
;	return R0
GetGyroY:
	PUSH    {R1}	;Push registers

	MOV32	R0, GYRO_YOUT_L	;Address of the lower gyroscope register

	PUSH{LR}
	BL	SPIReadCycle
	POP{LR}

	AND	R0, #SSI_DATA_MASK
	MOV		R1, R0	;Store low byte in R1

	MOV32	R0, GYRO_YOUT_H	;Address of the upper gyroscope register

	PUSH{LR}
	BL	SPIReadCycle
	POP{LR}

	AND	R0, #SSI_DATA_MASK
	LSL		R0, #BYTE_SHIFT	;Shift high byte up
	ADD		R0, R1	;Add low byte into R0 before returning

End_GetGyroY:
	POP    	{R1}	;Pop registers
	BX		LR			;Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GetGyroZ:
;
; Description:	The function is called with no arguments and returns the current
;				z-axis gyroscope value in R0. This is a 16-bit signed value.
;
; Operation:    Function waits until the serial sending condition is ready by
;				using SerialSendRdy. When ready, it sends a request for the
;				z-axis gyroscope data. Then waits until the serial receiving
;				condition is ready by using SerialGetRdy. When ready, it
;				receives the z-axis gyroscope data and stores it in R0.
;
; Arguments:		None.
;
; Return Values:    R0 = Gyro z-axis value
;
; Local Variables:  None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:	None.
;
; Registers Changed: R0, R1
; Stack Depth:      2 words (used in main function)
;
; Algorithms:       None.
; Data Structures:  None.
; Known Bugs:       None.
;
; Limitations:      None.
;
; Revision History:	01/10/24	George Ore	Created and added pseudo code
;					01/13/24	George Ore	Corrected pseudo code
;					01/16/24	George Ore	Started code implementation
;					01/24/24	George Ore	Reworked function
;					01/26/24	George Ore	Impelemented in lab
;
; Pseudo Code
;	R0 = SPIReadCycle(GYRO_ZOUT_L, fetches low Z gyro data first and then
;						the next address which is high)
;
;	return R0
GetGyroZ:
	PUSH    {R1}	;Push registers

	MOV32	R0, GYRO_ZOUT_L	;Address of the lower gyroscope register

	PUSH{LR}
	BL	SPIReadCycle
	POP{LR}

	AND	R0, #SSI_DATA_MASK
	MOV		R1, R0	;Store low byte in R1

	MOV32	R0, GYRO_ZOUT_H	;Address of the upper gyroscope register

	PUSH{LR}
	BL	SPIReadCycle
	POP{LR}

	AND	R0, #SSI_DATA_MASK
	LSL		R0, #BYTE_SHIFT	;Shift high byte up
	ADD		R0, R1	;Add low byte into R0 before returning

End_GetGyroZ:
	POP    	{R1}	;Pop registers
	BX		LR			;Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GetMagnetX:
;
; Description:	The function is called with no arguments and returns the current
;				x-axis magnetometer value in R0. This is a 16-bit signed value.
;
; Operation:    Function waits until the serial sending condition is ready by
;				using SerialSendRdy. When ready, it sends a request for the
;				x-axis magnetometer data. Then waits until the serial receiving
;				condition is ready by using SerialGetRdy. When ready, it
;				receives the x-axis magnetometer data and stores it in R0.
;
; Arguments:		None.
;
; Return Values:    R0 = Magnetometer x-axis value
;
; Local Variables:  None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:	None.
;
; Registers Changed: R0, R1, R2
; Stack Depth:      2 words (used in main function)
;
; Algorithms:       None.
; Data Structures:  None.
; Known Bugs:       None.
;
; Limitations:      None.
;
; Revision History:	01/10/24	George Ore	Created and added pseudo code
;					01/26/24	George Ore	Impelemented in lab unsuccessfully
;					02/01/24	George Ore	Made it actually work
;					02/02/24	George Ore	Finishing touches by turning the whole
;											thing single trigger based
;
; Pseudo Code
;	TriggerMagnetometerON()
;
;	while (triggerstat != triggered)
;		wait
;
;	TriggerMagnetometerOFF()
;
;	while(Status != data fetched successfully)
;		wait
;
;	R0 = SPIReadCycle(high x-axis data)>>8
;	R0 =+ SPIReadCycle(low x-axis data);
;	return R0
GetMagnetX:
	PUSH    {R1, R2}	;Push registers

StartGetMagnetX:
;Send the magnetometer trigger command
	MOV32		R0, MPU_I2C_SLV4_CTRL
	MOV32		R1, I2C_EN_1BYTE
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
	POP{LR}			;Enables slave to write 1 byte where it was pointing

	MOV32		R2, MAG_TRIGGERED

;Test to see if triggering was successful
WaitXMagTrigLoop:
	;Extract the status
	MOV32	R0, MPU_I2C_MST_STATUS

	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIReadCycle		;(ARGS: R0 = address)
	POP{LR}			;Read status

	AND		R0, #MAG_TRIGGERED
	CMP		R0, R2
	BNE		StartGetMagnetX;WaitXMagTrigLoop
	;BEQ	XTrigOff

;XTrigOff:
	;Turn off trigger
	MOV32		R0, MPU_I2C_SLV4_CTRL
	MOV32		R1, I2C_DIS_1BYTE
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
	POP{LR}			;Enables slave to write 1 byte where it was pointing

;See if the magnetometer data is ready
	MOV32	R2, MAG_READY

	;Extract the status
	MOV32	R0, EXT_SENS_DATA_00
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIReadCycle		;(ARGS: R0 = address)
	POP{LR}			;Read status

	AND		R0, #MAG_READY
	CMP		R0, R2
	BEQ		FetchLoopX
	;BNE	MakeXChill

;MakeXChill:
	MOV32	R0, WAIT30
	PUSH{LR}		;Call Wait_1ms
	BL	Wait_1ms		;(ARGS: R0 = ms to wait)
	POP{LR}			;Just chill for a bit

;Now try the whole function again
	B		StartGetMagnetX

;NOW DATA IS READY TO BE EXTRACTED

;Keep attempting to extract until status says data has been fetched
FetchLoopX:
;Trigger reading I2C communication slave and then disable
	MOV32		R0, MPU_I2C_SLV1_CTRL
	MOV32		R1, I2C_EN_2BYTE
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
	POP{LR}			;Enables slave to write 1 byte where it was pointing

	MOV32		R0, MPU_I2C_SLV1_CTRL
	MOV32		R1, I2C_DIS_2BYTE
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
	POP{LR}			;Enables slave to write 1 byte where it was pointing

	MOV32	R2, MAG_DATA_FETCHED

;Extract the status
	MOV32	R0, EXT_SENS_DATA_00
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIReadCycle		;(ARGS: R0 = address)
	POP{LR}			;Read status

	AND		R0, #MAG_STAT_MASK
	CMP		R0, R2
	BNE		FetchLoopX
	;BEQ	FetchDataX

;FetchDataX:
;Extract the x-axis magnetometer data
	MOV32	R0, EXT_SENS_DATA_01

	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIReadCycle		;(ARGS: R0 = address)
	POP{LR}			;Read status of magnetometer into R0

	AND		R0, #BYTEMASK
	MOV		R1, R0

	MOV32	R0, EXT_SENS_DATA_02

	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIReadCycle		;(ARGS: R0 = address)
	POP{LR}			;Read status of magnetometer into R0

	AND		R0, #BYTEMASK
	LSL		R0, #BYTE_SHIFT
	ADD		R0, R1

End_GetMagnetX:
	POP    	{R1, R2}	;Pop registers
	BX		LR			;Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GetMagnetY:
;
; Description:	The function is called with no arguments and returns the current
;				y-axis magnetometer value in R0. This is a 16-bit signed value.
;
; Operation:    Function waits until the serial sending condition is ready by
;				using SerialSendRdy. When ready, it sends a request for the
;				y-axis magnetometer data. Then waits until the serial receiving
;				condition is ready by using SerialGetRdy. When ready, it
;				receives the y-axis magnetometer data and stores it in R0.
;
; Arguments:		None.
;
; Return Values:    R0 = Magnetometer y-axis value
;
; Local Variables:  None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:	None.
;
; Registers Changed: R0, R1, R2
; Stack Depth:      2 words (used in main function)
;
; Algorithms:       None.
; Data Structures:  None.
; Known Bugs:       None.
;
; Limitations:      None.
;
; Revision History:	01/10/24	George Ore	Created and added pseudo code
;					01/26/24	George Ore	Impelemented in lab unsuccessfully
;					02/01/24	George Ore	Made it actually work
;					02/02/24	George Ore	Finishing touches by turning the whole
;											thing single trigger based
;
; Pseudo Code
;	TriggerMagnetometerON()
;
;	while (triggerstat != triggered)
;		wait
;
;	TriggerMagnetometerOFF()
;
;	while(Status != data fetched successfully)
;		wait
;
;	R0 = SPIReadCycle(high y-axis data)>>8
;	R0 =+ SPIReadCycle(low y-axis data);
;	return R0
GetMagnetY:
	PUSH    {R1, R2}	;Push registers

StartGetMagnetY:
;Send the magnetometer trigger command
	MOV32		R0, MPU_I2C_SLV4_CTRL
	MOV32		R1, I2C_EN_1BYTE
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
	POP{LR}			;Enables slave to write 1 byte where it was pointing

	MOV32		R2, MAG_TRIGGERED

;Test to see if triggering was successful
WaitYMagTrigLoop:
	;Extract the status
	MOV32	R0, MPU_I2C_MST_STATUS

	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIReadCycle		;(ARGS: R0 = address)
	POP{LR}			;Read status

	AND		R0, #MAG_TRIGGERED
	CMP		R0, R2
	BNE		StartGetMagnetY;WaitYMagTrigLoop
	;BEQ	YTrigOff

;YTrigOff:
	;Turn off trigger
	MOV32		R0, MPU_I2C_SLV4_CTRL
	MOV32		R1, I2C_DIS_1BYTE
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
	POP{LR}			;Enables slave to write 1 byte where it was pointing

;See if the magnetometer data is ready
	MOV32	R2, MAG_READY

	;Extract the status
	MOV32	R0, EXT_SENS_DATA_00
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIReadCycle		;(ARGS: R0 = address)
	POP{LR}			;Read status

	AND		R0, #MAG_READY
	CMP		R0, R2
	BEQ		FetchLoopY
	;BNE	MakeYChill

;MakeYChill:
	MOV32	R0, WAIT30
	PUSH{LR}		;Call Wait_1ms
	BL	Wait_1ms		;(ARGS: R0 = ms to wait)
	POP{LR}			;Just chill for a bit

;Now try the whole function again
	B		StartGetMagnetY

;NOW DATA IS READY TO BE EXTRACTED

;Keep attempting to extract until status says data has been fetched
FetchLoopY:
;Trigger reading I2C communication slave and then disable
	MOV32		R0, MPU_I2C_SLV2_CTRL
	MOV32		R1, I2C_EN_2BYTE
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
	POP{LR}			;Enables slave to write 1 byte where it was pointing

	MOV32		R0, MPU_I2C_SLV2_CTRL
	MOV32		R1, I2C_DIS_2BYTE
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
	POP{LR}			;Enables slave to write 1 byte where it was pointing

	MOV32	R2, MAG_DATA_FETCHED

;Extract the status
	MOV32	R0, EXT_SENS_DATA_00
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIReadCycle		;(ARGS: R0 = address)
	POP{LR}			;Read status

	AND		R0, #MAG_STAT_MASK
	CMP		R0, R2
	BNE		FetchLoopY
	;BEQ	FetchDataY

;FetchDataY:
;Extract the y-axis magnetometer data
	MOV32	R0, EXT_SENS_DATA_03

	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIReadCycle		;(ARGS: R0 = address)
	POP{LR}			;Read status of magnetometer into R0

	AND		R0, #BYTEMASK
	MOV		R1, R0

	MOV32	R0, EXT_SENS_DATA_04

	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIReadCycle		;(ARGS: R0 = address)
	POP{LR}			;Read status of magnetometer into R0

	AND		R0, #BYTEMASK
	LSL		R0, #BYTE_SHIFT
	ADD		R0, R1

End_GetMagnetY:
	POP    	{R1, R2}	;Pop registers
	BX		LR			;Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GetMagnetZ:
;
; Description:	The function is called with no arguments and returns the current
;				z-axis magnetometer value in R0. This is a 16-bit signed value.
;
; Operation:    Function waits until the serial sending condition is ready by
;				using SerialSendRdy. When ready, it sends a request for the
;				z-axis magnetometer data. Then waits until the serial receiving
;				condition is ready by using SerialGetRdy. When ready, it
;				receives the z-axis magnetometer data and stores it in R0.
;
; Arguments:		None.
;
; Return Values:    R0 = Magnetometer z-axis value
;
; Local Variables:  None.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:	None.
;
; Registers Changed: R0, R1, R2
; Stack Depth:      2 words (used in main function)
;
; Algorithms:       None.
; Data Structures:  None.
; Known Bugs:       None.
;
; Limitations:      None.
;
; Revision History:	01/10/24	George Ore	Created and added pseudo code
;					01/26/24	George Ore	Impelemented in lab unsuccessfully
;					02/01/24	George Ore	Made it actually work
;					02/02/24	George Ore	Finishing touches by turning the whole
;											thing single trigger based
;
; Pseudo Code
;	TriggerMagnetometerON()
;
;	while (triggerstat != triggered)
;		wait
;
;	TriggerMagnetometerOFF()
;
;	while(Status != data fetched successfully)
;		wait
;
;	R0 = SPIReadCycle(high z-axis data)>>8
;	R0 =+ SPIReadCycle(low z-axis data);
;	return R0
GetMagnetZ:
	PUSH    {R1, R2}	;Push registers

StartGetMagnetZ:
;Send the magnetometer trigger command
	MOV32		R0, MPU_I2C_SLV4_CTRL
	MOV32		R1, I2C_EN_1BYTE
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
	POP{LR}			;Enables slave to write 1 byte where it was pointing

	MOV32		R2, MAG_TRIGGERED

;Test to see if triggering was successful
WaitZMagTrigLoop:
	;Extract the status
	MOV32	R0, MPU_I2C_MST_STATUS

	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIReadCycle		;(ARGS: R0 = address)
	POP{LR}			;Read status

	AND		R0, #MAG_TRIGGERED
	CMP		R0, R2
	BNE		StartGetMagnetZ;WaitZMagTrigLoop
	;BEQ	ZTrigOff

;ZTrigOff:
	;Turn off trigger
	MOV32		R0, MPU_I2C_SLV4_CTRL
	MOV32		R1, I2C_DIS_1BYTE
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
	POP{LR}			;Enables slave to write 1 byte where it was pointing

;See if the magnetometer data is ready
	MOV32	R2, MAG_READY

	;Extract the status
	MOV32	R0, EXT_SENS_DATA_00
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIReadCycle		;(ARGS: R0 = address)
	POP{LR}			;Read status

	AND		R0, #MAG_READY
	CMP		R0, R2
	BEQ		FetchLoopZ
	;BNE	MakeZChill

;MakeZChill:
	MOV32	R0, WAIT30
	PUSH{LR}		;Call Wait_1ms
	BL	Wait_1ms		;(ARGS: R0 = ms to wait)
	POP{LR}			;Just chill for a bit

;Now try the whole function again
	B		StartGetMagnetZ

;NOW DATA IS READY TO BE EXTRACTED

;Keep attempting to extract until status says data has been fetched
FetchLoopZ:
;Trigger reading I2C communication slave and then disable
	MOV32		R0, MPU_I2C_SLV3_CTRL
	MOV32		R1, I2C_EN_2BYTE
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
	POP{LR}			;Enables slave to write 1 byte where it was pointing

	MOV32		R0, MPU_I2C_SLV3_CTRL
	MOV32		R1, I2C_DIS_2BYTE
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
	POP{LR}			;Enables slave to write 1 byte where it was pointing

	MOV32	R2, MAG_DATA_FETCHED

;Extract the status
	MOV32	R0, EXT_SENS_DATA_00
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIReadCycle		;(ARGS: R0 = address)
	POP{LR}			;Read status

	AND		R0, #MAG_STAT_MASK
	CMP		R0, R2
	BNE		FetchLoopZ
	;BEQ	FetchDataZ

;FetchDataZ:
;Extract the z-axis magnetometer data
	MOV32	R0, EXT_SENS_DATA_05

	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIReadCycle		;(ARGS: R0 = address)
	POP{LR}			;Read status of magnetometer into R0

	AND		R0, #BYTEMASK
	MOV		R1, R0

	MOV32	R0, EXT_SENS_DATA_06

	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIReadCycle		;(ARGS: R0 = address)
	POP{LR}			;Read status of magnetometer into R0

	AND		R0, #BYTEMASK
	LSL		R0, #BYTE_SHIFT
	ADD		R0, R1

End_GetMagnetZ:
	POP    	{R1, R2}	;Pop registers
	BX		LR			;Return
