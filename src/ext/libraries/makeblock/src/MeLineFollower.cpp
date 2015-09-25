/**
 * \par Copyright (C), 2012-2015, MakeBlock
 * \class MeLineFollower
 * \brief   Driver for Me line follwer device.
 * @file    MeLineFollower.cpp
 * @author  MakeBlock
 * @version V1.0.0
 * @date    2015/09/07
 * @brief   Driver for Me line follwer device.
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
 *    1. void MeLineFollower::setpin(uint8_t Sensor1,uint8_t Sensor2)
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
 * @example LineFollowerTest.ino
 */

#include "MeLineFollower.h"

volatile uint8_t       MeLineFollower::_Sensor1        = 0;
volatile uint8_t       MeLineFollower::_Sensor2        = 0;

#ifdef ME_PORT_DEFINED
/**
 * Alternate Constructor which can call your own function to map the line follwer device to arduino port,
 * no pins are used or initialized here.
 * \param[in]
 *   None
 */
MeLineFollower::MeLineFollower(void) : MePort(0)
{

}

/**
 * Alternate Constructor which can call your own function to map the line follwer device to arduino port
 * \param[in]
 *   port - RJ25 port from PORT_1 to M2
 */
MeLineFollower::MeLineFollower(uint8_t port) : MePort(port)
{

}
#else // ME_PORT_DEFINED 
/**
 * Alternate Constructor which can call your own function to map the line follwer device to arduino port,
 * it will assigned the input pin.
 * \param[in]
 *   Sensor1 - arduino port(should digital pin)
 * \param[in]
 *   Sensor2 - arduino port(should digital pin)
 */
MeLineFollower::MeLineFollower(uint8_t Sensor1,uint8_t Sensor2)
{
  _Sensor1 = Sensor1;
  _Sensor2 = Sensor2;
  pinMode(_Sensor1,INPUT);
  pinMode(_Sensor2,INPUT);
}
#endif // ME_PORT_DEFINED

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
void MeLineFollower::setpin(uint8_t Sensor1,uint8_t Sensor2)
{
  _Sensor1 = Sensor1;
  _Sensor2 = Sensor2;
  pinMode(_Sensor1,INPUT);
  pinMode(_Sensor2,INPUT);
#ifdef ME_PORT_DEFINED
  s1 = _Sensor1;
  s2 = _Sensor2;
#endif // ME_PORT_DEFINED
}

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
uint8_t MeLineFollower::readSensors(void)
{
  uint8_t state	= S1_IN_S2_IN;
#ifdef ME_PORT_DEFINED
  bool s1State = MePort::dRead1();
  bool s2State = MePort::dRead2();
#else // ME_PORT_DEFINED
  bool s1State = digitalRead(_Sensor1);
  bool s2State = digitalRead(_Sensor2);
#endif // ME_PORT_DEFINED
  state = ( (1 & s1State) << 1) | s2State;
  return(state);
}

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
bool MeLineFollower::readSensor1(void)
{
#ifdef ME_PORT_DEFINED
  return(MePort::dRead1() );
#else // ME_PORT_DEFINED
  return digitalRead(_Sensor1);
#endif // ME_PORT_DEFINED
}

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
bool MeLineFollower::readSensor2(void)
{
#ifdef ME_PORT_DEFINED
	return(MePort::dRead2() );
#else // ME_PORT_DEFINED
  return digitalRead(_Sensor2);
#endif // ME_PORT_DEFINED
}

