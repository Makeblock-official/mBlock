/**
 * \mainpage Makeblock library for Arduino
 *
 * \par Description
 *
 * This is the library provided by makeblock. \n
 * It provides drivers for all makeblock RJ25 jack interface modules. \n
 *
 * The latest version of this documentation can be downloaded from \n
 * http://learn.makeblock.cc/
 *
 * Package can be download from http://learn.makeblock.cc/
 *
 * \par Installation
 *
 * Install the package in the normal way: unzip the distribution zip file to the libraries \n
 * sub-folder of your sketchbook or Arduino, \n
 * copy files in makeblock/src folder to arduino/libraries/Makeblock/
 *
 * \par Donations
 *
 * This library is offered under GPLv2 license for those who want to use it that way. \n
 * Additional information can be found at http://www.gnu.org/licenses/old-licenses/gpl-2.0.html \n
 * We are tring hard to keep it up to date, fix bugs free and to provide free support on our site. \n
 *
 * \par Copyright
 *
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
 * \par History:
 * <pre>
 * Author           Time           Version          Descr
 * Mark Yan         2015/07/24     1.0.0            Rebuild the old lib.
 * Rafael Lee       2015/09/02     1.0.0            Added some comments and macros.
 * Lawrence         2015/09/09     1.0.0            Include some Arduino's official headfiles which path specified.
 * </pre>
 *
 * \author  Mark Yan (myan@makeblock.com) DO NOT CONTACT THE AUTHOR DIRECTLY: USE THE LISTS
 */


/**
 * \par Copyright (C), 2012-2015, MakeBlock
 * \brief   Configuration file of library.
 * \file    Meconfig.h
 * @author  MakeBlock
 * @version V1.0.0
 * @date    2015/09/01
 * @brief   Configuration file of library.
 * \par Copyright
 *
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
 * Define macro ME_PORT_DEFINED. \n
 * Define other macros if `__AVR__` defined.
 *
 * \par History:
 * <pre>
 * `<Author>`         `<Time>`        `<Version>`        `<Descr>`
 * Mark Yan         2015/07/24         1.0.0            Rebuild the old lib.
 * Rafael Lee       2015/09/02         1.0.0            Added some comments and macros. Fixed some bug and add some methods.
 * Lawrence         2015/09/09         1.0.0            Include some Arduino's official headfiles which path specified.
 * </pre>
 */


#ifndef MeConfig_H
#define MeConfig_H

#include <..\..\servo\src\servo.h>
#include <..\..\..\hardware\arduino\avr\libraries\Wire\Wire.h>
#include <..\..\..\hardware\arduino\avr\libraries\EEPROM\EEPROM.h>
#include <..\..\..\hardware\arduino\avr\libraries\SoftwareSerial\SoftwareSerial.h>


#define ME_PORT_DEFINED

#if defined(__AVR__)
#define MePIN_TO_BASEREG(pin)               ( portInputRegister (digitalPinToPort (pin) ) )
#define MePIN_TO_BITMASK(pin)               ( digitalPinToBitMask (pin) )
#define MeIO_REG_TYPE                       uint8_t
#define MeIO_REG_ASM                        asm ("r30")
#define MeDIRECT_READ(base, mask)           ( ( (*(base) ) & (mask) ) ? 1 : 0)
#define MeDIRECT_MODE_INPUT(base, mask)     ( (*( (base) + 1) ) &= ~(mask) ), ( (*( (base) + 2) ) |= (mask) ) // INPUT_PULLUP
#define MeDIRECT_MODE_OUTPUT(base, mask)    ( (*( (base) + 1) ) |= (mask) )
#define MeDIRECT_WRITE_LOW(base, mask)      ( (*( (base) + 2) ) &= ~(mask) )
#define MeDIRECT_WRITE_HIGH(base, mask)     ( (*( (base) + 2) ) |= (mask) )
#endif // __AVR__

#endif // MeConfig_H

