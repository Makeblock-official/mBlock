/**
 * \par Copyright (C), 2012-2015, MakeBlock
 * \class   MeJoystick
 * \brief   Driver for Me Joystick module.
 * @file    MeJoystick.h
 * @author  MakeBlock
 * @version V1.0.0
 * @date    2015/09/01
 * @brief   Header for MeJoystick.cpp module
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
 */
#ifndef MeJoystick_H
#define MeJoystick_H

#include <stdint.h>
#include <stdbool.h>
#include <arduino.h>
#include "MeConfig.h"

#ifdef ME_PORT_DEFINED
#include "MePort.h"
#endif // ME_PORT_DEFINED

#define CENTER_VALUE    (490)

/**
 * Class: MeJoystick
 * \par Description
 * Declaration of Class MeJoystick.
 */
#ifndef ME_PORT_DEFINED
class MeJoystick
#else // !ME_PORT_DEFINED
class MeJoystick : public MePort
#endif
{
  public:
#ifdef ME_PORT_DEFINED
/**
 * Alternate Constructor which can call your own function to map the MeJoystick to arduino port,
 * no pins are used or initialized here.
 * \param[in]
 *   None
 */
    MeJoystick();

/**
 * Alternate Constructor which can call your own function to map the MeJoystick to arduino port.
 * \param[in]
 *   port - RJ25 port from PORT_1 to M2
 */
    MeJoystick(uint8_t port);
#else // ME_PORT_DEFINED
/**
 * Alternate Constructor which can call your own function to map the MeJoystick to arduino port,
 * it will assigned the X-axis pin and Y-axis pin
 * \param[in]
 *   x_port - arduino port(should analog pin)
 * \param[in]
 *   y_port - arduino port(should analog pin)
 */
    MeJoystick(uint8_t x_port,uint8_t y_port);
#endif  // ME_PORT_DEFINED

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
    void setpin(uint8_t x_port, uint8_t y_port);

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
    int16_t readX();

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
    int16_t readY();
    int16_t read(int index);

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
    void CalCenterValue(int16_t = 0, int16_t = 0);

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
    float angle();

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
    float OffCenter();
  private:
    static volatile int16_t _X_offset;
    static volatile int16_t _Y_offset;
    static volatile uint8_t _X_port;
    static volatile uint8_t _Y_port;
};
#endif
