/**
 * \par Copyright (C), 2012-2015, MakeBlock
 * \class MeShutter
 * \brief   Driver for Me Shutter device.
 * @file    MeShutter.h
 * @author  MakeBlock
 * @version V1.0.0
 * @date    2015/09/04
 * @brief   Header for MeShutter.cpp module
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
 */
#ifndef MeShutter_H
#define MeShutter_H
#include <stdint.h>
#include <stdbool.h>
#include <arduino.h>
#include "MeConfig.h"
#ifdef ME_PORT_DEFINED
#include "MePort.h"
#endif  /* ME_PORT_DEFINED */

/**
 * Class: MeShutter
 * \par Description
 * Declaration of Class MeShutter.
 */
#ifndef ME_PORT_DEFINED
class MeShutter
#else // !ME_PORT_DEFINED
class MeShutter : public MePort
#endif // !ME_PORT_DEFINED
{
public:
#ifdef ME_PORT_DEFINED
/**
 * Alternate Constructor which can call your own function to map the MeShutter to arduino port,
 * no pins are used or initialized here.
 * \param[in]
 *   None
 */
  MeShutter(void);

/**
 * Alternate Constructor which can call your own function to map the MeShutter to arduino port,
 * and the shot and focus PIN will be set LOW
 * \param[in]
 *   port - RJ25 port from PORT_1 to M2
 */
  MeShutter(uint8_t port);
#else // ME_PORT_DEFINED
/**
 * Alternate Constructor which can call your own function to map the MeShutter to arduino port,
 * it will assigned the shot PIN and focus pin.
 * \param[in]
 *   ShotPin - arduino port for shot PIN(should digital pin)
 * \param[in]
 *   FocusPin - arduino port for focus PIN(should digital pin)
 */
  MeShutter(uint8_t ShotPin, uint8_t FocusPin);
#endif  // ME_PORT_DEFINED

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
  void setpin(uint8_t ShotPin, uint8_t FocusPin);

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
  void shotOn(void);

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
  void shotOff(void);

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
  void focusOn(void);

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
  void focusOff(void);
private:
  static volatile uint8_t  _ShotPin;
  static volatile uint8_t  _FocusPin;
};
#endif

