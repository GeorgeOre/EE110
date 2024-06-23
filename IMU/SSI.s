;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;																			   ;
;						CC2652R SSI Module Functions						   ;
;								George Ore									   ;
;																			   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description:	This file includes functions for controlling the CC2652R's
;				SSI module.
;
; Goal:			The goal of these functions is to facilitate the use of serial
;				communication protocols with the CC2652R microcontroller.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;							Required Constant Files
	.include "constants.inc"	;contains misc. constants
	.include "macros.inc"		;contains all macros
	.include "SSI.inc"			;contains SSI control constants
	.include "IMU.inc"			;contains IMU control constants
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;							Required Functions
;	None.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;							Table of Contents
;		Function Name		|	Purpose
;	General Serial Functions|
	.def	SerialSend		;	Send serial data
	.def	SerialGet		;	Get serial data
	.def	SerialSendRdy	;	Wait for conditions to send serial data
	.def	SerialGetRdy	;	Wait for conditions to get serial data
							;
;	SPI Functions			|
	.def	SPIReadCycle	;	Perform and SPI read
	.def	SPIWriteCycle	;	Perform and SPI write
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Revision History:	02/04/24	George Ore	Created format
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;*******************************************************************************
;*									FUNCTIONS								   *
;*******************************************************************************

;							General Serial Functions

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SerialSend:
;
; Description:	The function is passed data and sends it through the CC2652's
;				SSI module.
;
; Operation:	The SSI data register is written to with the data.
;
; Arguments:        R0 - Data to be sent
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
; Stack Depth:      1 word ***************************
;
; Algorithms:       None.
; Data Structures:  None.
; Known Bugs:       None.
;
; Limitations:      Will have issues if called when the SSI module is not ready
;					to transmit or if the transmit FIFO is full. Must test
;					these conditions before calling this function.
;
; Revision History: 02/02/24	George Ore	Created
;
; Pseudo Code
;	(ARGS: R0 = data)
;	SSI:DR = data 	;Loads data to be transmitted
;					;Transmission is handled by the SSI module
;
;	return R0
SerialSend:
	PUSH    {R0, R1}	;Push registers

	MOV32	R1, SSI0				;Load base address
	STR		R0, [R1, #SSI_DR]	;Load status register with data

;End_SerialSend:
	POP    	{R0, R1}	;Pop registers
	BX		LR			;Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SerialGet:
;
; Description:	Fetches data from the CC2652's SSI module's receive FIFO.
;
; Operation:    Places data from the SSI data register into R0.
;
; Arguments:        None.
; Return Values:    R0 - Data from SSI receive FIFO
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
; Stack Depth:      1 word **************************
;
; Algorithms:       None.
; Data Structures:  None.
; Known Bugs:       None.
;
; Limitations:      Will not have data if reveive FIFO is empty and can have
;					errors if reveive FIFO is full. Status must be checked before.
;
; Revision History: 02/01/24	George Ore	Created and implemented
;
; Pseudo Code
;	R0 = SSI_DR	;Fetches data from the SSI receive FIFO
;	return
SerialGet:
	PUSH    {R1}	;Push registers

	MOV32	R1, SSI0			;Load base address

	LDR		R0, [R1, #SSI_DR]	;Load Data from the SSI receive FIFO

;End_SerialGet:
	POP    	{R1}	;Pop registers
	BX		LR			;Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SerialSendRdy:
;
; Description:	This is a BLOCKING function that waits until the serial status
;				of the CC2652's SSI module is ready to send a transmit command
;
; Operation:    The state of the SSI module is constantly polled. When the
;				status is ready, it returns.
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
; Registers Changed: R0, R1, R2
; Stack Depth:       1 word
;
; Algorithms:        None.
; Data Structures:   None.
; Known Bugs:        None.
;
; Limitations:       None.
;
; Revision History: 01/24/24	George Ore	Created
;
; Pseudo Code
;	while SSI Status Register != SSI_SEND_READY
;		wait
;	return
SerialSendRdy:
	PUSH    {R0, R1, R2}	;Push registers

	MOV32	R1, SSI0				;Load base address
	MOV32	R2, SSI_SEND_READY		;Load SSI ready test condition

SerialSendRdyLoop:
	LDR		R0, [R1, #SSI_SR]	;Load SSI status register
	CMP		R0, R2				;Test if it is ready
	BNE		SerialSendRdyLoop	;Loop if not ready
	;BEQ	End_SerialSendRdy	;If ready, return

End_SerialSendRdy:
	POP    	{R0, R1, R2}	;Pop registers
	BX		LR			;Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SerialGetRdy:
;
; Description:	This is a BLOCKING function that waits until the serial status
;				of the CC2652's SSI module is ready to send a retrieve command
;
; Operation:    The state of the SSI module is constantly polled. When the
;				status is ready, it returns.
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
; Registers Changed: R0, R1, R2
; Stack Depth:       1 word
;
; Algorithms:        None.
; Data Structures:   None.
; Known Bugs:        None.
;
; Limitations:       None.
;
; Revision History: 02/01/24	George Ore	Created and implemented
;
; Pseudo Code
;	while SSI Status Register != SSI_GET_READY
;		wait
;	return
SerialGetRdy:
	PUSH    {R0, R1, R2}	;Push registers

	MOV32	R1, SSI0				;Load base address
	MOV32	R2, SSI_GET_READY		;Load SSI ready test condition

SerialGetRdyLoop:
	LDR		R0, [R1, #SSI_SR]	;Load SSI status register
	CMP		R0, R2				;Test if it is ready
 	BNE		SerialGetRdyLoop	;If not wait
	;BEQ	End_SerialGetRdy	;If ready, return

;End_SerialGetRdy:
	POP    	{R0, R1, R2}	;Pop registers
	BX		LR			;Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;								SPI Functions

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SPIReadDataCMD:
;
; Description:	The function is passed an address and sends a read command
;				to the MPU9250 through SPI.
;
; Operation:	The SSI data register is written to with the address plus the
;				read command bit.
;
; Arguments:        R0 - Address to SPI read from.
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
; Registers Changed: R0
; Stack Depth:      1 word ********************************
;
; Algorithms:       None.
; Data Structures:  None.
; Known Bugs:       None.
;
; Limitations:      None.
;
; Revision History: 01/05/24	George Ore	Created
;					01/12/24	George Ore	Finished pseudo code
;					01/16/24	George Ore	Started code implementation
;					01/25/24	George Ore	Fixed bugs and comments
;					02/01/24	George Ore	Turned into and SPI function
;
; Pseudo Code
;	(ARGS: R0 = address)
;	address(R0) =+ readoperationbit
;	SerialSend( transmit read request to address (R0))
;
;	return
SPIReadDataCMD:
	PUSH    {R0}	;Push registers

	ADD		R0, #SPI_READ	;Add read bit
	LSL		R0, #BYTE_SHIFT	;Format command as expected by the MPU9250
	PUSH{LR}		;Call SerialSend
	BL	SerialSend			;(ARGS: R0 - data to send)
	POP{LR}			;Transmits read command and address

;End_SPIReadDataCMD:
	POP    	{R0}	;Pop registers
	BX		LR			;Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SPIWriteDataCMD:
;
; Description:	The function is passed an address and data which it sends to
;				the MPU9250 through SPI as a write command.
;
; Operation:	The SSI data register is written to with the address, data, and
;				the write command bit.
;
; Arguments:        R0 - Address to send data to and the data (preformatted)
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
; Registers Changed: None.
; Stack Depth:      1 word ************************************
;
; Algorithms:       None.
; Data Structures:  None.
; Known Bugs:       None.
;
; Limitations:      None.
;
; Revision History:	01/16/24	George Ore	Realized that he forgot to document
;											Functionalized code
;					01/24/24	George Ore	Fixed bugs and comments
;					02/01/24	George Ore	Turned into and SPI function
;
; Pseudo Code
;	(ARGS: R0 = address+data)
;	address+data(R0) =+ writeoperationbit
;	SerialSend( transmit write command to address with data all in R0)
;
;	return
SPIWriteDataCMD:

;	ADD		R0, SPI_WRITE		;Add write bit (it is 0 so comment out)
	PUSH{LR}		;Call SerialSend
	BL	SerialSend			;(ARGS: R0 - data and address)
	POP{LR}			;Transmits write command, address, and data

;SPIWriteDataCMD:
	BX		LR			;Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SPIReadCycle:
;
; Description:	The function is passed the address to read from in R0. It reads
;				and stores the value through SPI into R0.
;
; Operation:    The function waits until the SSI module is ready before sending
;				a read command. Then it waits until it is done and fetches the
;				data from the SSI FIFO and returns it in R0.
;
; Arguments:        R0 - Address to read from.
; Return Values:    R0 - Data from the address argument.
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
; Registers Changed: R0
; Stack Depth:      1 word ************************
;
; Algorithms:       None.
; Data Structures:  None.
; Known Bugs:       None.
;
; Limitations:      None.
;
; Revision History:	01/10/24	George Ore	Created
; 					01/11/24	George Ore	Added pseudo code
;					01/16/24	George Ore	Added actual code
;					01/16/24	George Ore	Restructured funciton and
;											added more documentation
;					02/01/24	George Ore	Added proper TX/RX status
;											probing functions
;					02/02/24	George Ore	Added proper TX/RX data
;											getting functions
;
; Pseudo Code
;	(ARGS: R0 = address)
;	if SerialSendRdy() != READY
;		wait
;	SPIReadDataCMD(send command to fetch data at address R0)
;
;	if SerialGetRdy() != READY
;		wait
;	R0 = SerialGet(fetch data from receive FIFO)
;
;	return R0
SPIReadCycle:
;Wait until SPI transmission is possible
	PUSH{LR}		;Call SerialSendRdy
	BL	SerialSendRdy		;(ARGS: None)
	POP{LR}			;Blocking function until SSI is ready to transmit

;Send command to read your data at your intended address
	PUSH{LR}		;Call SPIReadDataCMD
	BL	SPIReadDataCMD		;(ARGS: R0 = data address)
	POP{LR}			;Sends a read command from the inputed address

;Wait until fetching data is possible
	PUSH{LR}		;Call SerialGetRdy
	BL	SerialGetRdy		;(ARGS: None)
	POP{LR}			;Blocking function until SSI FIFO is ready to be retrieved

;Get data you wanted to read
	PUSH{LR}		;Call SerialGet
	BL	SerialGet		;(ARGS: None)
	POP{LR}			;Places read data into R0

;End_SPIReadCycle:
	BX		LR			;Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SPIWriteCycle:
;
; Description:	The function is passed the address to write to in R0 and the
;				data to write in R1. It writes the data in the MPU9250 at the
;				inputted addresss.
;
; Operation:    The function first preformats the address and data for what the
;				MPU9250 expacts. It then waits until the SSI module is ready
;				before sending a write command. Then it waits until it is done
;				and extracts the dummy data from the SSI FIFO before returning.
;
; Arguments:         R0 - Address
;					 R1 - Data
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
; Registers Changed: R0
; Stack Depth:       1 word ********************
;
; Algorithms:        None.
; Data Structures:   None.
; Known Bugs:        None.
;
; Limitations:       None.
;
; Revision History:	01/10/24	George Ore	Created
; 					01/11/24	George Ore	Added pseudo code
;					01/16/24	George Ore	Added actual code
;					02/01/24	George Ore	Added proper TX/RX status
;											probing functions
;					02/02/24	George Ore	Added proper TX/RX data
;											getting functions
;
; Pseudo Code
;	(ARGS: R0 = address, R1 = data)
;	R0 = FormatData&Address(address, data)
;	if SerialSendRdy() != READY
;		wait
;	SPIWriteDataCMD(send command to write data at address)
;
;	if SerialGetRdy() != READY
;		wait
;	R0 = SerialGet(fetch dummy data from receive FIFO)
;
;	return
SPIWriteCycle:
	PUSH    {R0}	;Push registers

;Format data for writing
	LSL	R0, #SPI_DATA_OFFSET	;Adjust address position for SPI transmission
	ADD	R0, R1			;Add data and address in R0 to prep for transmit

;Wait until SPI transmission is possible
	PUSH{LR}	;Call SerialSendRdy
	BL	SerialSendRdy	;(ARGS: None)
	POP{LR}		;Blocking function until SSI is ready to transmit

;Send write command with formatted data
	PUSH{LR}	;Call SerialSendData
	BL	SPIWriteDataCMD	;(ARGS: R0 = address+data)
	POP{LR}		;Sends a write command of the data input at the address input

;Wait until fetching data is possible
	PUSH{LR}		;Call SerialGetRdy
	BL	SerialGetRdy		;(ARGS: None)
	POP{LR}			;Blocking function until SSI FIFO is ready to be retrieved

;Take out dummy recieved data from the FIFO to prevent it from filling up
	PUSH{LR}		;Call SerialGet
	BL	SerialGet		;(ARGS: None)
	POP{LR}			;Places read data into R0

;End_SPIWriteCycle:
	POP    	{R0}	;Pop registers
	BX		LR			;Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SetReadSlave:
;
; Description:	The function is passed the address to write to in R0 and the
;				data to write in R1. It writes the data in the MPU9250 at the
;				inputted addresss.
;
; Operation:    The function first preformats the address and data for what the
;				MPU9250 expacts. It then waits until the SSI module is ready
;				before sending a write command. Then it waits until it is done
;				and extracts the dummy data from the SSI FIFO before returning.
;
; Arguments:         R0 - Address
;					 R1 - Data
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
; Registers Changed: R0
; Stack Depth:       1 word ********************
;
; Algorithms:        None.
; Data Structures:   None.
; Known Bugs:        None.
;
; Limitations:       None.
;
; Revision History:	01/10/24	George Ore	Created
; 					01/11/24	George Ore	Added pseudo code
;					01/16/24	George Ore	Added actual code
;					02/01/24	George Ore	Added proper TX/RX status
;											probing functions
;					02/02/24	George Ore	Added proper TX/RX data
;											getting functions
;
; Pseudo Code
;	(ARGS: R0 = slave number, R1 = register to read, R2 = bytes to read)
;	R0 = FormatData&Address(address, data)
;	if SerialSendRdy() != READY
;		wait
;	SPIWriteDataCMD(send command to write data at address)
;
;	if SerialGetRdy() != READY
;		wait
;	R0 = SerialGet(fetch dummy data from receive FIFO)
;
;	return
SetReadSlave:
	PUSH	{R0, R1, R2, R3}

	PUSH	{R1}
	MOV32	R1, COUNT_DONE
SlaveIndexLoop:
	CMP		R0, R1
	BEQ		SetReadSlaveAddr
	;BNE	UpdateReadSlaveIndex

UpdateReadSlaveIndex:
	ADD		R3, #NEXT_SLAVE_INDEX	;
	SUB		R0, #ONE
	B		SlaveIndexLoop

SetReadSlaveAddr:
	;Target magnetometer with a read command
	MOV32	R0, MPU_I2C_SLV0_ADDR
	ADD		R0, R3
	MOV32	R1, AK8963
	ADD		R1, #MAG_READ_CMD
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
	POP{LR}			;Connects slave to the magnetometer
					;and sets transfer read mode

	;Load address of targetted register
	MOV32	R0, MPU_I2C_SLV0_REG
	ADD		R0, R3
	POP		{R1}
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
	POP{LR}			;Points slave 1 to X data register inside the magnetometer

	;Preset byte allocation
	MOV32	R0, MPU_I2C_SLV0_CTRL
	ADD		R0, R3
	MOV32	R1, I2C_SLV_DISABLE
	ADD		R0, R2
	PUSH{LR}		;Call SPIWriteCycle
	BL	SPIWriteCycle		;(ARGS: R0 = address, R1 = data)
	POP{LR}			;Disables slave to allocate 1 byte where it was pointing
End_SetReadSlave:
	BX	LR
