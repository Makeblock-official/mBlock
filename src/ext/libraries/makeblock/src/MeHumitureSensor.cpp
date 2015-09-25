/**
 * \par Copyright (C), 2012-2015, MakeBlock
 * \class MeHumiture
 * \brief   Driver for humiture sensor device.
 * @file    MeHumitureSensor.cpp
 * @author  MakeBlock
 * @version V1.0.0
 * @date    2015/09/08
 * @brief   Driver for humiture sensor device.
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
 * This file is a drive for humiture sensor device, It supports humiture sensor
 * provided by the MakeBlock.
 *
 * \par Method List:
 *
 *    1. void MeHumiture::setpin(uint8_t port)
 *    2. void MeHumiture::update(void)
 *    3. uint8_t MeHumiture::getHumidity(void)
 *    4. uint8_t MeHumiture::getTemperature(void)
 *
 * \par History:
 * <pre>
 * `<Author>`         `<Time>`        `<Version>`        `<Descr>`
 * Mark Yan         2015/09/08     1.0.0            Rebuild the old lib.
 * </pre>
 *
 * @example MeHumitureSensorTest.ino
 */
#include "MeHumitureSensor.h"

#ifdef ME_PORT_DEFINED
/**
 * Alternate Constructor which can call your own function to map the humiture sensor to arduino port,
 * no pins are used or initialized here.
 * \param[in]
 *   None
 */
MeHumiture::MeHumiture(void) : MePort(0)
{

}

/**
 * Alternate Constructor which can call your own function to map the temperature sensor to arduino port,
 * the slot2 pin will be used here since specify slot is not be set.
 * \param[in]
 *   port - RJ25 port from PORT_1 to M2
 */
MeHumiture::MeHumiture(uint8_t port) : MePort(port)
{

}
#else // ME_PORT_DEFINED
/**
 * \par Function
 *   setpin
 * \par Description
 *   Reset available PIN for temperature sensor by its arduino port.
 * \param[in]
 *   port - arduino port(should digital pin)
 * \par Output
 *   None
 * \return
 *   None
 * \par Others
 *   None
 */
MeHumiture::MeHumiture(uint8_t port)
{
  _DataPin = port;
}
#endif // ME_PORT_DEFINED

/**
 * \par Function
 *   setpin
 * \par Description
 *   Reset available PIN for temperature sensor by its arduino port.
 * \param[in]
 *   port - arduino port(should digital pin)
 * \par Output
 *   None
 * \return
 *   None
 * \par Others
 *   None
 */
void MeHumiture::setpin(uint8_t port)
{
  _DataPin = port;
  s2 = _DataPin;
}

/**
 * \par Function
 *   update
 * \par Description
 *   Use this function to update the sensor data
 * \par Output
 *   None
 * \return
 *   None
 * \par Others
 *   None
 */
void MeHumiture::update(void)
{
  uint8_t data[5] = {0};
  unsigned long Time, datatime;
  
#ifdef ME_PORT_DEFINED
  MePort::dWrite2(LOW);
  delay(20);
  MePort::dWrite2(HIGH);
  delayMicroseconds(40);
  MePort::dWrite2(LOW);
#else // ME_PORT_DEFINED
  pinMode(_DataPin,OUTPUT);
  digitalWrite(_DataPin,LOW);
  delay(20);
  digitalWrite(_DataPin,HIGH);
  delayMicroseconds(40);
  digitalWrite(_DataPin,LOW);
#endif // ME_PORT_DEFINED
  Time = millis();
#ifdef ME_PORT_DEFINED
  while(MePort::dRead2() != HIGH)
#else // ME_PORT_DEFINED
  pinMode(_DataPin,INPUT);
  while(digitalWrite(_DataPin) != HIGH)
#endif // ME_PORT_DEFINED
  {
    if( ( millis() - Time ) > 2)
    {
      break;
    }
  }

  Time = millis();
  
#ifdef ME_PORT_DEFINED
  while(MePort::dRead2() != LOW)
#else // ME_PORT_DEFINED
  pinMode(_DataPin,INPUT);
  while(digitalWrite(_DataPin) != LOW)
#endif // ME_PORT_DEFINED
  {
    if( ( millis() - Time ) > 2)
    {
      break;
    }
  }

  for(int16_t i=0;i<40;i++)
  {
  	Time = millis();
#ifdef ME_PORT_DEFINED
    while(MePort::dRead2() == LOW)
#else // ME_PORT_DEFINED
    pinMode(_DataPin,INPUT);
    while(digitalWrite(_DataPin) == LOW)
#endif // ME_PORT_DEFINED
    {
      if( ( millis() - Time ) > 2)
      {
        break;
      }
    }

    datatime = micros();
    Time = millis();
#ifdef ME_PORT_DEFINED
    while(MePort::dRead2() == HIGH)
#else // ME_PORT_DEFINED
    pinMode(_DataPin,INPUT);
    while(digitalWrite(_DataPin) == HIGH)
#endif // ME_PORT_DEFINED
    {
      if( ( millis() - Time ) > 2 )
      {
        break;
      }
    }

    if ( micros() - datatime > 40 )
    {
      data[i/8] <<= 1;
      data[i/8] |= 0x01;
    }
    else
    {
      data[i/8] <<= 1;
    }
  }
   
  if( (data[0] + data[2]) == data[4] )
  {
  	Humidity = data[0];
    Temperature = data[2];
  }
}

/**
 * \par Function
 *   getHumidity
 * \par Description
 *   Use this function to Get the Humidity data
 * \par Output
 *   None
 * \return
 *   The value of Humidity
 * \par Others
 *   None
 */
uint8_t MeHumiture::getHumidity(void)
{
  return Humidity;
}

/**
 * \par Function
 *   getTemperature
 * \par Description
 *   Use this function to Get the Temperature data
 * \par Output
 *   None
 * \return
 *   The value of Temperature
 * \par Others
 *   None
 */
uint8_t MeHumiture::getTemperature(void)
{
  return Temperature;
}

