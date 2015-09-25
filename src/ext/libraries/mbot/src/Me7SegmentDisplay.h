/**
 * \par Copyright (C), 2012-2015, MakeBlock
 * \class   Me7SegmentDisplay
 * \brief   Driver for Me 7-Segment Serial Display module.
 * @file    Me7SegmentDisplay.h
 * @author  MakeBlock
 * @version V1.0.0
 * @date    2015/09/01
 * @brief   Header file for Me7SegmentDisplay.cpp.
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
 * Driver for Me 7-Segment Serial Display module.
 * \par Method List:
 *
 *    1.    void    Me7SegmentDisplay::init(void);
 *    2.    void    Me7SegmentDisplay::set(uint8_t = BRIGHTNESS_2, uint8_t = 0x40, uint8_t = 0xc0);
 *    3.    void    Me7SegmentDisplay::reset(MePort port);
 *    4.    void    Me7SegmentDisplay::setpin(uint8_t dataPin, uint8_t clkPin);
 *    5.    void    Me7SegmentDisplay::write(uint8_t SegData[]);
 *    6.    void    Me7SegmentDisplay::write(uint8_t BitAddr, uint8_t SegData);
 *    7.    void    Me7SegmentDisplay::display(uint16_t value);
 *    8.    void    Me7SegmentDisplay::display(int16_t value);
 *    9.    void    Me7SegmentDisplay::display(double value, uint8_t = 1);
 *    10.   void    Me7SegmentDisplay::display(uint8_t DispData[]);
 *    11.   void    Me7SegmentDisplay::display(uint8_t DispData, uint8_t BitAddr);
 *    12.   void    Me7SegmentDisplay::clearDisplay(void);
 *    13.   void    Me7SegmentDisplay::setBrightness(uint8_t brightness);
 *    14.   void    Me7SegmentDisplay::coding(uint8_t DispData[]);
 *    15.   uint8_t Me7SegmentDisplay::coding(uint8_t DispData);
 *
 * \par History:
 * <pre>
 * `<Author>`         `<Time>`        `<Version>`        `<Descr>`
 * Mark Yan         2015/07/24     1.0.0            Rebuild the old lib.
 * Rafael Lee       2015/09/02     1.0.0            Added some comments and macros.
 * </pre>
 */

/* Define to prevent recursive inclusion -------------------------------------*/
#ifndef Me7SegmentDisplay_H
#define Me7SegmentDisplay_H

//************definitions for TM1637*********************
#include <stdint.h>
#include <stdbool.h>
#include <arduino.h>
#include "MeConfig.h"

#ifdef ME_PORT_DEFINED
#include "MePort.h"
#endif // ME_PORT_DEFINED

/* Exported constants --------------------------------------------------------*/
/******************definitions for TM1637**********************/
const uint8_t   ADDR_AUTO = 0x40;   //Automatic address increment mode
const uint8_t   ADDR_FIXED = 0x44;   //Fixed address mode
const uint8_t   STARTADDR = 0xc0;   //start address of display register
const uint8_t   SEGDIS_ON = 0x88;   //diplay on
const uint8_t   SEGDIS_OFF = 0x80;   //diplay off
/**** definitions for the clock point of the digit tube *******/
const uint8_t POINT_ON = 1;
const uint8_t POINT_OFF = 0;
/**************definitions for brightness***********************/
const uint8_t BRIGHTNESS_0 = 0;
const uint8_t BRIGHTNESS_1 = 1;
const uint8_t BRIGHTNESS_2 = 2;
const uint8_t BRIGHTNESS_3 = 3;
const uint8_t BRIGHTNESS_4 = 4;
const uint8_t BRIGHTNESS_5 = 5;
const uint8_t BRIGHTNESS_6 = 6;
const uint8_t BRIGHTNESS_7 = 7;
///@brief Class for numeric display module

/**
 * Class: Me7SegmentDisplay
 * \par Description
 *    Declaration of Class Me7SegmentDisplay.
 */
#ifndef ME_PORT_DEFINED
class Me7SegmentDisplay
#else // ME_PORT_DEFINED
class Me7SegmentDisplay :public MePort
#endif // ME_PORT_DEFINED
{
public:
#ifdef ME_PORT_DEFINED
  Me7SegmentDisplay();
  Me7SegmentDisplay(uint8_t port);
#else // ME_PORT_DEFINED
  Me7SegmentDisplay(uint8_t dataPin, uint8_t clkPin);
#endif // ME_PORT_DEFINED
  void init(void); // Clear display
  void set(uint8_t = BRIGHTNESS_2, uint8_t = 0x40, uint8_t = 0xc0);// Take effect next display cycle.
#ifdef ME_PORT_DEFINED
  void reset(uint8_t port);
#endif // ME_PORT_DEFINED
  void setpin(uint8_t dataPin, uint8_t clkPin);
  void write(uint8_t SegData[]);
  void write(uint8_t BitAddr, uint8_t SegData);
  void display(uint16_t value);
  void display(int16_t value);
  void display(double value, uint8_t = 1);
  void display(uint8_t DispData[]);
  void display(uint8_t DispData, uint8_t BitAddr);
  void clearDisplay(void);
  void setBrightness(uint8_t brightness);
  void coding(uint8_t DispData[]);
  uint8_t coding(uint8_t DispData);
private:
  uint8_t Cmd_SetData;
  uint8_t Cmd_SetAddr;
  uint8_t Cmd_DispCtrl;
  bool _PointFlag; //_PointFlag=1:the clock point on
  void writeByte(uint8_t wr_data);// Write 8 bits data to tm1637.
  void start(void);// Send start bits
  void point(bool PointFlag);// Whether to light the clock point ":". Take effect next display cycle.
  void stop(void); // Send stop bits.
  uint8_t _clkPin;
  uint8_t _dataPin;
};
#endif
