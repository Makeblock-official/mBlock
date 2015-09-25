/**
 * \par Copyright (C), 2012-2015, MakeBlock
 * \class MeTemperature
 * \brief   Driver for temperature sensor device.
 * @file    MeTemperature.h
 * @author  MakeBlock
 * @version V1.0.0
 * @date    2015/09/08
 * @brief   Header for MeTemperature.cpp module
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
 * This file is a drive for temperature sensor device, It supports temperature sensor
 * 18B20 provided by the MakeBlock.
 *
 * \par Method List:
 *
 *    1. void MeTemperature::reset(uint8_t port)
 *    2. void MeTemperature::reset(uint8_t port, uint8_t slot)
 *    3. void MeTemperature::setpin(uint8_t port)
 *    4. float MeTemperature::temperature(void)
 *
 * \par History:
 * <pre>
 * `<Author>`         `<Time>`        `<Version>`        `<Descr>`
 * Mark Yan         2015/09/08     1.0.0            Rebuild the old lib.
 * </pre>
 */
#ifndef MeTemperature_H
#define MeTemperature_H

#include <stdint.h>
#include <stdbool.h>
#include <arduino.h>
#include "MeConfig.h"
#include "MeOneWire.h"

#ifdef ME_PORT_DEFINED
#include "MePort.h"
#endif /* ME_PORT_DEFINED */

/* DS18B20 commands */
#define STARTCONVO       0x44    // Tells device to take a temperature reading and put it on the scratchpad
#define COPYSCRATCH      0x48    // Copy EEPROM
#define READSCRATCH      0xBE    // Read EEPROM
#define WRITESCRATCH     0x4E    // Write to EEPROM
#define RECALLSCRATCH    0xB8    // Reload from last known
#define READPOWERSUPPLY  0xB4    // Determine if device needs parasite power
#define ALARMSEARCH      0xEC    // Query bus for devices with an alarm condition

/**
 * Class: MeTemperature
 * \par Description
 * Declaration of Class MeTemperature.
 */
#ifndef ME_PORT_DEFINED
class MeTemperature
#else // !ME_PORT_DEFINED
class MeTemperature : public MePort
#endif // !ME_PORT_DEFINED
{
public:
#ifdef ME_PORT_DEFINED
/**
 * Alternate Constructor which can call your own function to map the temperature sensor to arduino port,
 * no pins are used or initialized here.
 * \param[in]
 *   None
 */
  MeTemperature(void);
  
/**
 * Alternate Constructor which can call your own function to map the temperature sensor to arduino port,
 * the slot2 pin will be used here since specify slot is not be set.
 * \param[in]
 *   port - RJ25 port from PORT_1 to M2
 */
  MeTemperature(uint8_t port);

/**
 * Alternate Constructor which can call your own function to map the temperature sensor to arduino port.
 * \param[in]
 *   port - RJ25 port from PORT_1 to M2
 * \param[in]
 *   slot - SLOT1 or SLOT2
 */
  MeTemperature(uint8_t port, uint8_t slot);
#else // ME_PORT_DEFINED
/**
 * Alternate Constructor which can call your own function to map the temperature sensor to arduino port.
 * \param[in]
 *   port - arduino port
 */
  MeTemperature(uint8_t port);
#endif // ME_PORT_DEFINED
/**
 * \par Function
 *   reset
 * \par Description
 *   Reset the available PIN for temperature sensor by its RJ25 port,
 *   the slot2 pin will be used here since specify slot is not be set
 * \param[in]
 *   port - RJ25 port from PORT_1 to M2
 * \par Output
 *   None
 * \return
 *   None
 * \par Others
 *   None
 */
  void reset(uint8_t port);

/**
 * \par Function
 *   reset
 * \par Description
 *   Reset the available PIN for temperature sensor by its RJ25 port.
 * \param[in]
 *   port - RJ25 port from PORT_1 to M2
 * \param[in]
 *   slot - SLOT1 or SLOT2
 * \par Output
 *   None
 * \return
 *   None
 * \par Others
 *   None
 */
  void reset(uint8_t port, uint8_t slot);

/**
 * \par Function
 *   setpin
 * \par Description
 *   Reset available PIN for temperature sensor by its arduino port.
 * \param[in]
 *   port - arduino port(should digital pin)
 * \par Output
 *   None
 * \return
 *   None
 * \par Others
 *   None
 */
  void setpin(uint8_t port);

/**
 * \par Function
 *   temperature
 * \par Description
 *   Get the celsius of temperature
 * \par Output
 *   None
 * \return
 *   The temperature value get from the sensor.
 * \par Others
 *   None
 */
  float temperature(void);
private:
	MeOneWire _ts;
    static volatile uint8_t  _DataPin;
};

#endif

