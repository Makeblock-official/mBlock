/**
 * \par Copyright (C), 2012-2015, MakeBlock
 * \class MeHumiture
 * \brief   Driver for humiture sensor device.
 * @file    MeHumitureSensor.h
 * @author  MakeBlock
 * @version V1.0.0
 * @date    2015/09/08
 * @brief   Header for for MeHumitureSensor.cpp module
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
 */
#ifndef MeHumitureSensor_H
#define MeHumitureSensor_H

#include <stdint.h>
#include <stdbool.h>
#include <arduino.h>
#include "MeConfig.h"

#ifdef ME_PORT_DEFINED
#include "MePort.h"
#endif // ME_PORT_DEFINED

/**
 * Class: MeHumiture
 * \par Description
 * Declaration of Class MeHumiture.
 */
#ifndef ME_PORT_DEFINED  
class MeHumiture
#else // !ME_PORT_DEFINED
class MeHumiture : public MePort
#endif // !ME_PORT_DEFINED
{
public:
#ifdef ME_PORT_DEFINED
/**
 * Alternate Constructor which can call your own function to map the humiture sensor to arduino port,
 * no pins are used or initialized here.
 * \param[in]
 *   None
 */
  MeHumiture(void);
 
/**
 * Alternate Constructor which can call your own function to map the temperature sensor to arduino port,
 * the slot2 pin will be used here since specify slot is not be set.
 * \param[in]
 *   port - RJ25 port from PORT_1 to M2
 */
  MeHumiture(uint8_t port);
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
  MeHumiture(uint8_t port);
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
  void setpin(uint8_t port);
  
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
  void update(void);

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
  uint8_t getHumidity(void);

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
  uint8_t getTemperature(void);

private:
  uint8_t Humidity;
  uint8_t Temperature;
  static volatile uint8_t  _DataPin;
};

#endif

