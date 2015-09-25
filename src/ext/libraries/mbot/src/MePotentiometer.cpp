/**
 * \par Copyright (C), 2012-2015, MakeBlock
 * \class   MePotentiometer
 * \brief   Driver for Me PIR Motion Sensor module.
 * @file    MePotentiometer.cpp
 * @author  MakeBlock
 * @version V1.0.0
 * @date    2015/09/08
 * @brief   Driver for Me Potentiometer.
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
 *    1. void     MePotentiometer::setpin(uint8_t potentiometerPin); 
 *    2. uint16_t MePotentiometer::read(); 
 *    3. static   MePotentiometer::volatile uint8_t _potentiometerPin;
 *
 * \par History:
 * <pre>
 * `<Author>`         `<Time>`        `<Version>`        `<Descr>`
 * Mark Yan         2015/07/24     1.0.0            Rebuild the old lib.
 * Rafael Lee       2015/09/08     1.0.0            Added some comments and macros.
 * </pre>
 *
 * @example PotentiometerTest.ino
 */

/* Includes ------------------------------------------------------------------*/
#include "MePotentiometer.h"
/* Private typedef -----------------------------------------------------------*/
/* Private define ------------------------------------------------------------*/
/* Private macro -------------------------------------------------------------*/

/* Private variables ---------------------------------------------------------*/
volatile uint8_t MePotentiometer::_potentiometerPin = 0;

/* Private function prototypes -----------------------------------------------*/

/* Private functions ---------------------------------------------------------*/
#ifdef ME_PORT_DEFINED
/**
 * \par Function
 *    read()
 * \par Description
 *    Class MePIRMotionSensor inherit from MePort if ME_PORT_DEFINED defined. \n
 * \param[in]
 *    None
 * \par Output
 *    None
 * \par Return
 *    None
 * \par Others
 *    None
 */
MePotentiometer::MePotentiometer() : MePort(0)
{
}

/**
 * \par Function
 *    read()
 * \par Description
 *    Class MePIRMotionSensor inherit from MePort if ME_PORT_DEFINED defined. \n
 * \param[in]
 *    uint8_t port - Port number.
 * \par Output
 *    None
 * \par Return
 *    None
 * \par Others
 *    None
 */
MePotentiometer::MePotentiometer(uint8_t port) : MePort(port)
{
}

#endif // ME_PORT_DEFINED 

/**
 * \par Function
 *    read()
 * \par Description
 *    Read DAC value of Me Potentiometer module.
 * \param[in]
 *    None
 * \par Output
 *    None
 * \par Return
 *    None
 * \par Others
 *    None
 */
void MePotentiometer::setpin(uint8_t potentiometerPin)
{
  _potentiometerPin = potentiometerPin;
  pinMode(_potentiometerPin, INPUT);
#ifdef ME_PORT_DEFINED
  s2 = potentiometerPin;
#endif // ME_PORT_DEFINED
}
/**
 * \par Function
 *    read()
 * \par Description
 *    Read DAC value of Me Potentiometer module.
 * \param[in]
 *    None
 * \par Output
 *    None
 * \par Return
 *    None
 * \par Others
 *    None
 */
uint16_t MePotentiometer::read(void)
{
  return(MePort::aRead2() );
}

