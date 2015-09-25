/**
 * \par Copyright (C), 2012-2015, MakeBlock
 * \class   MeCompass
 * \brief   Driver for MeCompass module.
 * @file    MeCompass.cpp
 * @author  MakeBlock
 * @version V1.0.0
 * @date    2015/09/01
 * @brief   Driver for MeCompass module.
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
 * @example MeCompassTest.ino
 */

/* Includes ------------------------------------------------------------------*/
#include "MeCompass.h"

/* Private variables ---------------------------------------------------------*/
volatile uint8_t MeCompass::_keyPin = 0;
volatile uint8_t MeCompass::_ledPin = 0;

/* Private functions ---------------------------------------------------------*/
#ifdef ME_PORT_DEFINED
/**
 * Alternate Constructor which can call your own function to map the MeCompass to arduino port,
 * no pins are used or initialized here
 */
MeCompass::MeCompass() : MePort(0)
{
  Device_Address = COMPASS_DEFAULT_ADDRESS;
  Calibration_Flag = false;
}

/**
 * Alternate Constructor which can call your own function to map the MeCompass to arduino port,
 * no pins are used or initialized here, but PWM frequency set to 976 Hz
 * \param[in]
 *   port - RJ25 port from PORT_1 to M2
 */
MeCompass::MeCompass(uint8_t port) : MePort(port)
{
  Device_Address = COMPASS_DEFAULT_ADDRESS;
  Calibration_Flag = false;
}

/**
 * Alternate Constructor which can call your own function to map the MeCompass to arduino port
 * and change the i2c device address
 * no pins are used or initialized here, but PWM frequency set to 976 Hz
 * \param[in]
 *   port - RJ25 port from PORT_1 to M2
 * \param[in]
 *   address - the i2c address you want to set
 */
MeCompass::MeCompass(uint8_t port, uint8_t address) : MePort(port)
{
  Device_Address = address;
  Calibration_Flag = false;
}
#else  // ME_PORT_DEFINED
/**
 * Alternate Constructor which can call your own function to map the _keyPin and _ledPin to arduino port,
 * no pins are used or initialized here
 * \param[in]
 *   keyPin - arduino gpio number
 * \param[in]
 *   ledPin - arduino gpio number
 */
MeCompass::MeCompass(uint8_t keyPin, uint8_t ledPin)
{
  Device_Address = COMPASS_DEFAULT_ADDRESS;
  Calibration_Flag = false;
  _keyPin = keyPin;
  _ledPin = ledPin;
}

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
MeCompass::MeCompass(uint8_t keyPin, uint8_t ledPin, uint8_t address)
{
  Device_Address = address;
  Calibration_Flag = false;
  _keyPin = keyPin;
  _ledPin = ledPin;
}
#endif // ME_PORT_DEFINED

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
void MeCompass::setpin(uint8_t keyPin, uint8_t ledPin)
{
  _keyPin = keyPin;
  _ledPin = ledPin;
#ifdef ME_PORT_DEFINED
  s1 = keyPin;
  s2 = ledPin;
#endif // ME_PORT_DEFINED
}

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
void MeCompass::begin(void)
{
  Wire.begin();

#ifdef ME_PORT_DEFINED
  dWrite2(HIGH);//LED  
#else  // ME_PORT_DEFINED
  pinMode(_ledPin, OUTPUT);
  digitalWrite(_ledPin, HIGH);
#endif

  // write CONFIG_A register
  writeReg(COMPASS_RA_CONFIG_A, COMPASS_AVERAGING_8 | COMPASS_RATE_15 | COMPASS_BIAS_NORMAL);
  // write CONFIG_B register
  writeReg(COMPASS_RA_CONFIG_B, COMPASS_GAIN_1090);
  // write MODE register
  Measurement_Mode = COMPASS_MODE_SINGLE;
  writeReg(COMPASS_RA_MODE, Measurement_Mode);

  read_EEPROM_Buffer();
  deviceCalibration();
}

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
bool MeCompass::testConnection(void)
{
  if(readData(COMPASS_RA_ID_A, buffer, 3) == 0) 
  {
    return (buffer[0] == 'H' && buffer[1] == '4' && buffer[2] == '3');
  }
  return false;
}

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
 *   The angle value from 0 to 360 degrees. If not success, return an error code.
 * \par Others
 *   Will return a correct angle when you keep the MeCompass working in the plane which have calibrated.
 */
double MeCompass::getAngle(void)
{
  int16_t cx,cy,cz;
  double compass_angle;
  int8_t return_value = 0;
  deviceCalibration();  
  return_value = getHeading(&cx, &cy, &cz);
  if(return_value != 0)
  {
    return (double)return_value;
  }  
  if(Calibration_Flag == true)
  {
    cx = (cx + Cal_parameter.X_excursion) * Cal_parameter.X_gain;
    cy = (cy + Cal_parameter.Y_excursion) * Cal_parameter.Y_gain;
    cz = (cz + Cal_parameter.Z_excursion) * Cal_parameter.Z_gain;  

    if(Cal_parameter.Rotation_Axis == 1)  //X_Axis
    {
      compass_angle = atan2( (double)cy, (double)cz );
    }
    else if(Cal_parameter.Rotation_Axis == 2)  //Y_Axis
    {
      compass_angle = atan2( (double)cx, (double)cz );
    }
    else if(Cal_parameter.Rotation_Axis == 3)  //Z_Axis
    {
      compass_angle = atan2( (double)cy, (double)cx );
    }
  }
  else
  {
    compass_angle = atan2( (double)cy, (double)cx );
  }  

  if(compass_angle < 0)
  {
    compass_angle = (compass_angle + 2 * COMPASS_PI) * 180 / COMPASS_PI;
  }
  else
  {
    compass_angle = compass_angle * 180 / COMPASS_PI;
  }
  return compass_angle;
}

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
int16_t MeCompass::getHeadingX(void)
{
  int8_t return_value = 0;
  deviceCalibration();
  return_value = readData( COMPASS_RA_DATAX_H, buffer, 2 );
  if(return_value != 0)
  {
    return return_value;
  }
  if( Measurement_Mode == COMPASS_MODE_SINGLE )
  {
    writeReg( COMPASS_RA_MODE, COMPASS_MODE_SINGLE );
  } 
  return ( ( (int16_t)buffer[0] ) << 8 ) | buffer[1];
}

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
int16_t MeCompass::getHeadingY(void)
{
  int8_t return_value = 0;
  deviceCalibration();
  return_value = readData(COMPASS_RA_DATAY_H, buffer, 2);
  if(return_value != 0)
  {
    return return_value;
  }
  if(Measurement_Mode == COMPASS_MODE_SINGLE)
  {
    writeReg(COMPASS_RA_MODE, COMPASS_MODE_SINGLE);
  } 
  return ( ( (int16_t)buffer[0] ) << 8) | buffer[1];
}

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
int16_t MeCompass::getHeadingZ(void)
{
  int8_t return_value = 0;
  deviceCalibration();
  return_value = readData(COMPASS_RA_DATAZ_H, buffer, 2);
  if(return_value != 0)
  {
    return return_value;
  }
  if(Measurement_Mode == COMPASS_MODE_SINGLE)
  {
    writeReg(COMPASS_RA_MODE, COMPASS_MODE_SINGLE);
  }     
  return ( ( (int16_t)buffer[0] ) << 8) | buffer[1];
}

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
int16_t MeCompass::getHeading(int16_t *x, int16_t *y, int16_t *z)
{
  int8_t return_value = 0;
  deviceCalibration();
  return_value = readData(COMPASS_RA_DATAX_H, buffer, 6);
  if(return_value != 0)
  {
    return return_value;
  }
  if(Measurement_Mode == COMPASS_MODE_SINGLE)
  {
    writeReg(COMPASS_RA_MODE, COMPASS_MODE_SINGLE);
  } 
  *x = ( ( (int16_t)buffer[0] ) << 8) | buffer[1];
  *y = ( ( (int16_t)buffer[4] ) << 8) | buffer[5];
  *z = ( ( (int16_t)buffer[2] ) << 8) | buffer[3];
  return return_value;
}

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
int8_t MeCompass::writeReg(int16_t reg, uint8_t data)
{
  int8_t return_value = 0;
  return_value = writeData(reg, &data, 1);
  return(return_value);
}

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
int8_t MeCompass::writeData(uint8_t start, const uint8_t *pData, uint8_t size)
{
  int8_t return_value = 0;
  Wire.beginTransmission(Device_Address);
  return_value = Wire.write(start);                  /* write the start address */
  if(return_value != 1)
  {
    return(I2C_ERROR);
  }
  Wire.write(pData, size);            /* write data bytes */
  return_value = Wire.endTransmission(true);     /* release the I2C-bus */
  return(return_value); //return : no error                           
}

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
int8_t MeCompass::readData(uint8_t start, uint8_t *buffer, uint8_t size)
{
  int16_t i = 0;
  int8_t return_value = 0;
  Wire.beginTransmission(Device_Address);
  return_value = Wire.write(start);
  if(return_value != 1)
  {
    return(I2C_ERROR);
  }
  return_value = Wire.endTransmission(false); /* hold the I2C-bus */
  if(return_value != 0)
  {
    return(return_value);
  }
  delayMicroseconds(1);
  /* Third parameter is true: relase I2C-bus after data is read. */
  Wire.requestFrom(Device_Address, size, (uint8_t)true);
  while(Wire.available() && i < size)
  {
    buffer[i++] = Wire.read();
  }
  delayMicroseconds(1);
  if(i != size)
  {
    return(I2C_ERROR);
  }
  return(0); /* return : no error */
}

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
void MeCompass::deviceCalibration(void)
{
#ifdef ME_PORT_DEFINED
  if(dRead1(INPUT_PULLUP) == 0)   //check the KEY
#else  // ME_PORT_DEFINED
  pinMode(_keyPin, INPUT_PULLUP);
  if(digitalRead(_keyPin) == 0)
#endif
  {
  	delay(10);
#ifdef ME_PORT_DEFINED
  	if(dRead1(INPUT_PULLUP) == 0)
#else  // ME_PORT_DEFINED
    pinMode(_keyPin, INPUT_PULLUP);
    if(digitalRead(_keyPin) == 0)
#endif
  	{
      if(testConnection()==false)
      {
#ifdef COMPASS_SERIAL_DEBUG
        Serial.println("It is not Me Compass!!!!!");
#endif
        return;
      }  
      long time_num,cal_time;
      bool LED_state = 0;
      int16_t X_num,Y_num,Z_num;
      int16_t X_max = -32768;
      int16_t X_min = 32767;
      int16_t Y_max = -32768;
      int16_t Y_min = 32767;
      int16_t Z_max = -32768;
      int16_t Z_min = 32767;
      int16_t X_abs,Y_abs,Z_abs;  
#ifdef COMPASS_SERIAL_DEBUG
      Serial.println("Compass calibration !!!");
#endif  
      time_num = millis();
#ifdef ME_PORT_DEFINED
      while(dRead1(INPUT_PULLUP) == 0)
#else  // ME_PORT_DEFINED
      pinMode(_keyPin, INPUT_PULLUP);
      while(digitalRead(_keyPin) == 0)
#endif
      {
        if( millis() - time_num > 200 )   //control the LED
        {
          time_num = millis();
          LED_state = !LED_state;
#ifdef ME_PORT_DEFINED
          dWrite2(LED_state); 
#else  // ME_PORT_DEFINED
          pinMode(_ledPin, OUTPUT);
          digitalWrite(_ledPin, LED_state);
#endif
#ifdef COMPASS_SERIAL_DEBUG
          Serial.println("You can free the KEY now ");
#endif
        }
      }  
#ifdef COMPASS_SERIAL_DEBUG
      Serial.println("collecting value.....");
#endif  
      delay(100);  
      cal_time = millis();
#ifndef ME_PORT_DEFINED 
      pinMode(_keyPin, INPUT_PULLUP);
#endif
      do
      {
        if(millis() - time_num > 200)   //control the LED
        {
          time_num = millis();
          LED_state = !LED_state;
#ifdef ME_PORT_DEFINED
          dWrite2(LED_state); 
#else  // ME_PORT_DEFINED
          pinMode(_ledPin, OUTPUT);
          digitalWrite(_ledPin, LED_state);
#endif
        }
        if(millis() - cal_time > 10)
        {
          getHeading(&X_num,&Y_num,&Z_num);  
          if(X_num < X_min)
          {
            X_min = X_num;
          }
          else if(X_num > X_max)
          {
            X_max = X_num;
          }  
          if(Y_num < Y_min)
          {
            Y_min = Y_num;
          }
          else if(Y_num > Y_max)
          {
            Y_max = Y_num;
          }  
          if(Z_num < Z_min)
          {
            Z_min = Z_num;
          }
          else if(Z_num > Z_max)
          {
            Z_max = Z_num;
          }
        }
      }
#ifdef ME_PORT_DEFINED
      while(dRead1(INPUT_PULLUP)==1);
      dWrite2(LOW);  //turn off the LED
#else  // ME_PORT_DEFINED
      while(digitalRead(_keyPin) == 1);
      pinMode(_ledPin, OUTPUT);
      digitalWrite(_ledPin, LOW);
#endif

      Cal_parameter.X_excursion = -( (float)X_max + (float)X_min ) / 2;
      Cal_parameter.Y_excursion = -( (float)Y_max + (float)Y_min ) / 2;
      Cal_parameter.Z_excursion = -( (float)Z_max + (float)Z_min ) / 2;
      Cal_parameter.X_gain = 1;
      Cal_parameter.Y_gain = ( (float)Y_max - (float)Y_min ) / ( (float)X_max - (float)X_min );
      Cal_parameter.Z_gain = ( (float)Z_max - (float)Z_min ) / ( (float)X_max - (float)X_min );  
      X_abs = abs(X_max-X_min);
      Y_abs = abs(Y_max-Y_min);
      Z_abs = abs(Z_max-Z_min);  
      if(X_abs<=Y_abs && X_abs<=Z_abs)
      {
        Cal_parameter.Rotation_Axis=1;  //X_Axis
      }
      else if(Y_abs<=X_abs && Y_abs<=Z_abs)
      {
        Cal_parameter.Rotation_Axis=2;  //Y_Axis
      }
      else
      {
        Cal_parameter.Rotation_Axis=3;  //Z_Axis
      }  
#ifdef COMPASS_SERIAL_DEBUG
      Serial.println("Print Calibration Parameter:");
      Serial.print("X_excursion: "); Serial.print(Cal_parameter.X_excursion,1); Serial.println(" ");
      Serial.print("Y_excursion: "); Serial.print(Cal_parameter.Y_excursion,1); Serial.println(" ");
      Serial.print("Z_excursion: "); Serial.print(Cal_parameter.Z_excursion,1); Serial.println(" ");
      Serial.print("X_gain: ");      Serial.print(Cal_parameter.X_gain,1);      Serial.println(" ");
      Serial.print("Y_gain: ");      Serial.print(Cal_parameter.Y_gain,1);      Serial.println(" ");
      Serial.print("Z_gain: ");      Serial.print(Cal_parameter.Z_gain,1);      Serial.println(" "); 
      Serial.print("Axis = ");       Serial.print(Cal_parameter.Rotation_Axis);      Serial.println(" ");
#endif  
      write_EEPROM_Buffer(&Cal_parameter);  
#ifdef ME_PORT_DEFINED
      dWrite2(HIGH);   //turn on the LED
      while(dRead1(INPUT_PULLUP) == 0);
#else  // ME_PORT_DEFINED
      pinMode(_ledPin, OUTPUT);
      digitalWrite(_ledPin, HIGH);
      pinMode(_keyPin, INPUT_PULLUP);
      while(digitalRead(_keyPin) == 0);
#endif
      delay(100);
    }
  }
}

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
void MeCompass::read_EEPROM_Buffer(void)
{
  uint8_t verify_number;
  uint8_t parameter_buffer[sizeof(Compass_Calibration_Parameter)];
  struct Compass_Calibration_Parameter *parameter_pointer;
    
  for(int address =0x00; address<sizeof(Compass_Calibration_Parameter); address++)
  {
    parameter_buffer[address]=EEPROM.read(START_ADDRESS_OF_EEPROM_BUFFER + address);
  }  
  parameter_pointer = (struct Compass_Calibration_Parameter *)parameter_buffer;  
  verify_number =(uint8_t)( parameter_pointer -> X_excursion
                          + parameter_pointer -> Y_excursion
                          + parameter_pointer -> Z_excursion
                          + parameter_pointer -> X_gain
                          + parameter_pointer -> Y_gain
                          + parameter_pointer -> Z_gain
                          + parameter_pointer -> Rotation_Axis 
                          + 0xaa  );  
  if(verify_number == parameter_pointer -> verify_flag)
  {
  #ifdef COMPASS_SERIAL_DEBUG
    Serial.println("Verify number is true!!!");
  #endif  
    Cal_parameter = (*parameter_pointer);  
    Calibration_Flag = true;
  }
  else
  {
  #ifdef COMPASS_SERIAL_DEBUG
    Serial.println("Verify number is false!!!");
  #endif  
    Calibration_Flag = false;
  }
}

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
void MeCompass::write_EEPROM_Buffer(struct Compass_Calibration_Parameter *parameter_pointer)
{
  uint8_t *buffer_pointer;
  uint8_t verify_number;  
  parameter_pointer -> verify_flag = (uint8_t)( parameter_pointer -> X_excursion
                                              + parameter_pointer -> Y_excursion
                                              + parameter_pointer -> Z_excursion
                                              + parameter_pointer -> X_gain
                                              + parameter_pointer -> Y_gain
                                              + parameter_pointer -> Z_gain
                                              + parameter_pointer -> Rotation_Axis 
                                              + 0xaa );  
  buffer_pointer = (uint8_t *)parameter_pointer;  
  for(int address = 0x00; address < sizeof(Compass_Calibration_Parameter); address++)
  {
    EEPROM.write(START_ADDRESS_OF_EEPROM_BUFFER + address, *(buffer_pointer+address));
  }  
  Calibration_Flag = true;  
#ifdef COMPASS_SERIAL_DEBUG
  Serial.println("Write EEPROM Buffer Success!!!");
#endif
}
