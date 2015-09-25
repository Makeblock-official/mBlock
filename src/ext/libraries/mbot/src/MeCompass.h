/**
 * \par Copyright (C), 2012-2015, MakeBlock
 * \class   MeCompass
 * \brief   Driver for MeCompass module.
 * @file    MeCompass.h
 * @author  MakeBlock
 * @version V1.0.0
 * @date    2015/09/01
 * @brief   Header for MeCompass.cpp module.
 *
 * \par Copyright
 * This software is Copyright (C), 2012-2015, MakeBlock. Use is subject to license \n
 * conditions. The main licensing options available are GPL V2 or Commercial: \n
 *
 * \par Open Source Licensing GPL V2
 * This is the appropriate option if you want to share the source code of your \n
 * application with everyone you distribute it to, and you also want to give them \n
 * the right to share who uses it. If you wish to use this software under Open \n
 * Source Licensing, you must contribute all your source code to the open source \n
 * community in accordance with the GPL Version 2 when your application is \n
 * distributed. See http://www.gnu.org/copyleft/gpl.html
 *
 * \par Description
 * This file is a drive for MeCompass module, It supports MeCompass V1.0 device provided
 * by MakeBlock.
 *
 * \par Method List:
 *
 *    1. void MeCompass::setpin(uint8_t keyPin, uint8_t ledPin)
 *    2. void MeCompass::init(void)
 *    3. bool MeCompass::testConnection(void)
 *    4. double MeCompass::getAngle(void)
 *    5. int16_t MeCompass::getHeadingX(void)
 *    6. int16_t MeCompass::getHeadingY(void)
 *    7. int16_t MeCompass::getHeadingZ(void)
 *    8. int16_t MeCompass::getHeading(int16_t *x, int16_t *y, int16_t *z)
 *
 * \par History:
 * <pre>
 * `<Author>`         `<Time>`        `<Version>`        `<Descr>`
 * Lawrence         2015/09/03           1.0.0       Rebuild the old lib.
 * Lawrence         2015/09/08           1.0.0       Added some comments and macros.
 * </pre>
 *
 */

/* Define to prevent recursive inclusion -------------------------------------*/
#ifndef MECOMPASS_H
#define MECOMPASS_H

/* Includes ------------------------------------------------------------------*/
#include <stdint.h>
#include <stdbool.h>
#include <arduino.h>
#include "MeConfig.h"

#ifdef ME_PORT_DEFINED
#include "MePort.h"
#endif /* ME_PORT_DEFINED */

/* Exported macro ------------------------------------------------------------*/
#define COMPASS_SERIAL_DEBUG

#define I2C_ERROR                  (-1)

// Me Compass only has one address
#define COMPASS_DEFAULT_ADDRESS    (0x1E)   

//Me Compass Register Address
#define COMPASS_RA_CONFIG_A        (0x00)
#define COMPASS_RA_CONFIG_B        (0x01)
#define COMPASS_RA_MODE            (0x02)
#define COMPASS_RA_DATAX_H         (0x03)
#define COMPASS_RA_DATAX_L         (0x04)
#define COMPASS_RA_DATAZ_H         (0x05)
#define COMPASS_RA_DATAZ_L         (0x06)
#define COMPASS_RA_DATAY_H         (0x07)
#define COMPASS_RA_DATAY_L         (0x08)
#define COMPASS_RA_STATUS          (0x09)
#define COMPASS_RA_ID_A            (0x0A)
#define COMPASS_RA_ID_B            (0x0B)
#define COMPASS_RA_ID_C            (0x0C)

//define number of samples averaged per measurement
#define COMPASS_AVERAGING_1        (0x00)
#define COMPASS_AVERAGING_2        (0x20)
#define COMPASS_AVERAGING_4        (0x40)
#define COMPASS_AVERAGING_8        (0x60)

//define data output rate value (Hz)
#define COMPASS_RATE_0P75          (0x00)   // 0.75 (Hz)
#define COMPASS_RATE_1P5           (0x40)   // 1.5  (Hz)
#define COMPASS_RATE_3             (0x08)   // 3    (Hz)
#define COMPASS_RATE_7P5           (0x0C)   // 7.5  (Hz)
#define COMPASS_RATE_15            (0x10)   // 15   (Hz)
#define COMPASS_RATE_30            (0x14)   // 30   (Hz)
#define COMPASS_RATE_75            (0x18)   // 75   (Hz)

//define measurement bias value
#define COMPASS_BIAS_NORMAL        (0x00)
#define COMPASS_BIAS_POSITIVE      (0x01)
#define COMPASS_BIAS_NEGATIVE      (0x02)

//define magnetic field gain value
/* -+-------------+-----------------
 *  | Field Range | Gain (LSB/Gauss)
 * -+-------------+-----------------
 *  | +/- 0.88 Ga | 1370
 *  | +/- 1.3 Ga  | 1090 (Default)
 *  | +/- 1.9 Ga  | 820
 *  | +/- 2.5 Ga  | 660
 *  | +/- 4.0 Ga  | 440
 *  | +/- 4.7 Ga  | 390
 *  | +/- 5.6 Ga  | 330
 *  | +/- 8.1 Ga  | 230
 * -+-------------+-----------------*/
#define COMPASS_GAIN_1370          (0x00)
#define COMPASS_GAIN_1090          (0x20)
#define COMPASS_GAIN_820           (0x40)
#define COMPASS_GAIN_660           (0x60)
#define COMPASS_GAIN_440           (0x80)
#define COMPASS_GAIN_390           (0xA0)
#define COMPASS_GAIN_330           (0xC0)
#define COMPASS_GAIN_220           (0xE0)

//define measurement mode
#define COMPASS_MODE_CONTINUOUS    (0x00)
#define COMPASS_MODE_SINGLE        (0x01)
#define COMPASS_MODE_IDLE          (0x02)

//define others parameter
#define COMPASS_PI 3.14159265F
#define START_ADDRESS_OF_EEPROM_BUFFER  (int16_t)(0x00)

/* define a struct to save calibration parameters------------------------------*/
struct Compass_Calibration_Parameter
{
  float X_excursion;
  float Y_excursion;
  float Z_excursion;
  float X_gain;
  float Y_gain;
  float Z_gain;
  uint8_t Rotation_Axis;   //1:X_Axis   2:Y_Axis   3:Z_Axis

  uint8_t verify_flag;
};

/**
 * Class: MeCompass
 * \par Description
 * Declaration of Class MeCompass
 */
#ifndef ME_PORT_DEFINED
class MeCompass
#else // !ME_PORT_DEFINED
class MeCompass : public MePort
#endif // !ME_PORT_DEFINED
{
public:
#ifdef ME_PORT_DEFINED
/**
 * Alternate Constructor which can call your own function to map the MeCompass to arduino port,
 * no pins are used or initialized here
 */
  MeCompass();

/**
 * Alternate Constructor which can call your own function to map the MeCompass to arduino port,
 * no pins are used or initialized here, but PWM frequency set to 976 Hz
 * \param[in]
 *   port - RJ25 port from PORT_1 to M2
 */
  MeCompass(uint8_t port);

/**
 * Alternate Constructor which can call your own function to map the MeCompass to arduino port
 * and change the i2c device address
 * no pins are used or initialized here, but PWM frequency set to 976 Hz
 * \param[in]
 *   port - RJ25 port from PORT_1 to M2
 * \param[in]
 *   address - the i2c address you want to set
 */
  MeCompass(uint8_t port, uint8_t address);
#else
/**
 * Alternate Constructor which can call your own function to map the _keyPin and _ledPin to arduino port,
 * no pins are used or initialized here
 * \param[in]
 *   keyPin - arduino gpio number
 * \param[in]
 *   ledPin - arduino gpio number
 */
  MeCompass(uint8_t keyPin, uint8_t ledPin);

/**
 * Alternate Constructor which can call your own function to map the _keyPin and _ledPin to arduino port
 * and change the i2c device address, no pins are used or initialized here
 * \param[in]
 *   keyPin - arduino gpio number
 * \param[in]
 *   ledPin - arduino gpio number
 * \param[in]
 *   address - the i2c address you want to set
 */
  MeCompass(uint8_t keyPin, uint8_t ledPin, uint8_t address);
#endif  //  ME_PORT_DEFINED
/**
 * \par Function
 *   setpin
 * \par Description
 *   Set the PIN of the button module.
 * \param[in]
 *   keyPin - pin mapping for arduino
 * \param[in]
 *   ledPin - pin mapping for arduino
 * \par Output
 *   None
 * \return
 *   None.
 * \par Others
 *   Set global variable _KeyPin, _ledPin, s1 and s2
 */
  void setpin(uint8_t keyPin, uint8_t ledPin);

/**
 * \par Function
 *   begin
 * \par Description
 *   Initialize the MeCompass.
 * \param[in]
 *   None
 * \par Output
 *   None
 * \return
 *   None
 * \par Others
 *   You can check the HMC5883 datasheet for the macro definition.
 */    
  void begin(void);

/**
 * \par Function
 *   testConnection
 * \par Description
 *   Identify the device whether is the MeCompass.
 * \param[in]
 *   None
 * \par Output
 *   None
 * \return
 *   true or false
 * \par Others
 *   You can check the HMC5883 datasheet for the identification code.
 */
  bool testConnection(void);

/**
 * \par Function
 *   getAngle
 * \par Description
 *   Calculate the yaw angle by the calibrated sensor value.
 * \param[in]
 *   None
 * \par Output
 *   None
 * \return
 *   The angle value from 0 to 360 degrees
 * \par Others
 *   Will return a correct angle when you keep the MeCompass working in the plane which have calibrated.
 */
  double getAngle(void);  

/**
 * \par Function
 *   getHeadingX
 * \par Description
 *   Get the sensor value of X-axis.
 * \param[in]
 *   None
 * \par Output
 *   None
 * \return
 *   The sensor value of X-axis. If error, will return a error code.
 * \par Others
 *   The sensor value is a 16 bits signed integer.
 */
  int16_t getHeadingX(void);

/**
 * \par Function
 *   getHeadingY
 * \par Description
 *   Get the sensor value of Y-axis.
 * \param[in]
 *   None
 * \par Output
 *   None
 * \return
 *   The sensor value of Y-axis. If error, will return a error code.
 * \par Others
 *   The sensor value is a 16 bits signed integer.
 */
  int16_t getHeadingY(void);

/**
 * \par Function
 *   getHeadingZ
 * \par Description
 *   Get the sensor value of Z-axis.
 * \param[in]
 *   None
 * \par Output
 *   None
 * \return
 *   The sensor value of Z-axis. If error, will return a error code.
 * \par Others
 *   The sensor value is a 16 bits signed integer.
 */
  int16_t getHeadingZ(void);

/**
 * \par Function
 *   getHeading
 * \par Description
 *   Get the sensor value of 3 axes including X-axis, Y-axis and Z-axis.
 * \param[in]
 *   x - the address of the variable you want to store the value in.
 * \param[in]
 *   y - the address of the variable you want to store the value in.
 * \param[in]
 *   z - the address of the variable you want to store the value in.
 * \par Output
 *   None
 * \return
 *   If error, will return a error code, else return 0.
 * \par Others
 *   The sequence of the sensor data registors of HMC5883 is X, Z, Y.
 */
  int16_t getHeading(int16_t *x, int16_t *y, int16_t *z);
private:
  static volatile uint8_t  _keyPin;
  static volatile uint8_t  _ledPin;
  bool Calibration_Flag;
  uint8_t buffer[6];
  uint8_t Device_Address;
  uint8_t Measurement_Mode;
  struct Compass_Calibration_Parameter Cal_parameter;

/**
 * \par Function
 *   writeReg
 * \par Description
 *   Write the registor of i2c device.
 * \param[in]
 *   reg - the address of registor.
 * \param[in]
 *   data - the data that will be written to the registor.
 * \par Output
 *   None
 * \return
 *   Return the error code.
 *   the definition of the value of variable return_value:
 *   0:success
 *   1:BUFFER_LENGTH is shorter than size
 *   2:address send, nack received
 *   3:data send, nack received
 *   4:other twi error
 *   refer to the arduino official library twi.c
 * \par Others
 *   To set the registor for initializing.
 */ 
  int8_t writeReg(int16_t reg, uint8_t data);

/**
 * \par Function
 *   writeData
 * \par Description
 *   Write the data to i2c device.
 * \param[in]
 *   start - the address which will write the data to.
 * \param[in]
 *   pData - the head address of data array.
 * \param[in]
 *   size - set the number of data will be written to the devide.
 * \par Output
 *   None
 * \return
 *   Return the error code.
 *   the definition of the value of variable return_value:
 *   0:success
 *   1:BUFFER_LENGTH is shorter than size
 *   2:address send, nack received
 *   3:data send, nack received
 *   4:other twi error
 *   refer to the arduino official library twi.c
 * \par Others
 *   Calling the official i2c library to write data.
 */
  int8_t writeData(uint8_t start, const uint8_t *pData, uint8_t size);

/**
 * \par Function
 *   readData
 * \par Description
 *   Write the data to i2c device.
 * \param[in]
 *   start - the address which will write the data to.
 * \param[in]
 *   pData - the head address of data array.
 * \param[in]
 *   size - set the number of data will be written to the devide.
 * \par Output
 *   None
 * \return
 *   Return the error code.
 *   the definition of the value of variable return_value:
 *   0:success
 *   1:BUFFER_LENGTH is shorter than size
 *   2:address send, nack received
 *   3:data send, nack received
 *   4:other twi error
 *   refer to the arduino official library twi.c
 * \par Others
 *   Calling the official i2c library to read data.
 */
  int8_t readData(uint8_t start, uint8_t *buffer, uint8_t size);  

/**
 * \par Function
 *   deviceCalibration
 * \par Description
 *   Calibration function for the MeCompass. 
 * \param[in]
 *   None
 * \par Output
 *   None
 * \return
 *   None.
 * \par Others
 *   Pressing the button to run the calibration function with the led flickering,
 *   rotate the MeCompass over 360 degress in a stable plane that you specified to calibrate,
 *   and press the button again to finish the calibration.
 */
  void deviceCalibration(void);

/**
 * \par Function
 *   read_EEPROM_Buffer
 * \par Description
 *   Read some calculated calibration parameters from the EEPROM. 
 * \param[in]
 *   None
 * \par Output
 *   None
 * \return
 *   None.
 * \par Others
 *   Calibration parameters will be stored in the struct Compass_Calibration_Parameter.
 *   Call the arduino official EEPROM library.
 */  
  void read_EEPROM_Buffer(void);

/**
 * \par Function
 *   write_EEPROM_Buffer
 * \par Description
 *   Write some calculated calibration parameters to the EEPROM. 
 * \param[in]
 *   parameter_pointer - the address of a struct have stored some calculated calibration parameters.
 * \par Output
 *   None
 * \return
 *   None.
 * \par Others
 *   Calibration parameters will be saved in the EEPROM of the MCU.
 *   Call the arduino official EEPROM library.
 */
  void write_EEPROM_Buffer(struct Compass_Calibration_Parameter *parameter_pointer);
};
#endif // MECOMPASS_H
