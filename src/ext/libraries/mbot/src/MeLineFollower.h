/**
 * \par Copyright (C), 2012-2015, MakeBlock
 * \class MeLineFollower
 * \brief   Driver for Me line follwer device.
 * @file    MeLineFollower.h
 * @author  MakeBlock
 * @version V1.0.0
 * @date    2015/09/07
 * @brief   Header for for MeLineFollower.cpp module
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
 * This file is a drive for Me line follwer device, It supports line follwer device
 * V2.2 provided by the MakeBlock. The line follwer used Infrared Tube to Use infrared
 * receiver and transmitter to detect the black line.
 *
 * \par Method List:
 *
 *    1. void MeSoundSensor::setpin(uint8_t Sensor1,uint8_t Sensor2)
 *    2. uint8_t MeLineFollower::readSensors(void)
 *    3. bool MeLineFollower::readSensor1(void)
 *    4. bool MeLineFollower::readSensor1(void)
 *
 * \par History:
 * <pre>
 * `<Author>`         `<Time>`        `<Version>`        `<Descr>`
 * Mark Yan         2015/09/07     1.0.0            Rebuild the old lib.
 * </pre>
 *
 */
#ifndef MeLineFollower_H
#define MeLineFollower_H

#include <stdint.h>
#include <stdbool.h>
#include <arduino.h>
#include "MeConfig.h"

#ifdef ME_PORT_DEFINED
#include "MePort.h"
#endif // ME_PORT_DEFINED

#define S1_IN_S2_IN   (0x00)    // sensor1 and sensor2 are both inside of black line
#define S1_IN_S2_OUT  (0x01)    // sensor1 is inside of black line and sensor2 is outside of black line
#define S1_OUT_S2_IN  (0x02)    // sensor1 is outside of black line and sensor2 is inside of black line
#define S1_OUT_S2_OUT (0x03)    // sensor1 and sensor2 are both outside of black line

/**
 * Class: MeLineFollower
 * \par Description
 * Declaration of Class MeLineFollower.
 */
#ifndef ME_PORT_DEFINED
class MeLineFollower
#else // !ME_PORT_DEFINED
class MeLineFollower : public MePort
#endif  // ME_PORT_DEFINED
{
public:
#ifdef ME_PORT_DEFINED
/**
 * Alternate Constructor which can call your own function to map the line follwer device to arduino port,
 * no pins are used or initialized here.
 * \param[in]
 *   None
 */
  MeLineFollower(void);

/**
 * Alternate Constructor which can call your own function to map the line follwer device to arduino port
 * \param[in]
 *   port - RJ25 port from PORT_1 to M2
 */
  MeLineFollower(uint8_t port);
#else // ME_PORT_DEFINED 
/**
 * Alternate Constructor which can call your own function to map the line follwer device to arduino port,
 * it will assigned the input pin.
 * \param[in]
 *   Sensor1 - arduino port(should digital pin)
 * \param[in]
 *   Sensor2 - arduino port(should digital pin)
 */
  MeSoundSensor(uint8_t Sensor1,uint8_t Sensor2);
#endif  // ME_PORT_DEFINED
/**
 * \par Function
 *   setpin
 * \par Description
 *   Reset the line follwer device available PIN by its arduino port.
 * \param[in]
 *   Sensor1 - arduino port(should digital pin)
 * \param[in]
 *   Sensor2 - arduino port(should digital pin)
 * \par Output
 *   None
 * \return
 *   None
 * \par Others
 *   None
 */
  void setpin(uint8_t Sensor1,uint8_t Sensor2);

/**
 * \par Function
 *   readSensors
 * \par Description
 *   Get the sensors state.
 * \par Output
 *   None
 * \return
 *   (0x00)-S1_IN_S2_IN:   sensor1 and sensor2 are both inside of black line \n
 *   (0x01)-S1_IN_S2_OUT:  sensor1 is inside of black line and sensor2 is outside of black line \n
 *   (0x02)-S1_OUT_S2_IN:  sensor1 is outside of black line and sensor2 is inside of black line \n
 *   (0x03)-S1_OUT_S2_OUT: sensor1 and sensor2 are both outside of black line
 * \par Others
 *   None
 */
  uint8_t readSensors(void);

/**
 * \par Function
 *   readSensor1
 * \par Description
 *   Get the sensors1(left sensors) state.
 * \par Output
 *   None
 * \return
 *   0: sensor1 is inside of black line \n
 *   1: sensor1 is outside of black line
 * \par Others
 *   None
 */
  bool readSensor1(void);

/**
 * \par Function
 *   readSensor2
 * \par Description
 *   Get the sensors2(right sensors) state.
 * \par Output
 *   None
 * \return
 *   0: sensor1 is inside of black line \n
 *   1: sensor1 is outside of black line
 * \par Others
 *   None
 */
  bool readSensor2(void);
private:
  static volatile uint8_t  _Sensor1;
  static volatile uint8_t  _Sensor2;
};
#endif
