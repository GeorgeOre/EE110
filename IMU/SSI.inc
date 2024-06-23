;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           SSI Control Constants                              ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description:  This file holds constants to be used in the main file
;
; Revision History: 01/16/24    George Ore  Initial revision
;                   02/04/24    George Ore  Revised
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;SSI Constants;;;;;;
;General
ALL_PINS        .EQU    0xFFFFFFFF  ;Represents all pins
NO_PINS         .EQU    0x00000000  ;Represents no pins

;    Mask Constants
SSI_READY_MASK  .EQU    0x10        ;Used to check if the SSI module is ready
SSI_DATA_MASK   .EQU    0xFF        ;Used to ignore irrelevant data bits

;Output Constants
PWM_PIN         .EQU    0x00040000  ;Used to toggle pin 18 with PWM

;;;;;;SPI Constants;;;;;;
;General SPI
SPI_WRITE           .EQU    0x00  ;Indicates an SPI write operation
SPI_READ            .EQU    0x80  ;Indicates an SPI read operation
SPI_DATA_OFFSET     .EQU    8   ;Shifts address value 2 bytes left
TWO_BYTES           .EQU    2   ;Indicates that two bytes have been read


;;;;;;Memory Register Values;;;;;;

;   SSI Control 0 Register SSI_CR0
;   Bits    Name                Code    Description
;   0-3     Data Size Select    0xX     (0xX + 1) represents the data size
;   4-5     Frame Format        0x0     Motorola SPI Frame Format
;                               0x1     TI Synchronous Serial Frame Format
;                               0x2     National Microwire Frame Format
;   6       Serial Polarity     0x0     SSI clock LOW when idle
;                               0x1     SSI clock HIGH when idle
;   7       Serial Phase        0x0     Data captured on the first edge
;                               0x1     Data captured on the second edge
;   8-15    Serial Clock Rate   0xXX    This is used to generate the
;                                       transmit and receive bit rate of the
;                                       SSI. The bit rate is a value from 0-255
;                               (SSI's clock frequency)/((SCR+1)*CPSR.CPSDVSR)
;   16-31   Reserved            0
*ALL TIMES ASSUME 48MHz CLOCK PRESCALED BY 2*
SSI_16b_SPI_00_1MHz .EQU    0x170F  ;Configure SSI clock phase 0, polarity 0,
                                    ;SPI mode, 16 bit data packets, 1MHz clock
SSI_16b_SPI_01_1MHz .EQU    0x174F  ;Configure SSI clock phase 0, polarity 1,
                                    ;SPI mode, 16 bit data packets, 1MHz clock
SSI_16b_SPI_10_1MHz .EQU    0x178F  ;Configure SSI clock phase 1, polarity 0,
                                    ;SPI mode, 16 bit data packets, 1MHz clock
SSI_16b_SPI_11_1MHz .EQU    0x17CF  ;Configure SSI clock phase 1, polarity 1,
                                    ;SPI mode, 16 bit data packets, 1MHz clock

;   SSI Control 1 Register SSI_CR1
;   Bits    Name                Code    Description
;   0       Loop Back Mode      0x0     Normal serial port operation
;                               0x1     Output of transmit serial shifter is
;                                       connected to input of receive
;                                       serial shifter internally
;   1       SSI Enable          0x0     SSI NOT Enabled
;                               0x1     SSI Enabled
;   2       Master/Slave Select 0x0     Master mode
;                               0x1     Slave mode
;   3       Slave-out disable   0x0     SSI can drive TXD output in slave mode
;                               0x1     SSI cannot drive TXD output in slave mode
;   4-31    Reserved            0
SSI_M_ENABLE  .EQU    0x2   ;Turn on SSI in master mode
SSI_M_DISABLE  .EQU    0x0   ;Turn on SSI in master mode
SSI_M_LB_ENABLE  .EQU    0x2   ;Turn on SSI in master mode
SSI_M_LB_DISABLE  .EQU    0x2   ;Turn on SSI in master mode

;   SSI Data Register SSI_DR
;   Bits    Name                Code    Description
;   0-15    Data                0xXXXX  16 bits of SSI data
;   16-31   Reserved            0
SSI_DATAMASK    .EQU    0xFFFF  ;Mask to fetch 16 bit SSI data

;   SSI Status Register SSI_SR
;   Bits    Name                Code    Description
;   0       T-FIFO empty        0/1     Denotes if transmit FIFO is empty
;   1       T-FIFO not full     0/1     Denotes if transmit FIFO is not full
;   2       R-FIFO not empty    0/1     Denotes if receive FIFO is not empty
;   3       R-FIFO full         0/1     Denotes if receive FIFO is full
;   4       Serial Busy         0/1     Denotes if serial interface is busy
;   5-31    Reserved            0
SSI_NBUSY   .EQU    0x00        ;Used to check if the SSI is not busy
SSI_BUSY    .EQU    0x10        ;Used to check if the SSI is busy
SSI_TFIFO_NFULL .EQU    0x2     ;Used to check if the transmit FIFO is not full
SSI_RFIFO_FULL  .EQU    0x8     ;Used to check if the recieve FIFO is full

SSI_GET_READY   .EQU    0x7     ;Used to check if the SSI module is ready to
                                ;fetch from the FIFO
SSI_SEND_READY  .EQU    0x3     ;Used to check if the SSI module is ready to
                                ;send a command
SSI_READY   .EQU    0x0         ;Used in testing

;   SSI Clock Prescale Register SSI_CPSR
;   Bits    Name                Code    Description
;   0-7  Clock Prescale divisor 0xXX    Even value that divides the clock
;   8-31 Reserved               0
SSI_PRE1MHz .EQU    2    ;Prescales the SSI module to have a 1 MHz period

;;;;;;Memory Register Addresses;;;;;;

;Base Address
SSI0    .EQU    0x40000000  ;SSI0 module
SSI1    .EQU    0x40008000  ;SSI1 module

;SSI Data and Control Register Offsets
SSI_CR0     .EQU    0x00    ;SSI Control 0
SSI_CR1     .EQU    0x04    ;SSI Control 1
SSI_DR      .EQU    0x08    ;SSI Data
SSI_SR      .EQU    0x0C    ;SSI Status
SSI_CPSR    .EQU    0x10    ;SSI Clock Prescale
SSI_IMSC    .EQU    0x14    ;SSI Interrupt Mask Set and Clear
SSI_RIS     .EQU    0x18    ;SSI Raw Interrupt Status
SSI_MIS     .EQU    0x1C    ;SSI Masked Interrupt Status
SSI_ICR     .EQU    0x20    ;SSI Interrupt Clear
SSI_DMACR   .EQU    0x24    ;DMA Control
