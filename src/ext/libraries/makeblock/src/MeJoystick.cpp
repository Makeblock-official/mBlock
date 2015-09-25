/**
 * \par Copyright (C), 2012-2015, MakeBlock
 * \class   MeJoystick
 * \brief   Driver for Me Joystick module.
 * @file    MeJoystick.cpp
 * @author  MakeBlock
 * @version V1.0.0
 * @date    2015/09/01
 * @brief   Driver for Me Joystick module
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
 * This file is a drive  Me Joystick, It supports Me Joystick V1.1 device provided
 * by MakeBlock.
 *
 * \par Method List:
 *
 *    1. void MeJoystick::setpin(uint8_t port)
 *    2. int16_t MeJoystick::readX(void)
 *    3. int16_t MeJoystick::readY(void)
 *    4. void MeJoystick::CalCenterValue(int16_t x_offset,int16_t y_offset)
 *    5. float MeJoystick::angle(void)
 *    6. float MeJoystick::OffCenter(void)
 *
 * \par History:
 * <pre>
 * `<Author>`         `<Time>`        `<Version>`        `<Descr>`
 * Mark Yan         2015/09/01     1.0.0            Rebuild the old lib.
 * </pre>
 *
 * @example MeJoystickTest.ino
 */
#include "MeJoystick.h"

volatile uint8_t MeJoystick::_X_port = 0;
volatile uint8_t MeJoystick::_Y_port = 0;
volatile int16_t MeJoystick::_X_offset = 0;
volatile int16_t MeJoystick::_Y_offset = 0;

#ifdef ME_PORT_DEFINED
/**
 * Alternate Constructor which can call your own function to map the MeJoystick to arduino port,
 * no pins are used or initialized here.
 * \param[in]
 *   None
 */
MeJoystick::MeJoystick() : MePort(0)
{
}

/**
 * Alternate Constructor which can call your own function to map the MeJoystick to arduino port.
 * \param[in]
 *   port - RJ25 port from PORT_1 to M2
 */
MeJoystick::MeJoystick(uint8_t port) : MePort(port)
{
}
#else // ME_PORT_DEFINED
/**
 * Alternate Constructor which can call your own function to map the MeJoystick to arduino port,
 * it will assigned the X-axis pin and Y-axis pin.
 * \param[in]
 *   x_port - arduino port(should analog pin)
 * \param[in]
 *   y_port - arduino port(should analog pin)
 */
MeJoystick::MeJoystick(uint8_t x_port,uint8_t y_port)
{
  _X_port = x_port;
  _Y_port = y_port;
}
#endif // ME_PORT_DEFINED

/**
 * \par Function
 *   setpin
 * \par Description
 *   Reset the MeJoystick available PIN by its arduino port.
 * \param[in]
 *   x_port - arduino port for X value PIN(should analog pin)
 * \param[in]
 *   y_port - arduino port for Y value PIN(should analog pin)
 * \par Output
 *   None
 * \return
 *   None
 * \par Others
 *   None
 */
void MeJoystick::setpin(uint8_t x_port,uint8_t y_port)
{
  _X_port = x_port;
  _Y_port = y_port;
#ifdef ME_PORT_DEFINED
  s1 = x_port;
  s2 = y_port;
#endif // ME_PORT_DEFINED
}

/**
 * \par Function
 *   readX
 * \par Description
 *   Get the value of X-axis
 * \par Output
 *   None
 * \return
 *   The X-axis value from(-500 - 500)
 * \par Others
 *   None
 */
int16_t MeJoystick::readX(void)
{
  int16_t x_value;
#ifdef ME_PORT_DEFINED
  x_value = MePort::aRead1();
#else // ME_PORT_DEFINED
  x_value = analogRead(_X_port);
#endif // ME_PORT_DEFINED
  x_value = (x_value - CENTER_VALUE) + _X_offset;
  return x_value;
}

/**
 * \par Function
 *   readY
 * \par Description
 *   Get the value of Y-axis
 * \par Output
 *   None
 * \return
 *   The Y-axis value from(-500 - 500)
 * \par Others
 *   None
 */
int16_t MeJoystick::readY(void)
{
  int16_t y_value;
#ifdef ME_PORT_DEFINED
  y_value = MePort::aRead2();
#else // ME_PORT_DEFINED
  y_value = analogRead(_Y_port);
#endif // ME_PORT_DEFINED
  y_value = (y_value - CENTER_VALUE) + _Y_offset;
  return y_value;
}

int16_t MeJoystick::read(int index)
{
  switch(index){
    case 1:return readX();
    case 2:return readY();
  }
  return 0;
}

/**
 * \par Function
 *   CalCenterValue
 * \par Description
 *   If joystick not been triggered(The default middle position), But the X-axis
 *   and Y-axis is not 0, we can use this function to calibration its 0 value.
 * \param[in]
 *   x_offset - The offset vlaue we needed to calibrate the X-axis
 * \param[in]
 *   y_offset - The offset vlaue we needed to calibrate the Y-axis
 * \par Output
 *   None
 * \return
 *   None
 * \par Others
 *   None
 */
void MeJoystick::CalCenterValue(int16_t x_offset,int16_t y_offset)
{
  _X_offset = x_offset;
  _Y_offset = y_offset;
}

/**
 * \par Function
 *   angle
 * \par Description
 *   We can use function to get the angle of the joystick
 * \par Output
 *   None
 * \return
 *   The angle of the joystick(-180 - 180)
 * \par Others
 *   None
 */
float MeJoystick::angle(void)
{
  int16_t x_value;
  int16_t y_value;
  float angle;
#ifdef ME_PORT_DEFINED
  x_value = MePort::aRead1();
  y_value = MePort::aRead2();
#else // ME_PORT_DEFINED
  x_value = analogRead(_X_port);
  y_value = analogRead(_Y_port);
#endif // ME_PORT_DEFINED
  x_value = (x_value - CENTER_VALUE) + _X_offset;
  y_value = (y_value - CENTER_VALUE) + _Y_offset;
  if((abs(x_value) < 10) && (abs(y_value) < 10))
  {
    angle = 0;
  }
  else
  {
    angle = atan2(x_value, y_value) * 180.0 / PI;
  }
  return angle;
}

/**
 * \par Function
 *   OffCenter
 * \par Description
 *   We can use function to get the off-center distance of the joystick
 * \par Output
 *   None
 * \return
 *   The off-center distance of the joystick(0 - 700)
 * \par Others
 *   None
 */
float MeJoystick::OffCenter(void)
{
  long dx   = abs(readX());
  long dy   = abs(readY());
  long dist = dx * dx + dy * dy;
  return(min(CENTER_VALUE*sqrt(2), sqrt(dist)));
}

