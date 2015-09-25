/**
 * \par Copyright (C), 2012-2015, MakeBlock
 * \class MeInfraredReceiver
 * \brief   Driver for Me Infrared Receiver device.
 * @file    MeInfraredReceiver.h
 * @author  MakeBlock
 * @version V1.0.0
 * @date    2015/09/09
 * @brief   Header for for MeInfraredReceiver.cpp module
 * \par Description
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
 * Description: this file is a drive for Me Infrared Receiver, It supports
   Infrared Receiver V2.0 and V3.0 device provided by the MakeBlock company.
 *
 * \par Method List:
 *
 *    1. void MeInfraredReceiver::begin(void)
 *    2. int16_t MeInfraredReceiver::read(void)
 *    3. bool MeInfraredReceiver::buttonState(void)
 *
 * \par History:
 * <pre>
 * `<Author>`         `<Time>`        `<Version>`        `<Descr>`
 * Mark Yan         2015/09/09     1.0.0            Rebuild the old lib.
 * </pre>
 *
 */

#ifndef MeInfraredReceiver_H
#define MeInfraredReceiver_H

#include <stdint.h>
#include <stdbool.h>
#include <arduino.h>
#include "MeConfig.h"
#include "MeSerial.h"

/* NEC Code table */
#define IR_BUTTON_POWER     (0x45)
#define IR_BUTTON_A         (0x45)
#define IR_BUTTON_B         (0x46)
#define IR_BUTTON_MENU      (0x47)
#define IR_BUTTON_C         (0x47)
#define IR_BUTTON_TEST      (0x44)
#define IR_BUTTON_D         (0x44)
#define IR_BUTTON_PLUS      (0x40)
#define IR_BUTTON_UP        (0x40)
#define IR_BUTTON_RETURN    (0x43)
#define IR_BUTTON_E         (0x43)
#define IR_BUTTON_PREVIOUS  (0x07)
#define IR_BUTTON_LEFT      (0x07)
#define IR_BUTTON_PLAY      (0x15)
#define IR_BUTTON_SETTING   (0x15)
#define IR_BUTTON_NEXT      (0x09)
#define IR_BUTTON_RIGHT     (0x09)
#define IR_BUTTON_MINUS     (0x19)
#define IR_BUTTON_DOWN      (0x19)
#define IR_BUTTON_CLR       (0x0D)
#define IR_BUTTON_F     (0x0D)
#define IR_BUTTON_0     (0x16)
#define IR_BUTTON_1     (0x0C)
#define IR_BUTTON_2     (0x18)
#define IR_BUTTON_3     (0x5E)
#define IR_BUTTON_4     (0x08)
#define IR_BUTTON_5     (0x1C)
#define IR_BUTTON_6     (0x5A)
#define IR_BUTTON_7     (0x42)
#define IR_BUTTON_8     (0x52)
#define IR_BUTTON_9     (0x4A)

#ifdef ME_PORT_DEFINED
#include "MePort.h"
#endif /* ME_PORT_DEFINED */

/**
 * CLASS:  MeUltrasonicSensor
 * TODO: DESCRIPTION
 */
#ifndef ME_PORT_DEFINED
class MeInfraredReceiver
#else // !ME_PORT_DEFINED
class MeInfraredReceiver : public MeSerial
#endif // !ME_PORT_DEFINED
{
public:
#ifdef ME_PORT_DEFINED
/**
 * Alternate Constructor which can call your own function to map the Infrared Receiver to arduino port,
 * no pins are used or initialized here.
 * \param[in]
 *   None
 */
  MeInfraredReceiver();

/**
 * Alternate Constructor which can call your own function to map the Infrared Receiver to arduino port,
 * If the hardware serial was selected, we will used the hardware serial.
 * \param[in]
 *   port - RJ25 port from PORT_1 to M2
 */
  MeInfraredReceiver(uint8_t port);
#else // ME_PORT_DEFINED
/**
 * Alternate Constructor which can call your own function to map the Infrared Receiver to arduino port,
 * If the hardware serial was selected, we will used the hardware serial.
 * \param[in]
 *   receivePin - the rx pin of serial(arduino port)
 * \param[in]
 *   keycheckpin - the pin used for check the pin pressed state(arduino port)
 * \param[in]
 *   inverse_logic - Whether the Serial level need inv.
 */
  MeInfraredReceiver(uint8_t receivePin, uint8_t transmitPin, bool inverse_logic);
#endif // ME_PORT_DEFINED
/**
 * \par Function
 *   begin
 * \par Description
 *   Sets the speed (baud rate) for the serial communication. Supported baud 
 *   rates is 9600bps
 * \par Output
 *   None
 * \return
 *   None
 * \par Others
 *   None
 */
  void begin(void);

/**
 * \par Function
 *   read
 * \par Description
 *   Return a character that was received on the RX pin of the software serial port. 
 *   Note that only one SoftwareSerial instance can receive incoming data at a time 
 *  (select which one with the listen() function).
 * \par Output
 *   None
 * \return
 *   The character read, or -1 if none is available
 * \par Others
 *   None
 */
  int16_t read(void);

/**
 * \par Function
 *   buttonState
 * \par Description
 *   Check button press state
 * \par Output
 *   None
 * \return
 *   true: The button is pressed, false: No button is pressed
 * \par Others
 *   None
 */
  bool buttonState(void);

private:
  static volatile uint8_t _RxPin;
  static volatile uint8_t _KeyCheckPin; 
};

#endif

