/**
 * \par Copyright (C), 2012-2015, MakeBlock
 * \class MeSoundSensor
 * \brief   Driver for Me sound sensor device.
 * @file    MeSoundSensor.cpp
 * @author  MakeBlock
 * @version V1.0.0
 * @date    2015/09/04
 * @brief   Driver for Me sound sensor device.
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
 * This file is a drive for Me sound sensor device, It supports sound sensor
 * V1.1 provided by the MakeBlock.
 *
 * \par Method List:
 *
 *    1. void MeSoundSensor::setpin(uint8_t SoundSensorPin)
 *    2. uint8_t MeSoundSensor::strength()
 *
 * \par History:
 * <pre>
 * `<Author>`         `<Time>`        `<Version>`        `<Descr>`
 * Mark Yan         2015/09/04     1.0.0            Rebuild the old lib.
 * </pre>
 *
 * @example SoundSensorTest.ino
 */

#include "MeSoundSensor.h"

volatile uint8_t       MeSoundSensor::_SoundSensorRead        = 0;

#ifdef ME_PORT_DEFINED
/**
 * Alternate Constructor which can call your own function to map the Sound Sensor to arduino port,
 * no pins are used or initialized here.
 * \param[in]
 *   None
 */
MeSoundSensor::MeSoundSensor(void) : MePort(0)
{
}

/**
 * Alternate Constructor which can call your own function to map the Sound Sensor to arduino port
 * \param[in]
 *   port - RJ25 port from PORT_1 to M2
 */
MeSoundSensor::MeSoundSensor(uint8_t port) : MePort(port)
{
}
#else // ME_PORT_DEFINED
/**
 * Alternate Constructor which can call your own function to map the Sound Sensor to arduino port,
 * it will assigned the output pin.
 * \param[in]
 *   port - arduino port(should analog pin)
 */
MeSoundSensor::MeSoundSensor(uint8_t port)
{
  _SoundSensorRead = port;
}
#endif // ME_PORT_DEFINED

/**
 * \par Function
 *   setpin
 * \par Description
 *   Reset the Sound Sensor available PIN by its arduino port.
 * \param[in]
 *   SoundSensorPin - arduino port for sensor read(should analog pin)
 * \par Output
 *   None
 * \return
 *   None
 * \par Others
 *   None
 */
void MeSoundSensor::setpin(uint8_t SoundSensorPin)
{
  _SoundSensorRead = SoundSensorPin;

#ifdef ME_PORT_DEFINED
  s2 = _SoundSensorRead;
#endif // ME_PORT_DEFINED
}

/**
 * \par Function
 *   strength
 * \par Description
 *   Read and return the sensor value.
 * \par Output
 *   None
 * \return
 *   The sensor value of sound sensor
 * \par Others
 *   None
 */
int16_t MeSoundSensor::strength(void)
{
#ifdef ME_PORT_DEFINED
  return(MePort::aRead2());
#else // ME_PORT_DEFINED
  return analogRead(_SoundSensorRead);
#endif // ME_PORT_DEFINED
}

