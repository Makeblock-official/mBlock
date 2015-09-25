/**
 * \par Copyright (C), 2012-2015, MakeBlock
 * \class   MeLightSensor
 * \brief   Driver for Me-LightSensor module.
 * @file    MeLightSensor.h
 * @author  MakeBlock
 * @version V1.0.0
 * @date    2015/09/01
 * @brief   Header file for MeLightSensor.cpp
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
 *
 * \par Method List:
 *
 *     1. void    MeLightSensor::setpin(uint8_t ledPin, uint8_t sensorPin);
 *     2. int16_t MeLightSensor::read();
 *     3. void    MeLightSensor::lightOn();
 *     4. void    MeLightSensor::lightOff();
 *
 * \par History:
 * <pre>
 * `<Author>`         `<Time>`        `<Version>`        `<Descr>`
 * Mark Yan         2015/07/24     1.0.0            Rebuild the old lib.
 * Rafael Lee       2015/09/02     1.0.0            Added function setpin and some comments.
 * </pre>
 */


/* Define to prevent recursive inclusion -------------------------------------*/
#ifndef MeLightSensor_H
#define MeLightSensor_H

/* Includes ------------------------------------------------------------------*/
#include <stdint.h>
#include <stdbool.h>
#include <arduino.h>
#include "MeConfig.h"

#ifdef ME_PORT_DEFINED
#include "MePort.h"
#endif // ME_PORT_DEFINED

/**
 * Class: Me4Button
 * \par Description
 *    Declaration of Class Me4Button
 */
#ifndef ME_PORT_DEFINED
class MeLightSensor
#else // !ME_PORT_DEFINED
class MeLightSensor : public MePort
#endif  // !ME_PORT_DEFINED
{
public:
#ifdef ME_PORT_DEFINED
  MeLightSensor();
  MeLightSensor(uint8_t port);
#endif  // ME_PORT_DEFINED
  void setpin(uint8_t ledPin, uint8_t sensorPin);
  int16_t read();
  void lightOn();
  void lightOff();
private:
  uint8_t _ledPin;
  uint8_t _sensorPin;
};

#endif // MeLightSensor_H
