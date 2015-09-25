/**
 * \par Copyright (C), 2012-2015, MakeBlock
 * \class MeShutter
 * \brief   Driver for Me Shutter device.
 * @file    MeShutter.cpp
 * @author  MakeBlock
 * @version V1.0.0
 * @date    2015/09/04
 * @brief   Driver for Me Shutter device.
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
 * This file is a drive for Me Shutter device, It supports Me Shutter device
 * V1.0 provided by the MakeBlock.
 *
 * \par Method List:
 *
 *    1. void MeShutter::setpin(uint8_t ShotPin, uint8_t FocusPin)
 *    2. uint8_t MeShutter::shotOn()
 *    3. uint8_t MeShutter::shotOff()
 *    4. uint8_t MeShutter::focusOn()
 *    5. uint8_t MeShutter::focusOff()
 *
 * \par History:
 * <pre>
 * `<Author>`         `<Time>`        `<Version>`        `<Descr>`
 * Mark Yan         2015/09/04     1.0.0            Rebuild the old lib.
 * </pre>
 *
 * @example MeShutterTest.ino
 */
#include "MeShutter.h"

volatile uint8_t       MeShutter::_ShotPin             = 0;
volatile uint8_t       MeShutter::_FocusPin            = 0;

#ifdef ME_PORT_DEFINED
/**
 * Alternate Constructor which can call your own function to map the MeShutter to arduino port,
 * no pins are used or initialized here.
 * \param[in]
 *   None
 */
MeShutter::MeShutter(void) : MePort(0)
{

}

/**
 * Alternate Constructor which can call your own function to map the MeShutter to arduino port,
 * and the shot and focus PIN will be set LOW
 * \param[in]
 *   port - RJ25 port from PORT_1 to M2
 */
MeShutter::MeShutter(uint8_t port) : MePort(port)
{
  MePort::dWrite1(LOW);
  MePort::dWrite2(LOW);
}
#else //ME_PORT_DEFINED
/**
 * Alternate Constructor which can call your own function to map the MeShutter to arduino port,
 * it will assigned the shot PIN and focus pin.
 * \param[in]
 *   ShotPin - arduino port for shot PIN(should digital pin)
 * \param[in]
 *   FocusPin - arduino port for focus PIN(should digital pin)
 */
MeShutter::MeShutter(uint8_t ShotPin, uint8_t FocusPin)
{
  _ShotPin = ShotPin;
  _FocusPin = FocusPin;

  //set pinMode OUTPUT
  pinMode(_ShotPin, OUTPUT);
  pinMode(_FocusPin, OUTPUT);
  digitalWrite(_ShotPin, LOW);
  digitalWrite(_FocusPin, LOW);
}
#endif // ME_PORT_DEFINED

/**
 * \par Function
 *   setpin
 * \par Description
 *   Reset the shutter available PIN by its arduino port.
 * \param[in]
 *   ShotPin - arduino port for shot PIN(should digital pin)
 * \param[in]
 *   FocusPin - arduino port for focus PIN(should digital pin)
 * \par Output
 *   None
 * \return
 *   None
 * \par Others
 *   None
 */
void MeShutter::setpin(uint8_t ShotPin, uint8_t FocusPin)
{
  _ShotPin = ShotPin;
  _FocusPin = FocusPin;

  //set pinMode OUTPUT
  pinMode(_ShotPin, OUTPUT);
  pinMode(_FocusPin, OUTPUT);
  digitalWrite(_ShotPin, LOW);
  digitalWrite(_FocusPin, LOW);
#ifdef ME_PORT_DEFINED
  s1 = _ShotPin;
  s2 = _FocusPin;
#endif
}

/**
 * \par Function
 *   shotOn
 * \par Description
 *   Set the shot PIN on
 * \par Output
 *   None
 * \return
 *   None
 * \par Others
 *   None
 */
void MeShutter::shotOn(void)
{
#ifdef ME_PORT_DEFINED
  MePort::dWrite1(HIGH);
#else //ME_PORT_DEFINED
  digitalWrite(_ShotPin, HIGH);
#endif //ME_PORT_DEFINED
}

/**
 * \par Function
 *   shotOff
 * \par Description
 *   Set the shot PIN off
 * \par Output
 *   None
 * \return
 *   None
 * \par Others
 *   None
 */
void MeShutter::shotOff(void)
{
#ifdef ME_PORT_DEFINED
  MePort::dWrite1(LOW);
#else //ME_PORT_DEFINED
  digitalWrite(_ShotPin, LOW);
#endif //ME_PORT_DEFINED
}

/**
 * \par Function
 *   focusOn
 * \par Description
 *   Set the focus PIN on
 * \par Output
 *   None
 * \return
 *   None
 * \par Others
 *   None
 */
void MeShutter::focusOn(void)
{
#ifdef ME_PORT_DEFINED
  MePort::dWrite2(HIGH);
#else //ME_PORT_DEFINED
  digitalWrite(_FocusPin, HIGH);
#endif //ME_PORT_DEFINED
}

/**
 * \par Function
 *   focusOff
 * \par Description
 *   Set the focus PIN off
 * \par Output
 *   None
 * \return
 *   None
 * \par Others
 *   None
 */
void MeShutter::focusOff(void)
{
#ifdef ME_PORT_DEFINED
  MePort::dWrite2(LOW);
#else //ME_PORT_DEFINED
  digitalWrite(_FocusPin, LOW);
#endif //ME_PORT_DEFINED
}

