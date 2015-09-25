/**
 * \par Copyright (C), 2012-2015, MakeBlock
 * \class MeInfraredReceiver
 * \brief   Driver for Me Infrared Receiver device.
 * @file    MeInfraredReceiver.cpp
 * @author  MakeBlock
 * @version V1.0.0
 * @date    2015/09/09
 * @brief   Driver for Me Infrared Receiver device.
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
 * @example InfraredReceiverTest.ino
 */
#include "MeInfraredReceiver.h"

volatile uint8_t MeInfraredReceiver::_RxPin = 0;
volatile uint8_t MeInfraredReceiver::_KeyCheckPin = 0;

#ifdef ME_PORT_DEFINED
/**
 * Alternate Constructor which can call your own function to map the Infrared Receiver to arduino port,
 * no pins are used or initialized here.
 * \param[in]
 *   None
 */
MeInfraredReceiver::MeInfraredReceiver(void) : MeSerial(0)
{
}

/**
 * Alternate Constructor which can call your own function to map the Infrared Receiver to arduino port,
 * If the hardware serial was selected, we will used the hardware serial.
 * \param[in]
 *   port - RJ25 port from PORT_1 to M2
 */
MeInfraredReceiver::MeInfraredReceiver(uint8_t port) : MeSerial(port)
{
  _RxPin = s2;
  _KeyCheckPin = s1;
}
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
MeInfraredReceiver::MeInfraredReceiver(uint8_t receivePin, uint8_t keycheckpin, bool inverse_logic)\
                        : MeSerial(receivePin, transmitPin, inverse_logic)
{
  _RxPin = receivePin;
  _KeyCheckPin = keycheckpin;
}
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
void MeInfraredReceiver::begin(void)
{
  MeSerial::begin(9600);
#ifdef ME_PORT_DEFINED
  pinMode(s1, INPUT);
#else // ME_PORT_DEFINED
  pinMode(_KeyCheckPin, INPUT);
#endif // ME_PORT_DEFINED
}

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
int16_t MeInfraredReceiver::read(void)
{
  int16_t val;
  uint16_t i;
  val = MeSerial::read();     /* Read serial infrared data */
  val &= 0xff;
  return(val);
}

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
bool MeInfraredReceiver::buttonState(void)
{
  bool val;
  if(_hard)
  {
    MeSerial::end();
  }
#ifdef ME_PORT_DEFINED
  val = MePort::dRead1();
#else // ME_PORT_DEFINED
  val =  digitalRead(_KeyCheckPin);
#endif // ME_PORT_DEFINED
  if(_hard)
  {
    begin();
  }
  return(!val);
}

