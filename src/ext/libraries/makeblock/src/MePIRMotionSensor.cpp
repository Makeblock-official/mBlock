/**
 * \par Copyright (C), 2012-2015, MakeBlock
 * \class   MePIRMotionSensor
 * \brief   Driver for Me PIR Motion Sensor module.
 * @file    MePIRMotionSensor.cpp
 * @author  MakeBlock
 * @version V1.0.0
 * @date    2015/09/01
 * @brief   Driver for Me PIR Motion Sensor module.
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
 *    1. void    MePIRMotionSensor::setpin(uint8_t sensorPin);
 *    2. bool    MePIRMotionSensor::isHumanDetected();
 *
 * \par History:
 * <pre>
 * `<Author>`         `<Time>`        `<Version>`        `<Descr>`
 * Mark Yan         2015/07/24     1.0.0            Rebuild the old lib.
 * Rafael Lee       2015/09/07     1.0.0            Added some comments and macros.
 * </pre>
 *
 * @example NumberDisplay.ino \n
 *          NumberFlow.ino \n
 *          TimeDisplay.ino
 */

/* Includes ------------------------------------------------------------------*/
#include "MePIRMotionSensor.h"

/* Private functions ---------------------------------------------------------*/

/**
 * \par Function
 *    MePort
 * \par Description
 *    Class MePIRMotionSensor inherit from MePort if ME_PORT_DEFINED defined. \n
 * \param[in]
 *    None
 * \par Output
 *    None
 * \par Return
 *    None
 * \par Others
 *    None
 */
#ifdef ME_PORT_DEFINED
MePIRMotionSensor::MePIRMotionSensor() : MePort(0)
{
}

/**
 * \par Function
 *    MePort
 * \par Description
 *    Class MePIRMotionSensor inherit from MePort if ME_PORT_DEFINED defined. \n
 *    Set port, set pin2 to input.
 * \param[in]
 *    uint8_t port - Port number.
 * \par Output
 *    None
 * \par Return
 *    None
 * \par Others
 *    None
 */
MePIRMotionSensor::MePIRMotionSensor(uint8_t port) : MePort(port)
{
  pinMode(s2, INPUT);
}

#endif // ME_PORT_DEFINED

/**
 * \par Function
 *    setpin
 * \par Description
 *    Reset the PIR motion sensor available PIN by its arduino port.
 * \param[in]
 *    uint8_t dataPin - The DATA pin for Seven-Segment LED module.
 * \param[in]
 *    uint8_t clkPin - The CLK pin for Seven-Segment LED module.
 * \par Output
 *    None
 * \par Return
 *    None
 * \par Others
 *    Set global variable _KeyPin and s2
 */
void MePIRMotionSensor::setpin(uint8_t sensorPin)
{
  _sensorPin = sensorPin;
  pinMode(_sensorPin, INPUT);
#ifdef ME_PORT_DEFINED
  s2 = sensorPin;
#endif // ME_PORT_DEFINED
}

/**
 * \par Function
 *    isHumanDetected
 * \par Description
 *    Is human been detected.
 * \param[in]
 *    None
 * \par Output
 *    None
 * \par Return
 *    ture: human is detected 
 *    false: no human been detected 
 * \par Others
 *    None
 */
bool MePIRMotionSensor::isHumanDetected()
{
  return(MePort::dRead2());
}

