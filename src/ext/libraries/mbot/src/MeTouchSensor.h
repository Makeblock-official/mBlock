/**
 * \par Copyright (C), 2012-2015, MakeBlock
 * \class MeTouchSensor
 * \brief   Driver for Me touch sensor device.
 * @file    MeTouchSensor.h
 * @author  MakeBlock
 * @version V1.0.0
 * @date    2015/09/07
 * @brief   Header for for MeTouchSensor.cpp module
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
 * This file is a drive for Me touch sensor device, It supports touch sensor
 * provided by the MakeBlock.
 *
 * \par Method List:
 *
 *    1. void MeTouchSensor::setpin(uint8_t ShotPin, uint8_t FocusPin)
 *    2. bool MeTouchSensor::touched()
 *    3. void MeTouchSensor::SetTogMode(uint8_t TogMode)
 *
 * \par History:
 * <pre>
 * `<Author>`         `<Time>`        `<Version>`        `<Descr>`
 * Mark Yan         2015/09/07     1.0.0            Rebuild the old lib.
 * </pre>
 *
 */
#ifndef MeTouchSensor_H
#define MeTouchSensor_H

#include <stdint.h>
#include <stdbool.h>
#include <arduino.h>
#include "MeConfig.h"

#ifdef ME_PORT_DEFINED
#include "MePort.h"
#endif /* ME_PORT_DEFINED */

/**
 * Class: MeTouchSensor
 * \par Description
 * Declaration of Class MeTouchSensor.
 */
#ifndef ME_PORT_DEFINED
class MeTouchSensor
#else /* !ME_PORT_DEFINED */
class MeTouchSensor : public MePort
#endif // !ME_PORT_DEFINED
{
public:
#ifdef ME_PORT_DEFINED
/**
 * Alternate Constructor which can call your own function to map the touch Sensor to arduino port,
 * no pins are used or initialized here.
 * \param[in]
 *   None
 */
  MeTouchSensor(void);
  
/**
 * Alternate Constructor which can call your own function to map the touch Sensor to arduino port
 * \param[in]
 *   port - RJ25 port from PORT_1 to M2
 */
  MeTouchSensor(uint8_t port);
#else // ME_PORT_DEFINED
/**
 * Alternate Constructor which can call your own function to map the touch Sensor to arduino port,
 * it will assigned the TogPin PIN and OutputPin pin.
 * \param[in]
 *   TogPin - arduino port for output type option pin(should digital pin)
 * \param[in]
 *   OutputPin - arduino port for output pin(should digital pin)
 */
  MeTouchSensor(uint8_t TogPin, uint8_t OutputPin);
#endif // ME_PORT_DEFINED
/**
 * \par Function
 *   setpin
 * \par Description
 *   Reset the touch Sensor available PIN by its arduino port.
 * \param[in]
 *   TogPin - arduino port for output type option pin(should digital pin)
 * \param[in]
 *   OutputPin - arduino port for output pin(should digital pin)
 * \par Output
 *   None
 * \return
 *   None
 * \par Others
 *   None
 */
  void setpin(uint8_t TogPin, uint8_t OutputPin);

/**
 * \par Function
 *   touched
 * \par Description
 *   Read and return the output signal.
 * \par Output
 *   None
 * \return
 *   The output signal of touch sensor
 * \par Others
 *   None
 */
  bool touched(void);

/**
 * \par Function
 *   SetTogMode
 * \par Description
 *   Set the output type.
 * \param[in]
 *   TogMode - 1=> Toggle mode; 0(default)=>Direct mode
 * \par Output
 *   None
 * \return
 *   None
 * \par Others
 *   None
 */
  void SetTogMode(uint8_t TogMode);
private:
  static volatile uint8_t _TogPin;
  static volatile uint8_t _OutputPin;
};

#endif

