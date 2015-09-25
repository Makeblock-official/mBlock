/**
 * \par Copyright (C), 2012-2015, MakeBlock
 * \class   MeLimitSwitch
 * \brief   Driver for Me_LimitSwitch module.
 * @file    MeLimitSwitch.h
 * @author  MakeBlock
 * @version V1.0.0
 * @date    2015/09/04
 * @brief   Header for MeLimitSwitch.cpp.
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
 */

/* Define to prevent recursive inclusion -------------------------------------*/
#ifndef MeLimitSwitch_H
#define MeLimitSwitch_H

/* Includes ------------------------------------------------------------------*/
#include <stdint.h>
#include <stdbool.h>
#include <arduino.h>
#include "MeConfig.h"

#ifdef ME_PORT_DEFINED
#include "MePort.h"
#endif // ME_PORT_DEFINED

/* Exported classes ----------------------------------------------------------*/
#ifndef ME_PORT_DEFINED
class MeLimitSwitch
#else // !ME_PORT_DEFINED

/**
 * Class: MeLimitSwitch
 * \par Description
 *    Declaration of Class MeLimitSwitch.
 */

class MeLimitSwitch : public MePort
#endif  // !ME_PORT_DEFINED
{
public:
#ifdef ME_PORT_DEFINED
  MeLimitSwitch();
  MeLimitSwitch(uint8_t port);
  MeLimitSwitch(uint8_t port, uint8_t slot);
#endif  // ME_PORT_DEFINED
  void setpin(uint8_t switchPin);
  bool touched();

private:
  uint8_t _device;
  uint8_t _switchPin;
};
#endif
