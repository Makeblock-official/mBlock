/**
 * \par Copyright (C), 2012-2015, MakeBlock
 * \class   MeLimitSwitch
 * \brief   Driver for Me_LimitSwitch module.
 * @file    MeLimitSwitch.cpp
 * @author  MakeBlock
 * @version V1.0.0
 * @date    2015/09/01
 * @brief   Driver for Me LimitSwitch module.
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
 *    1. void MeLimitSwitch::setpin(uint8_t switchPin);
 *    2. bool MeLimitSwitch::touched();
 *
 * \par History:
 * <pre>
 * `<Author>`         `<Time>`        `<Version>`        `<Descr>`
 * Mark Yan         2015/07/24     1.0.0            Rebuild the old lib.
 * Rafael Lee       2015/09/04     1.0.0            Added some comments and macros.
 * </pre>
 *
 * @example LimitSwitchTest.ino \n
 *          MicroSwitchTest.ino \n
 */

/* Includes ------------------------------------------------------------------*/
#include "MeLimitSwitch.h"


/* Private functions ---------------------------------------------------------*/
#ifdef ME_PORT_DEFINED

/**
 * \par Function
 *    MePort
 * \par Description
 *    Class MeLimitSwitch inherit from MePort if ME_PORT_DEFINED defined. \n
 * \param[in]
 *    None
 * \par Output
 *    None
 * \Return
 *    None
 * \par Others
 *    None
 */
MeLimitSwitch::MeLimitSwitch() : MePort(0)
{
}


/**
 * \par Function
 *    MePort
 * \par Description
 *    Class MeLimitSwitch inherit from MePort if ME_PORT_DEFINED defined. \n
 *    Set port and default pin to pin2.
 * \param[in]
 *    uint8_t port - Number of port which module is connected to.
 * \par Output
 *    MeLimitSwitch._device
 *    MeLimitSwitch.pinMode
 * \Return
 *    None
 * \par Others
 *    None
 */
MeLimitSwitch::MeLimitSwitch(uint8_t port) : MePort(port)
{
  _device = SLOT1;
  pinMode(s2, INPUT_PULLUP);
}

/**
 * \par Function
 *    MePort
 * \par Description
 *    Class MeLimitSwitch inherit from MePort if ME_PORT_DEFINED defined. \n
 *    Set port and slot.
 * \param[in]
 *    uint8_t port - Number of port which module is connected to.
 * \param[in]
 *    uint8_t slot - Number of port which module is connected to.
 * \par Output
 *    MeLimitSwitch._device
 *    MeLimitSwitch.pinMode
 * \Return
 *    None
 * \par Others
 *    None
 */
MeLimitSwitch::MeLimitSwitch(uint8_t port, uint8_t slot) : MePort(port)
{
  reset(port, slot);
  if (getSlot() == SLOT1)
  {
    pinMode(s1, INPUT_PULLUP);
  }
  else
  {
    pinMode(s2, INPUT_PULLUP);
  }
}

#endif // ME_PORT_DEFINED

/**
 * \par Function
 *    setpin
 * \par Description
 *
 * \param[in]
 *    uint8_t dataPin - The DATA pin for Seven-Segment LED module.
 * \param[in]
 *    uint8_t clkPin - The CLK pin for Seven-Segment LED module.
 * \par Output
 *    None
 * \par Return
 *    None
 * \par Others
 *    None
 */
void MeLimitSwitch::setpin(uint8_t switchPin)
{
  _switchPin = switchPin;
  pinMode(_switchPin, INPUT_PULLUP);
#ifdef ME_PORT_DEFINED
  if (getSlot() == SLOT1)
  {
    s1 = switchPin;
  }
  else
  {
    s2 = switchPin;
  }
#endif // ME_PORT_DEFINED
}

/**
 * \par Function
 *    touched
 * \par Description
 *    Get switch value from selected _slot defined by MePort.
 * \param[in]
 *    None
 * \par Output
 *    None
 * \Return
 *    True if module is touched.
 * \par Others
 *    None
 */
bool MeLimitSwitch::touched()
{
  return(!(getSlot() == SLOT1 ? digitalRead(s1) : digitalRead(s2)));
}

