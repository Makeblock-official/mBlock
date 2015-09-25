/**
 * \par Copyright (C), 2012-2015, MakeBlock
 * \class MeSerial
 * \brief   Driver for serial.
 * @file    MeSerial.cpp
 * @author  MakeBlock
 * @version V1.0.0
 * @date    2015/09/08
 * @brief   this file is a drive for serial
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
 * This file is a drive for serial, It support hardware and software serial
 *
 * \par Method List:
 *
 *    1. void MeSerial::setHardware(bool mode)
 *    2. void MeSerial::begin(long baudrate)
 *    3. void MeSerial::end(void)
 *    4. size_t MeSerial::write(uint8_t byte)
 *    5. int16_t MeSerial::read(void)
 *    6. int16_t MeSerial::available(void)
 *    7. bool MeSerial::listen(void)
 *    8. bool MeSerial::isListening(void)
 *    9. int16_t MeSerial::poll(void)
 *
 * \par History:
 * <pre>
 * `<Author>`         `<Time>`        `<Version>`        `<Descr>`
 * Mark Yan         2015/09/08     1.0.0            Rebuild the old lib.
 * </pre>
 * @example MeSerialReceiveTest.ino
 * @example MeSerialTransmitTest.ino
 */
#include "MeSerial.h"
#include <stdio.h>
#include <stdarg.h>

volatile uint8_t MeSerial::_RxPin = 0;
volatile uint8_t MeSerial::_TxPin = 0;

#ifdef ME_PORT_DEFINED
/**
 * Alternate Constructor which can call your own function to map the serial to arduino port,
 * no pins are used or initialized here. hardware serial will be used by default.
 * \param[in]
 *   None
 */
MeSerial::MeSerial(void) : MePort(), SoftwareSerial(NC, NC)
{
  _hard = true;
  _scratch = true;
  _polling = false;
}

/**
 * Alternate Constructor which can call your own function to map the serial to arduino port,
 * If the hardware serial was selected, we will used the hardware serial.
 * \param[in]
 *   port - RJ25 port from PORT_1 to M2
 */
MeSerial::MeSerial(uint8_t port) : MePort(port), SoftwareSerial(mePort[port].s2, mePort[port].s1)
{
  _scratch = false;
  _hard = false;
  _polling = false;
  _RxPin = s2;
  _TxPin = s1;
#if defined(__AVR_ATmega32U4__)
  //_polling = getPort() > PORT_5;
   _polling = false;
  _hard = getPort() == PORT_4;
#else
  _hard = getPort() == PORT_5;
#endif
}
#else // ME_PORT_DEFINED
/**
 * Alternate Constructor which can call your own function to map the serial to arduino port,
 * If the hardware serial was selected, we will used the hardware serial.
 * \param[in]
 *   receivePin - the rx pin of serial(arduino port)
 * \param[in]
 *   transmitPin - the tx pin of serial(arduino port)
 * \param[in]
 *   inverse_logic - Whether the Serial level need inv.
 */
MeSerial::MeSerial(uint8_t receivePin, uint8_t transmitPin, bool inverse_logic)\
                   : SoftwareSerial(receivePin, transmitPin, inverse_logic)
{
  _scratch = false;
  _hard = false;
  _polling = false;
  _RxPin = receivePin;
  _TxPin = transmitPin;
#if defined(__AVR_ATmega32U4__)
   _polling = false;
  if((receivePin == 0) && (transmitPin == 1))
  {
    _hard = true;
  }
  else
  {
    _hard = false;
  }
#else
  if((receivePin == 0) && (transmitPin == 1))
  {
    _hard = true;
  }
  else
  {
    _hard = false;
  }
#endif
}
#endif // ME_PORT_DEFINED

/**
 * \par Function
 *   setHardware
 * \par Description
 *   if need change the hardware and software serial, this function can be used.
 * \param[in]
 *   mode - if need use hardware serial this value should set to true, or set it false.
 * \par Output
 *   None
 * \return
 *   None
 * \par Others
 *   None
 */
void MeSerial::setHardware(bool mode)
{
  _hard = mode;
}

/**
 * \par Function
 *   begin
 * \par Description
 *   Sets the speed (baud rate) for the serial communication. Supported baud 
 *   rates are 300, 600, 1200, 2400, 4800, 9600, 14400, 19200, 28800, 31250, 
 *   38400, 57600, and 115200.
 * \param[in]
 *   baudrate - he baud rate (long)
 * \par Output
 *   None
 * \return
 *   None
 * \par Others
 *   None
 */
void MeSerial::begin(long baudrate)
{
  _bitPeriod = 1000000 / baudrate;
  if (_hard)
  {
#if defined(__AVR_ATmega32U4__)
    _scratch ? Serial.begin(baudrate) : Serial1.begin(baudrate);
#else
    Serial.begin(baudrate);
#endif
  }
  else
  {
    SoftwareSerial::begin(baudrate);
  }
}

/**
 * \par Function
 *   end
 * \par Description
 *   Stop listening and release the object
 * \par Output
 *   None
 * \return
 *   None
 * \par Others
 *   None
 */
void MeSerial::end(void)
{
  if (_hard)
  {
#if defined(__AVR_ATmega32U4__)
    Serial1.end();
#else
    Serial.end();
#endif
  }
  else
  {
    SoftwareSerial::end();
  }
}

/**
 * \par Function
 *   write
 * \par Description
 *   Writes binary data to the serial port. This data is sent as a byte or series of bytes; 
 * \param[in]
 *   byte - a value to send as a single byte
 * \par Output
 *   None
 * \return
 *   it will return the number of bytes written, though reading that number is optional
 * \par Others
 *   None
 */
size_t MeSerial::write(uint8_t byte)
{
  if (_hard)
  {
#if defined(__AVR_ATmega32U4__)
    return (_scratch ? Serial.write(byte) : Serial1.write(byte) );
#else
    return (Serial.write(byte) );
#endif
  }
  else
  {
    return (SoftwareSerial::write(byte) );
  }
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
int16_t MeSerial::read(void)
{
  if (_polling)
  {
    int16_t temp = _byte;
    _byte = -1;
    return (temp > -1 ? temp : poll() );
  }
  if (_hard)
  {
#if defined(__AVR_ATmega32U4__)
    return (_scratch ? Serial.read() : Serial1.read() );
#else
    return (Serial.read() );
#endif
  }
  else
  {
    return (SoftwareSerial::read() );
  }
}

/**
 * \par Function
 *   available
 * \par Description
 *   Get the number of bytes (characters) available for reading from a software
 *   serial port. This is data that's already arrived and stored in the serial 
 *   receive buffer.
 * \par Output
 *   None
 * \return
 *   The number of bytes available to read
 * \par Others
 *   None
 */
int16_t MeSerial::available(void)
{
  if (_polling)
  {
    _byte = poll();
    return (_byte > -1 ? 1 : 0);
  }
  if (_hard)
  {
#if defined(__AVR_ATmega32U4__)
    return (_scratch ? Serial.available() : Serial1.available() );
#else
    return (Serial.available() );
#endif
  }
  else
  {
    return (SoftwareSerial::available() );
  }
}

/**
 * \par Function
 *   listen
 * \par Description
 *   Enables the selected software serial port to listen, used for software serial.
 *   Only one software serial port can listen at a time; data that arrives for other 
 *   ports will be discarded. Any data already received is discarded during the call 
 *   to listen() (unless the given instance is already listening).
 * \par Output
 *   None
 * \return
 *   This function sets the current object as the "listening"
 *   one and returns true if it replaces another
 * \par Others
 *   None
 */
bool MeSerial::listen(void)
{
  if (_hard)
  {
    return (true);
  }
  else
  {
    return (SoftwareSerial::listen() );
  }
}

/**
 * \par Function
 *   isListening
 * \par Description
 *   Tests to see if requested software serial port is actively listening.
 * \par Output
 *   None
 * \return
 *   Returns true if we were actually listening.
 * \par Others
 *   None
 */
bool MeSerial::isListening(void)
{
  if (_hard)
  {
    return (true);
  }
  else
  {
    return (SoftwareSerial::isListening() );
  }
}

/**
 * \par Function
 *   poll
 * \par Description
 *   If we used the serial as software serial port, and set the _polling mask true.
 *   we beed use this function to read the serial data.
 * \par Output
 *   None
 * \return
 *   The character read, or -1 if none is available
 * \par Others
 *   None
 */
int16_t MeSerial::poll(void)
{
  int16_t val = 0;
  int16_t bitDelay = _bitPeriod - clockCyclesToMicroseconds(50);
  if (digitalRead(_RxPin) == LOW)
  {
    for (int16_t offset = 0; offset < 8; offset++)
    {
      delayMicroseconds(bitDelay);
      val |= digitalRead(_RxPin) << offset;
    }
    delayMicroseconds(bitDelay);
    return (val & 0xff);
  }
  return (-1);
}

/**
 * \par Function
 *   sendString
 * \par Description
 *   Send a string as a series of bytes, used for printf().
 * \param[in]
 *   str - A string to send as a series of bytes
 * \par Output
 *   None
 * \return
 *   None
 * \par Others
 *   None
 */
void MeSerial::sendString(char *str)
{
  while(*str)
  {
    write(*str++);
  }
}

/**
 * \par Function
 *   printf
 * \par Description
 *   Printf format string (of which "printf" stands for "print formatted") 
 *   refers to a control parameter used by a class of functions in the 
 *   string-processing libraries of various programming languages.
 * \param[in]
 *   fmt - A string that specifies the format of the output. The formatting 
 *   string determines what additional arguments you need to provide.
 * \par Output
 *   None
 * \return
 *   None
 * \par Others
 *   None
 */
void MeSerial::printf(char *fmt,...)
{
    va_list ap;
    char string[128];
    va_start(ap,fmt);
    vsprintf(string,fmt,ap);
    sendString(string);
    va_end(ap);
}

