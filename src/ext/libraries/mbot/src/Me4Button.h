/**
 * \par Copyright (C), 2012-2015, MakeBlock
 * \class   Me4Button
 * \brief   Driver for Me-4 Button module.
 * @file    Me4Button.h
 * @author  MakeBlock
 * @version V1.0.0
 * @date    2015/08/31
 * @brief   Header for Me4Button.cpp module
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
 * This file is the drive for 4 Button module, It supports
 *      Me-4 Button V1.0 module provided by MakeBlock.
 * \par Method List:
 *
 *    1.  void    Me4Button::setpin(uint8_t port);
 *    2.  uint8_t Me4Button::pressed();
 *
 * \par History:
 * <pre>
 * `<Author>`         `<Time>`        `<Version>`        `<Descr>`
 * Mark Yan         2015/07/24     1.0.0            Rebuild the old lib.
 * Rafael Lee       2015/08/31     1.0.0            Added some comments and macros.
 * </pre>
 */

/* Define to prevent recursive inclusion -------------------------------------*/
#ifndef Me4Button_H
#define Me4Button_H

/* Includes ------------------------------------------------------------------*/
#include <stdint.h>
#include <stdbool.h>
#include <arduino.h>
#include "MeConfig.h"

#ifdef ME_PORT_DEFINED
#include "MePort.h"
#endif //  ME_PORT_DEFINED

/* Exported macro ------------------------------------------------------------*/
#define KEY_NULL   (0)
#define KEY_1      (1)
#define KEY_2      (2)
#define KEY_3      (3)
#define KEY_4      (4)

#define KEY_NULL_VALUE   (962)     // 1023*((5-0.3)/5)
#define KEY_1_VALUE      (0)
#define KEY_2_VALUE      (481)     // 962/2
#define KEY_3_VALUE      (641)     // 962*2/3
#define KEY_4_VALUE      (721)     // 962*3/4

#define DEBOUNCED_INTERVAL (8)
// If you want key response faster, you can set DEBOUNCED_INTERVAL to a
// smaller number.

#define FALSE  (0)
#define TRUE   (1)

/**
 * Class: Me4Button
 * \par Description
 * Declaration of Class Me4Button
 */
#ifndef ME_PORT_DEFINED
class Me4Button
#else // !ME_PORT_DEFINED
class Me4Button : public MePort
#endif // !ME_PORT_DEFINED
{
public:
#ifdef ME_PORT_DEFINED
/**
 * Alternate Constructor which can call your own function to map the Me4Button to arduino port,
 * no pins are used or initialized here
 */
  Me4Button(void);
  
/**
 * Alternate Constructor which can call your own function to map the Me4Button to arduino port,
 * no pins are used or initialized here, but PWM frequency set to 976 Hz
 * \param[in]
 *    port - RJ25 port from PORT_1 to M2
 */
  Me4Button(uint8_t port);
#else //  ME_PORT_DEFINED
/**
 * Alternate Constructor which can call your own function to map the _KeyPin to arduino port,
 * no pins are used or initialized here
 * \param[in]
 *    port - arduino gpio number
 */
  Me4Button(uint8_t port);
#endif  //  ME_PORT_DEFINED
/**
 * \par Function
 *    setpin
 * \par Description
 *    Set the PIN of the button module.
 * \param[in]
 *    port - pin mapping for arduino
 * \par Output
 *    None
 * \return
 *    None
 * \par Others
 *    None
 */
  void setpin(uint8_t port);

/**
 * \par Function
 *    pressed
 * \par Description
 *    read key ADC value to a variable.
 * \param[in]
 *    None
 * \par Output
 *    None
 * \return
 *    return the key vlaue
 * \par Others
 *    The key should periodically read, if it was delayed, It will affect the sensitivity of the keys
 */
  uint8_t pressed(void);
private:
  static volatile unsigned long previous_time;
  static volatile unsigned long key_debounced_count;
  static volatile unsigned long key_match_count;
  static volatile unsigned long key_debounced_value;
  static volatile int16_t  Pre_Button_Value;
  static volatile uint8_t  _KeyPin;
};
#endif // Me4Button_H
