;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                           IMU Control Constants                              ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Description:  This file holds constants to be used in the main file
;
; Revision History: 01/26/24    George Ore  Initial revision
;                   02/04/24    George Ore  Revised
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;IMU Constants;;;;;;
;General

;Mask Constants

;Slave Setting Constants
NEXT_SLAVE_INDEX    .EQU    3   ;Used for general slave settings

;;;;;;Memory Register Values;;;;;;

;   MPU Configuration Register MPU_CONFIG
;   Bits    Name                Code    Description
;   0-2     Digital Low Pass    xxx     Sets settings for the DLPF connected
;           Filter Configuration        to the gyro and temp sensor
;                                       Relies on Fchoices and tables
;   3-5     External FYNC Set   xxx     We dont need, its for external stuff
;   6       FIFO Mode           0/1     If written 1 when FIFO full, additonal
;                                       writes do not enter. If 0 when FIFO
;                                       full, they will enter FIFO.
;   7       Reserved            0
;NOTHING

;   Gyroscope Configuration Register MPU_GYRO_CONFIG
;   Bits    Name                Code    Description
;   0-1     Fchoice B           xxx     Used to configure the DLPF
;                                       Relies on FCHOICE and tables
;   2       Reserved            0
;   3-4  Gyro Full Scale Select 00      +250 dps
;                               01      +500 dps
;                               10      +1000 dps
;                               11      +2000 dps
;   5       Z-Gyro Self Test    ?       Manufactuer
;   6       Y-Gyro Self Test    ?       Manufactuer
;   7       X-Gyro Self Test    ?       Manufactuer
GYRO_HSENSITIVITY   .EQU    0  ;Highest sensitivity
GYRO_LSENSITIVITY   .EQU    11000b  ;Lowest sensitivity

;   Accelerometer Configuration Register MPU_ACCEL_CONFIG
;   Bits    Name                Code    Description
;   0-2     Reserved            0
;   3-4 Accel Full Scale Select 00      +/- 2 g
;                               01      +/- 4 g
;                               10      +/- 8 g
;                               11      +/- 16 g
;   5       Z-Accel Self Test   ?       Manufactuer
;   6       Y-Accel Self Test   ?       Manufactuer
;   7       X-Accel Self Test   ?       Manufactuer
;NOTHING

;   Accelerometer Configuration 2 Register MPU_ACCEL_CONFIG2
;   Bits    Name                Code    Description
;   0-2   Accelerometer Digital xxx     Used to configure the accel-DLPF
;         Low Pass Filter Configuration Independent from gyro and temp DLPF
;                                       Relies on FCHOICE and tables
;   3     Accelerometer Fchoice         Part of one of the DLPF tables
;   4-5     Reserved            0
;   6-7     Reserved            0
;NOTHING

;   I2C Master Module Control Register MPU_I2C_MST_CTRL
;   Bits    Name                Code    Description
;   0-3     I2C Clock Control   0xX     Sets the I2C clock
;   4   Pause when Slave !Read  0       Restart between reads
;                               1       Stop between reads
;   5       Slave 3 FIFO Enable 0/1     Enable slave 3 to accesss the FIFO
;                                       at the sample rate
;   6   Wait 4 External Sensor  0/1     Set 1 to delay data ready interrupt
;                                       until external sensor data is loaded
;   7       Multi Master Mode   0/1     Set 1 to enable multi master mode
;clock control?

;   I2C Master Module Status Register MPU_I2C_MST_STATUS
;   Bits    Name                Code    Description
;   0       Slave 0 Nack        0/1     This bit is 1 when nack received
;                                       and is interrupt capable
;   1       Slave 1 Nack        0/1     This bit is 1 when nack received
;                                       and is interrupt capable
;   2       Slave 2 Nack        0/1     This bit is 1 when nack received
;                                       and is interrupt capable
;   3       Slave 3 Nack        0/1     This bit is 1 when nack received
;                                       and is interrupt capable
;   4       Slave 4 Nack        0/1     This bit is 1 when nack received
;                                       and is interrupt capable
;   5      I2C Lost Arbitration 0/1     This bit is 1 when a slave looses
;                                       arbitration and is interrupt capable
;   6       Slave 4 Done        0/1     Asserted when slave 4 transfer is
;                                       complete and is interrupt capable
;   7       Pass Through        0/1     Status of FSYNC interrupt
MAG_TRIGGERED   .EQU   0x40
XNACK       .EQU    0x2
YNACK       .EQU    0x4
ZNACK       .EQU    0x8

;   User Control Register MPU_USER_CTRL
;   Bits    Name                Code    Description
;   0       Reset Signal Paths  0/1     Resets gyro, temp, accel signal paths
;                                       Clears sensor registers
;   1       I2C Master Reset    0/1     Reset I2C master module asynchonously
;   2       FIFO Reset          0/1     Reset FIFO module asynchronously
;   3       Reserved            0
;   4     I2C Interface Disable 0/1     Set 1 to reset I2C slave module
;                                       and set to only SPI mode
;   5       I2C Master Enable   0/1     Set 1 to enable I2C master module
;   6       FIFO Enable         0/1     Set 1 to enable FIFO operation mode
;   7       Reserved            0
MPU_MASTER_EN       .EQU        0x20  ;Enable master module
MPU_MASTER_EN_RST   .EQU        0x21  ;Enable master module with reset
MPU_SIG_PATH_RST    .EQU        0x01  ;Reset all signal paths

;   Power Managment Settings 1 Register MPU_PWR_MGMT_1
;   Bits    Name                Code    Description
;   0-2     Clock Selection     0,6     Internal 20 MHz oscillator
;                               1-5     Auto selects the best available clock
;                                       source – PLL if ready, else use 20MHz
;                               7       Stops the clock and keeps timing
;                                       generator in reset
;   3       PD PTAT             0/1     Power down internal PTAT
;   4       Gyro Standby        0/1     Low power mode with quick gyro enable
;   5       Cycle               0/1     When set, will sleep and sample 1
;                                       according to other settings
;   6       Sleep               0/1     Go sleep mode
;   7       Hardware Reset      0/1     Reset
;clokc?

;   Power Managment Settings 2 Register MPU_PWR_MGMT_2
;   Bits    Name                Code    Description
;   0       Disable Gyro Z      0/1     Set to disable
;   1       Disable Gyro Y      0/1     Set to disable
;   2       Disable Gyro X      0/1     Set to disable
;   3       Disable Accel Z     0/1     Set to disable
;   4       Disable Accel Y     0/1     Set to disable
;   5       Disable Accel X     0/1     Set to disable
;   6-7     Reserved            0
;NOTHING

;                       SLAVES

;   I2C Slave X Addressing Register MPU_I2C_SLVX_ADDR
;   Bits    Name                Code    Description
;   0-6     I2C ID              0xXX    Address of I2C device
;   7       Read/Write          0       Transfer is a write
;                               1       Transfer is a read
MAG_WRITE_CMD    .EQU           0x00    ;Used to set write bit
MAG_READ_CMD     .EQU           0x80    ;Used to set read bit

;   I2C Slave X Register Selection Register MPU_I2C_SLVX_REG
;   Bits    Name                Code    Description
;   0-7     Register Address    0xXX    Points to destination address


;   I2C Slave X Control Register MPU_I2C_SLVX_CTRL
;   Bits    Name                Code    Description
;   0-3     Data Length         0xX     Number of bytes
;   4       Group End Condition 0       Groups end in odd numbers
;                               1       Groups end in even numbers
;   5       Register Disable    0/1     Set to disable writing register value
;                                       and to limit to only R/W data
;   6       Byte Swap           0/1     Set to swap bytes
;   7       Slave Enable        0/1     Set to enable
I2C_DIS_1BYTE   .EQU    0x01  ;Disable slave with 1 byte
I2C_DIS_2BYTE   .EQU    0x02  ;Disable slave with 2 bytes
I2C_DIS_3BYTE   .EQU    0x03  ;Disable slave with 3 bytes
I2C_SLV_DISABLE .EQU    0x00  ;Disable slave
;All enables assume groups end in even numbers
I2C_SLV_ENABLE  .EQU    0x90  ;Enable slave
I2C_EN_1BYTE    .EQU    0x91  ;Enable slave with 1 byte
I2C_EN_2BYTE    .EQU    0x92  ;Enable slave with 2 bytes
I2C_EN_3BYTE    .EQU    0x93  ;Enable slave with 3 bytes

;   I2C Slave X Data Out Register MPU_I2C_SLVX_DO
;   Bits    Name                Code    Description
;   0-7     Data Out            0xXX    Data to be used in a write


;                       MAGNETOMETER

;   Magnetometer Status 1 Register AK_ST1
;   Bits    Name                Code    Description
;   0       Data Ready          0/1     Is set when data is ready
;   1       Data Skipped        0/1     Is set when data is skipped
;   2-7     Reserved            0
MAG_NOT_READY       .EQU    0   ;Magnetometer Data Not Ready
MAG_DATA_FETCHED    .EQU    0   ;Magnetometer Data Not Ready
MAG_READY           .EQU    1   ;Magnetometer Data Ready
MAG_READYY          .EQU    2   ;Magnetometer Data Been Ready
MAG_SKIPPED         .EQU    2   ;Magnetometer Data Skipped
MAG_INTERACTED      .EQU    1   ;If greater than or equal to then Mag has data
MAG_STAT_MASK       .EQU    3   ;For masking the status bits

;   Magnetometer Status 2 Register AK_ST2
;   Bits    Name                Code    Description
;   0-2     Reserved            0
;   3       Mag-Sensor Overflow 0/1     Set if yes
;   4       Output Bit Settings 0       14 bit output
;                               1       16 bit output
;   5-7     Reserved            0

;   Magnetometer Control Register AK_CNTL
;   Bits    Name                Code    Description
;   0-3     Operation Mode      0000    Power down mode
;                               0001    Single measurment mode
;                               0010    Continuous mode 1
;                               0110    Continuous mode 2
;                               0100    External trigger mode
;                               1000    Fuse ROM access mode
;                               1111    Self test mode
;   4       Output Bit Settings 0       14 bit output
;                               1       16 bit output
;   5-7     Reserved            0
MAG_POWER_DOWN_MODE      .EQU    0x0
MAG_SINGLE_16b_MEASURMENT_MODE      .EQU    0x11
MAG_SLOW_16b_C_MEASURMENT_MODE  .EQU    0x12
MAG_FAST_16b_C_MEASURMENT_MODE  .EQU    0x16

;;;;;;Memory Register Addresses;;;;;;

;MPU-9250 Registers
MPU_CONFIG          .EQU    0x1A    ;MPU Configuration
MPU_GYRO_CONFIG     .EQU    0x1B    ;Gyroscope Configuration
MPU_ACCEL_CONFIG    .EQU    0x1C    ;Accelerometer Configuration
MPU_ACCEL_CONFIG2   .EQU    0x1D    ;Accelerometer Configuration 2
MPU_I2C_MST_CTRL    .EQU    0x24    ;I2C Master Module Control
MPU_I2C_MST_STATUS  .EQU    0x36    ;I2C Master Module Status
MPU_USER_CTRL       .EQU    0x6A    ;User Control
MPU_PWR_MGMT_1      .EQU    0x6B    ;Power Managment Settings 1
MPU_PWR_MGMT_2      .EQU    0x6C    ;Power Managment Settings 2

MPU_I2C_SLV0_ADDR   .EQU    0x25    ;I2C Slave 0 Addressing
MPU_I2C_SLV0_REG    .EQU    0x26    ;I2C Slave 0 Register Selection
MPU_I2C_SLV0_CTRL   .EQU    0x27    ;I2C Slave 0 Control
MPU_I2C_SLV0_DO     .EQU    0x63    ;I2C Slave 0 Data

MPU_I2C_SLV1_ADDR   .EQU    0x28    ;I2C Slave 1 Addressing
MPU_I2C_SLV1_REG    .EQU    0x29    ;I2C Slave 1 Register Selection
MPU_I2C_SLV1_CTRL   .EQU    0x2A    ;I2C Slave 1 Control
MPU_I2C_SLV1_DO     .EQU    0x64    ;I2C Slave 1 Data

MPU_I2C_SLV2_ADDR   .EQU    0x2B    ;I2C Slave 2 Addressing
MPU_I2C_SLV2_REG    .EQU    0x2C    ;I2C Slave 2 Register Selection
MPU_I2C_SLV2_CTRL   .EQU    0x2D    ;I2C Slave 2 Control
MPU_I2C_SLV2_DO     .EQU    0x65    ;I2C Slave 2 Data

MPU_I2C_SLV3_ADDR   .EQU    0x2E    ;I2C Slave 3 Addressing
MPU_I2C_SLV3_REG    .EQU    0x2F    ;I2C Slave 3 Register Selection
MPU_I2C_SLV3_CTRL   .EQU    0x30    ;I2C Slave 3 Control
MPU_I2C_SLV3_DO     .EQU    0x66    ;I2C Slave 3 Data

MPU_I2C_SLV4_ADDR   .EQU    0x31    ;I2C Slave 4 Addressing
MPU_I2C_SLV4_REG    .EQU    0x32    ;I2C Slave 4 Register Selection
MPU_I2C_SLV4_DO     .EQU    0x33    ;I2C Slave 4 Data Out
MPU_I2C_SLV4_CTRL   .EQU    0x34    ;I2C Slave 4 Control
MPU_I2C_SLV4_DI     .EQU    0x35    ;I2C Slave 4 Data In

ACCEL_XOUT_H        .EQU    0x3B    ;Accelerometer X-Axis High Data
ACCEL_XOUT_L        .EQU    0x3C    ;Accelerometer X-Axis Low Data
ACCEL_YOUT_H        .EQU    0x3D    ;Accelerometer Y-Axis High Data
ACCEL_YOUT_L        .EQU    0x3E    ;Accelerometer Y-Axis Low Data
ACCEL_ZOUT_H        .EQU    0x3F    ;Accelerometer Z-Axis High Data
ACCEL_ZOUT_L        .EQU    0x40    ;Accelerometer Z-Axis Low Data
TEMP_OUT_H          .EQU    0x41    ;Temperature Sensor High Data
TEMP_OUT_L          .EQU    0x42    ;Temperature Sensor Low Data
GYRO_XOUT_H         .EQU    0x43    ;Gyroscope X-Axis High Data
GYRO_XOUT_L         .EQU    0x44    ;Gyroscope X-Axis Low Data
GYRO_YOUT_H         .EQU    0x45    ;Gyroscope Y-Axis High Data
GYRO_YOUT_L         .EQU    0x46    ;Gyroscope Y-Axis Low Data
GYRO_ZOUT_H         .EQU    0x47    ;Gyroscope Z-Axis High Data
GYRO_ZOUT_L         .EQU    0x48    ;Gyroscope Z-Axis Low Data
EXT_SENS_DATA_00    .EQU    0x49    ;Slave Data Register 00
EXT_SENS_DATA_01    .EQU    0x4A    ;Slave Data Register 01
EXT_SENS_DATA_02    .EQU    0x4B    ;Slave Data Register 02
EXT_SENS_DATA_03    .EQU    0x4C    ;Slave Data Register 03
EXT_SENS_DATA_04    .EQU    0x4D    ;Slave Data Register 04
EXT_SENS_DATA_05    .EQU    0x4E    ;Slave Data Register 05
EXT_SENS_DATA_06    .EQU    0x4F    ;Slave Data Register 06

;AK8963 Magnetometer
AK8963              .EQU    0x0C    ;Magnetometer Device Address
AK_ST1              .EQU    0x02    ;Magnetometer Status 1
AK_HXL              .EQU    0x03    ;Magnetometer X-Axis Low Data
AK_HXH              .EQU    0x04    ;Magnetometer X-Axis High Data
AK_HYL              .EQU    0x05    ;Magnetometer Y-Axis Low Data
AK_HYH              .EQU    0x06    ;Magnetometer Y-Axis High Data
AK_HZL              .EQU    0x07    ;Magnetometer Z-Axis Low Data
AK_HZH              .EQU    0x08    ;Magnetometer Z-Axis High Data
AK_ST2              .EQU    0x09    ;Magnetometer Status 2
AK_CNTL             .EQU    0x0A    ;Magnetometer Control
AK_WHOAMI           .EQU    0x00    ;Magnetometer Identification Number
