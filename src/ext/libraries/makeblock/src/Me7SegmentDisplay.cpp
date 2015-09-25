/**
 * \par Copyright (C), 2012-2015, MakeBlock
 * \class   Me7SegmentDisplay
 * \brief   Driver for Me 7-Segment Serial Display module.
 * @file    Me7SegmentDisplay.cpp
 * @author  MakeBlock
 * @version V1.0.0
 * @date    2015/09/01
 * @brief   Driver for Me 7 Segment Serial Display module.
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
 * Driver for Me 7 Segment Serial Display module.
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
 * Rafael Lee       2015/09/02     1.0.0            Added some comments and macros. Some bug fixed in coding function.
 * </pre>
 *
 * @example NumberDisplay.ino
 * @example NumberFlow.ino
 * @example TimeDisplay.ino
 */

/* Includes ------------------------------------------------------------------*/
#include "Me7SegmentDisplay.h"

/* Private variables ---------------------------------------------------------*/
static uint8_t TubeTab[] = 
{
  0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x6f, //0-9
  0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71,                         //'A', 'B', 'C', 'D', 'E', 'F',
  0xbf, 0x86, 0xdb, 0xcf, 0xe6, 0xed, 0xfd, 0x87, 0xff, 0xef, //0.-9.
  0xf7, 0xfc, 0xb9, 0xde, 0xf9, 0xf1,                         //'A.', 'B.', 'C.', 'D.', 'E.', 'F.',
  0, 0x40                                                     //' ','-'
};

#ifdef ME_PORT_DEFINED

/* Private functions ---------------------------------------------------------*/
/**
 * \par Function
 *    Me7SegmentDisplay
 * \par Description
 *    Constructor for 7 Segment Display and clear display.
 * \param[in]
 *    None
 * \par Output
 *    None
 * \par Return
 *    None
 * \par Others
 *    Set global variable _KeyPin and s2
 */
Me7SegmentDisplay::Me7SegmentDisplay() : MePort()
{
}

/**
 * \par Function
 *    Me7SegmentDisplay
 * \par Description
 *    Constructor for 7 Segment Display and clear display.
 * \param[in]
 *    uint8_t port - Port number.
 * \par Output
 *    uint8_t Cmd_SetData - Private variable Cmd_SetData of class Me7SegmentDisplay.
 *    uint8_t Cmd_SetAddr - Private variable Cmd_SetAddr of class Me7SegmentDisplay.
 *    uint8_t Cmd_DispCtrl - Control command for Me 7 Segment Serial Display module.
 * \par Return
 *    None
 * \par Others
 *    Set global variable _KeyPin and s2
 */
Me7SegmentDisplay::Me7SegmentDisplay(uint8_t port) : MePort(port)
{
  _dataPin = s1;
  _clkPin = s2;
  pinMode(_clkPin, OUTPUT);
  pinMode(_dataPin, OUTPUT);
  set();
  clearDisplay();
}
#else // ME_PORT_DEFINED

/**
 * \par Function    Me7SegmentDisplay
 * \par Description
 *    Constructor for 7 segment display, set I2C data pin, clock pin and clear display.
 * \param[in]
 *    uint8_t dataPin - The DATA pin for Seven-Segment LED module.
 * \param[in]
 *    uint8_t clkPin - The CLK pin for Seven-Segment LED module.
 * \par Output
 *    uint8_t Cmd_SetData - Private variable Cmd_SetData of class Me7SegmentDisplay.
 *    uint8_t Cmd_SetAddr - Private variable Cmd_SetAddr of class Me7SegmentDisplay.
 *    uint8_t Cmd_DispCtrl - Control command for Me 7 Segment Serial Display module.
 * \par Return
 *    None
 * \par Others
 */
Me7SegmentDisplay::Me7SegmentDisplay(uint8_t dataPin, uint8_t clkPin)
{
  _dataPin = dataPin;
  _clkPin = clkPin;
  pinMode(_clkPin, OUTPUT);
  pinMode(_dataPin, OUTPUT);
  set();
  clearDisplay();
}
#endif // ME_PORT_DEFINED

#ifdef ME_PORT_DEFINED
void Me7SegmentDisplay::reset(uint8_t port)
{
  reset(port);
  _clkPin = s2;
  _dataPin = s1;
  pinMode(_clkPin, OUTPUT);
  pinMode(_dataPin, OUTPUT);
  set();
  clearDisplay();
}
#endif // ME_PORT_DEFINED

/**
 * \par Function
 *    setpin
 * \par Description
 *    Set I2C data pin, clock pin and clear display.
 * \param[in]
 *    uint8_t dataPin - The DATA pin for Seven-Segment LED module.
 * \param[in]
 *    uint8_t clkPin - The CLK pin for Seven-Segment LED module.
 * \par Output
 *    None
 * \par Return
 *    None
 * \par Others
 *    Set global variable _KeyPin and s2
 */
void Me7SegmentDisplay::setpin(uint8_t dataPin, uint8_t clkPin)
{
  _dataPin = dataPin;
  _clkPin = clkPin;
  pinMode(_clkPin, OUTPUT);
  pinMode(_dataPin, OUTPUT);
#ifdef ME_PORT_DEFINED
  s1 = dataPin;
  s2 = clkPin;
#endif // ME_PORT_DEFINED
}

/**
 * \Function
 *    clearDisplay
 * \Description
 *    Clear display.
 * \par Output
 *    None
 * \par Return
 *    None
 * \par Others
 */
void Me7SegmentDisplay::clearDisplay(void)
{
  uint8_t buf[4] = { ' ', ' ', ' ', ' ' };
  display(buf);
}

/**
 * \par Function
 *    init
 * \par Description
 *    Clear display.
 * \param[in]
 *    None
 * \par Output  None
 * \return
 *    None
 * \others
 *    None
 */
void Me7SegmentDisplay::init(void)
{
  clearDisplay();
}

/**
 * \par Function
 *    writeByte
 * \par Description
 *    Simulate IIC and write data to IIC bus,  write one byte to TM1637.
 * \param[in]
 *    uint8_t wr_data - Data to write to module.
 * \par Output
 *    uint8_t Cmd_SetData - Private variable Cmd_SetData of class Me7SegmentDisplay.
 *    uint8_t Cmd_SetAddr - Private variable Cmd_SetAddr of class Me7SegmentDisplay.
 *    uint8_t Cmd_DispCtrl - Control command for Me 7 Segment Serial Display module.
 * \return
 *    None
 * \others
 */
void Me7SegmentDisplay::writeByte(uint8_t wr_data)
{
  uint8_t i;
  uint8_t cnt0;
  for (i = 0; i < 8; i++)  //sent 8bit data
  {
    digitalWrite(_clkPin, LOW);
    if (wr_data & 0x01)
    {
      digitalWrite(_dataPin, HIGH); //LSB first
    }
    else
    {
      digitalWrite(_dataPin, LOW);
    }
    wr_data >>= 1;
    digitalWrite(_clkPin, HIGH);

  }
  digitalWrite(_clkPin, LOW); //wait for ACK
  digitalWrite(_dataPin, HIGH);
  digitalWrite(_clkPin, HIGH);
  pinMode(_dataPin, INPUT);
  while (digitalRead(_dataPin))
  {
    cnt0 += 1;
    if (cnt0 == 200)
    {
      pinMode(_dataPin, OUTPUT);
      digitalWrite(_dataPin, LOW);
      cnt0 = 0;
    }
    //pinMode(_dataPin,INPUT);
  }
  pinMode(_dataPin, OUTPUT);

}

//send start signal to TM1637
/**
 * \par Function
 *    start
 * \par Description
 *    Start display.
 * \param[in]
 *    None
 * \par Output
 *    uint8_t Cmd_SetData - Private variable Cmd_SetData of class Me7SegmentDisplay.
 *    uint8_t Cmd_SetAddr - Private variable Cmd_SetAddr of class Me7SegmentDisplay.
 *    uint8_t Cmd_DispCtrl - Control command for Me 7 Segment Serial Display module.
 * \return
 *    None
 * \others
 *    Set global variable _KeyPin and s2
 */
void Me7SegmentDisplay::start(void)
{
  digitalWrite(_clkPin, HIGH); //send start signal to TM1637
  digitalWrite(_dataPin, HIGH);
  digitalWrite(_dataPin, LOW);
  digitalWrite(_clkPin, LOW);
}

//End of transmission
/**
 * \par Function
 *    stop
 * \par Description
 *    Stop display.
 * \param[in]
 *    None
 * \par Output
 *    None
 * \return
 *    None
 * \others
 *    Set global variable _KeyPin and s2
 */
void Me7SegmentDisplay::stop(void)
{
  digitalWrite(_clkPin, LOW);
  digitalWrite(_dataPin, LOW);
  digitalWrite(_clkPin, HIGH);
  digitalWrite(_dataPin, HIGH);
}

/**
 * \par Function
 *    write
 * \par Description
 *    White data array to module.
 * \param[in]
 *    uint8_t SegData[] - Data array to write to module.
 * \par Output
 *    uint8_t Cmd_SetData - Private variable Cmd_SetData of class Me7SegmentDisplay.
 *    uint8_t Cmd_SetAddr - Private variable Cmd_SetAddr of class Me7SegmentDisplay.
 *    uint8_t Cmd_DispCtrl - Control command for Me 7 Segment Serial Display module.
 * \return
 *    None
 * \par Others
 */
void Me7SegmentDisplay::write(uint8_t SegData[])
{
  uint8_t i;
  start();    // Start signal sent to TM1637 from MCU.
  writeByte(ADDR_AUTO);
  stop();
  start();
  writeByte(Cmd_SetAddr);
  for (i = 0; i < 4; i++)
  {
    writeByte(SegData[i]);
  }
  stop();
  start();
  writeByte(Cmd_DispCtrl);
  stop();
}

/**
 * \par Function
 *    write
 * \par Description
 *    White data array to certain address.
 * \param[in]
 *    uint8_t BitAddr - Bit address of data.
 * \param[in]
 *    uint8_t SegData - Data to display.
 * \par Output
 *    uint8_t Cmd_SetData - Private variable Cmd_SetData of class Me7SegmentDisplay.
 *    uint8_t Cmd_SetAddr - Private variable Cmd_SetAddr of class Me7SegmentDisplay.
 *    uint8_t Cmd_DispCtrl - Control command for Me 7 Segment Serial Display module.
 * \return
 *    None
 * \others
 */
void Me7SegmentDisplay::write(uint8_t BitAddr, uint8_t SegData)
{
  start();    // start signal sent to TM1637 from MCU
  writeByte(ADDR_FIXED);
  stop();
  start();
  writeByte(BitAddr | STARTADDR);
  writeByte(SegData);
  stop();
  start();
  writeByte(Cmd_DispCtrl);
  stop();
}

/**
 * \par Function
 *    display
 * \par Description
 *    Display certain value.
 * \param[in]
 *    uint16_t value - Value to display.
 * \par Output
 *    None
 * \return
 *    None
 * \par Others
 */
void Me7SegmentDisplay::display(uint16_t value)
{
  display((int16_t)value);
}

/**
 * \par Function
 *    display
 * \par Description
 *    Display certain value.
 * \param[in]
 *    int16_t value - Value to display.
 * \par Output
 *    None
 * \return
 *    None
 * \par Others
 */
void Me7SegmentDisplay::display(int16_t value)
{
  display((double)value, 0);
}

/**
 * \par Function
 *    display
 * \par Description
 *    Display double number.
 * \param[in]
 *    double value - Value to display.
 * \param[in]
 *    uint8_t digits - Number of digits to display.
 * \par Output
 *    None
 * \return
 *    None
 * \par Others
 */
void Me7SegmentDisplay::display(double value, uint8_t digits)
{
Posotion_1:
  uint8_t buf[4] = { ' ', ' ', ' ', ' ' };
  uint8_t tempBuf[4];
  uint8_t b = 0;
  uint8_t bit_num = 0;
  uint8_t int_num = 0;
  uint8_t isNeg = 0;
  double number = value;
  if (number >= 9999.5 || number <= -999.5)
  {
    buf[0] = ' ';
    buf[1] = ' ';
    buf[2] = ' ';
    buf[3] = 0x0e;
  }
  else
  {
    // Handle negative numbers
    if (number < 0.0)
    {
      number = -number;
      isNeg = 1;
    }
    // Round correctly so that print(1.999, 2) prints as "2.00"
    double rounding = 0.5;
    for (uint8_t i = 0; i < digits; ++i)
    {
      rounding /= 10.0;
    }
    number += rounding;

    // Extract the integer part of the number and print it
    uint16_t int_part = (uint16_t)number;
    double remainder = number - (double)int_part;
    do
    {
      uint16_t m = int_part;
      int_part /= 10;
      int8_t c = m - 10 * int_part;
      tempBuf[int_num] = c;
      int_num++;
    }
    while (int_part);

    bit_num = isNeg + int_num + digits;

    if (bit_num > 4)
    {
      bit_num = 4;
      digits = 4 - (isNeg + int_num);
      goto Posotion_1;
    }
    b = 4 - bit_num;
    if (isNeg)
    {
      buf[b++] = 0x21; // '-' display minus sign
    }
    for (uint8_t i = int_num; i > 0; i--)
    {
      buf[b++] = tempBuf[i - 1];
    }
    // Print the decimal point, but only if there are digits beyond
    if (digits > 0)
    {
      buf[b - 1] += 0x10;  // display '.'
      // Extract digits from the remainder one at a time
      while (digits-- > 0)
      {
        remainder *= 10.0;
        int16_t toPrint = int16_t(remainder);
        buf[b++] = toPrint;
        remainder -= toPrint;
      }
    }
  }
  display(buf);
}

/**
 * \par Function
 *    display
 * \par Description
 *    Display 8 bit number array.
 * \param[in]
 *    uint8_t DispData[]
 * \par Output
 *    None
 * \return
 *    None
 * \par Others
 */
void Me7SegmentDisplay::display(uint8_t DispData[])
{
  uint8_t SegData[4];
  uint8_t i;
  for (i = 0; i < 4; i++)
  {
    SegData[i] = DispData[i];
  }
  coding(SegData);
  write(SegData);
}

/**
 * \par Function
 *    display
 * \par Description
 *    Display data to certain digit.
 * \param[in]
 *    uint8_t DispData - Data to display.
 * \param[in]
 *    uint8_t BitAddr - Address to display.
 * \par Output
 *    None
 * \return
 *    None
 * \par Others
 */
void Me7SegmentDisplay::display(uint8_t DispData, uint8_t BitAddr)
{
  uint8_t SegData;

  if ((DispData >= 'A' && DispData <= 'F'))
  {
    DispData = DispData - 'A' + 10;
  }
  else if ((DispData >= 'a' && DispData <= 'f'))
  {
    DispData = DispData - 'a' + 10;
  }
  SegData = coding(DispData);
  write(BitAddr, SegData);
}


/**
 * \par Function
 *    set
 * \par Description
 *    Set brightness, data and address.
 * \param[in]
 *    uint8_t SetData - Data
 * \param[in]
 *    uint8_t SetAddr - Address
 * \param[in]
 *    uint8_t brightness - Brightness
 * \par Output
 *    uint8_t Cmd_SetData - Private variable Cmd_SetData of class Me7SegmentDisplay.
 *    uint8_t Cmd_SetAddr - Private variable Cmd_SetAddr of class Me7SegmentDisplay.
 *    uint8_t Cmd_DispCtrl - Control command for Me 7 Segment Serial Display module.
 * \return
 *    None
 * \par Others
 */
void Me7SegmentDisplay::set(uint8_t brightness, uint8_t SetData, uint8_t SetAddr)
{
  Cmd_SetData = SetData;
  Cmd_SetAddr = SetAddr;
  Cmd_DispCtrl = SEGDIS_ON + brightness;//Set brightness, take effect next display cycle.
}


/**
 * \par Function
 *    setBrightness
 * \par Description
 *    Set brightness.
 * \param[in]
 *    uint8_t brightness - Brightness, defined in Me7SegmentDisplay.h from BRIGHTNESS_0 to BRIGHTNESS_7.
 * \par Output
 *    uint8_t Cmd_DispCtrl - Control command for Me 7 Segment Serial Display module.
 * \return
 *    None
 * \par Others
 */

void Me7SegmentDisplay::setBrightness(uint8_t brightness)
{
  Cmd_DispCtrl = SEGDIS_ON + brightness;
}

/**
 * \par Function
 *    coding
 * \par Description
 *    Set display data using look up table.
 * \param[in]
 *    uint8_t DispData[] - DataArray to display.
 * \par Output
 *    DispData[] - DataArray to be displayed.
 * \return
 *    None
 * \par Others
 */
void Me7SegmentDisplay::coding(uint8_t DispData[])
{
  for (uint8_t i = 0; i < 4; i++)
  {
    if (DispData[i] >= sizeof(TubeTab) / sizeof(*TubeTab))
    {
      DispData[i] = 32; // Change to ' '(space)
    }
    DispData[i] = TubeTab[DispData[i]];
  }
}


/**
 * \par Function
 *    coding
 * \par Description
 *    Return display data from look up table.
 * \param[in]
 *    uint8_t DispData - DataArray to display.
 * \par Output
 *    None
 * \return
 *    uint8_t DispData
 * \par Others
 */
uint8_t Me7SegmentDisplay::coding(uint8_t DispData)
{
  if (DispData >= sizeof(TubeTab) / sizeof(*TubeTab))
  {
    DispData = 32; // Change to ' '(space)
  }
  DispData = TubeTab[DispData];//+ PointData;
  return DispData;
}
