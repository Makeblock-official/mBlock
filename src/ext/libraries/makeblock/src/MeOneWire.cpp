/**
 * \par Copyright (C), 2012-2015, MakeBlock
 * \class MeOneWire
 * \brief   Driver for 1-wire protocol.
 * @file    MeOneWire.cpp
 * @author  MakeBlock
 * @version V1.0.0
 * @date    2015/09/04
 * @brief   Driver for 1-wire protocol.
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
 * This file is a drive for 1-wire protocol, 1-Wire communication protocol
 * was developed by Dallas Semiconductor owned by Maxim. This protocol allows
 * communication of multiple chips to one host with minimal pin count.
 * The protocol is called 1-Wire because it uses 1 wire to transfer data.
 * 1-Wire architecture uses pull up resistor to pull voltage of data line at
 * master side.
 *
 * \par Method List:
 *
 *    1. bool  MeOneWire::readIO(void)
 *    2. void MeOneWire::reset(uint8_t pin)
 *    3. uint8_t MeOneWire::reset(void)
 *    4. void MeOneWire::select(const uint8_t rom[8])
 *    5. void MeOneWire::skip(void)()
 *    6. void MeOneWire::write(uint8_t v, uint8_t power = 0)
 *    7. void MeOneWire::write_bytes(const uint8_t *buf, uint16_t count, bool power = 0)
 *    8. uint8_t MeOneWire::read(void)
 *    9. void MeOneWire::read_bytes(uint8_t *buf, uint16_t count)
 *    10. void MeOneWire::write_bit(uint8_t v)
 *    11. uint8_t MeOneWire::read_bit(void)
 *    12. void MeOneWire::depower(void)
 *    13. void MeOneWire::reset_search(void)
 *    14. void MeOneWire::target_search(uint8_t family_code)
 *    15. uint8_t MeOneWire::search(uint8_t *newAddr)
 *
 * \par History:
 * <pre>
 * `<Author>`         `<Time>`        `<Version>`        `<Descr>`
 * Mark Yan         2015/09/04     1.0.0            Rebuild the old lib.
 * </pre>
 *
 */
#include "MeOneWire.h"
/**
 * Alternate Constructor which can call your own function to map the MeOneWire to arduino port,
 * no pins are used or initialized here.
 * \param[in]
 *   None
 */
MeOneWire::MeOneWire(void)
{

}

/**
 * Alternate Constructor which can call your own function to map the MeOneWire to arduino port,
 * it will assigned the shot PIN and focus pin.
 * \param[in]
 *   pin - arduino port for 1-wire(should digital pin)
 */
MeOneWire::MeOneWire(uint8_t pin)
{
  bitmask = MePIN_TO_BITMASK(pin);
  baseReg = MePIN_TO_BASEREG(pin);
  // reset_search();
}

/**
 * \par Function
 *   reset
 * \par Description
 *   Reset the available PIN for 1-wire
 * \param[in]
 *   pin - arduino port(should digital pin)
 * \par Output
 *   None 
 * \return
 *   None
 * \par Others
 *   None
 */
void MeOneWire::reset(uint8_t pin)
{
  bitmask = MePIN_TO_BITMASK(pin);
  baseReg = MePIN_TO_BASEREG(pin);
}

/**
 * \par Function
 *   readIO
 * \par Description
 *   Read a bit from 1-wire data port
 * \par Output
 *   None 
 * \return
 *   return the bit value we read
 * \par Others
 *   None
 */
bool MeOneWire::readIO(void)
{
  MeIO_REG_TYPE           mask = bitmask;
  volatile MeIO_REG_TYPE *reg MeIO_REG_ASM = baseReg;
  uint8_t r;
  MeDIRECT_MODE_INPUT(reg, mask);    // allow it to float
  delayMicroseconds(10);
  r = MeDIRECT_READ(reg, mask);
  return(r);
}

/**
 * \par Function
 *   reset
 * \par Description
 *   Perform the MeOneWire reset function.  We will wait up to 250uS for
 *   the bus to come high, if it doesn't then it is broken or shorted.
 * \param[in]
 *   v - The bit value need be written
 * \par Output
 *   None 
 * \return
 *   Returns 1 if a device asserted a presence pulse, 0 otherwise.
 * \par Others
 *   None
 */
uint8_t MeOneWire::reset(void)
{
  MeIO_REG_TYPE mask = bitmask;
  volatile MeIO_REG_TYPE *reg MeIO_REG_ASM = baseReg;
  uint8_t r;
  uint8_t retries = 125;

  noInterrupts();
  MeDIRECT_MODE_INPUT(reg, mask);
  interrupts();
  /* wait until the wire is high... just in case */
  do
  {
    if (--retries == 0)
    {
      return(0);
    }
    delayMicroseconds(2);
  }
  while (!MeDIRECT_READ(reg, mask));

  noInterrupts();
  MeDIRECT_WRITE_LOW(reg, mask);
  MeDIRECT_MODE_OUTPUT(reg, mask);        /* drive output low */
  interrupts();
  delayMicroseconds(480);
  noInterrupts();
  MeDIRECT_MODE_INPUT(reg, mask);         /* allow it to float */
  delayMicroseconds(70);
  r = !MeDIRECT_READ(reg, mask);
  interrupts();
  delayMicroseconds(410);
  return(r);
}

/**
 * \par Function
 *   write_bit
 * \par Description
 *   Write a bit. The bus is always left powered at the end, see
 *   note in write() about that.
 * \param[in]
 *   v - The bit value need be written
 * \par Output
 *   None 
 * \return
 *   None
 * \par Others
 *   None
 */
void MeOneWire::write_bit(uint8_t v)
{
  MeIO_REG_TYPE mask = bitmask;
  volatile MeIO_REG_TYPE *reg MeIO_REG_ASM = baseReg;

  if (v & 1)
  {
    noInterrupts();
    MeDIRECT_WRITE_LOW(reg, mask);
    MeDIRECT_MODE_OUTPUT(reg, mask);        /* drive output low */
    delayMicroseconds(10);
    MeDIRECT_WRITE_HIGH(reg, mask);         /* drive output high */
    interrupts();
    delayMicroseconds(55);
  }
  else
  {
    noInterrupts();
    MeDIRECT_WRITE_LOW(reg, mask);
    MeDIRECT_MODE_OUTPUT(reg, mask);        /* drive output low */
    delayMicroseconds(65);
    MeDIRECT_WRITE_HIGH(reg, mask);         /* drive output high */
    interrupts();
    delayMicroseconds(5);
  }
}

/**
 * \par Function
 *   read_bit
 * \par Description
 *   Read a bit. Port and bit is used to cut lookup time and provide
 *   more certain timing
 * \par Output
 *   None 
 * \return
 *   return the bit value we read
 * \par Others
 *   None
 */
uint8_t MeOneWire::read_bit(void)
{
  MeIO_REG_TYPE mask = bitmask;
  volatile MeIO_REG_TYPE *reg MeIO_REG_ASM = baseReg;
  uint8_t r;

  noInterrupts();
  MeDIRECT_MODE_OUTPUT(reg, mask);
  MeDIRECT_WRITE_LOW(reg, mask);
  delayMicroseconds(3);
  MeDIRECT_MODE_INPUT(reg, mask); /* let pin float, pull up will raise */
  delayMicroseconds(10);
  r = MeDIRECT_READ(reg, mask);
  interrupts();
  delayMicroseconds(53);
  return(r);
}

/**
 * \par Function
 *   write
 * \par Description
 *   Write a byte of data
 * \param[in]
 *   v - The value need be written
 * \param[in]
 *   power - Should we need active drivers to raise the pin high
 * \par Output
 *   None 
 * \return
 *   None
 * \par Others
 *   None
 */
void MeOneWire::write(uint8_t v, uint8_t power /* = 0 */)
{
  uint8_t bitMask;

  for (bitMask = 0x01; bitMask; bitMask <<= 1)
  {
    MeOneWire::write_bit((bitMask & v) ? 1 : 0);
  }
  if (!power)
  {
    noInterrupts();
    MeDIRECT_MODE_INPUT(baseReg, bitmask);
    MeDIRECT_WRITE_LOW(baseReg, bitmask);
    interrupts();
  }
}

/**
 * \par Function
 *   write_bytes
 * \par Description
 *   Write certain number of data
 * \param[in]
 *   buf - The buffer used to store the data that need be written
 * \param[in]
 *   count - The count of the bytes we need to write
 * \param[in]
 *   power - Should we need active drivers to raise the pin high
 * \par Output
 *   None 
 * \return
 *   None
 * \par Others
 *   None
 */
void MeOneWire::write_bytes(const uint8_t *buf, uint16_t count, bool power /* = 0 */)
{
  for (uint16_t i = 0; i < count; i++)
  {
    write(buf[i]);
  }
  if (!power)
  {
    noInterrupts();
    MeDIRECT_MODE_INPUT(baseReg, bitmask);
    MeDIRECT_WRITE_LOW(baseReg, bitmask);
    interrupts();
  }
}

/**
 * \par Function
 *   read
 * \par Description
 *   Read a byte of data
 * \par Output
 *   None 
 * \return
 *   The read data(8-bit data)
 * \par Others
 *   None
 */
uint8_t MeOneWire::read()
{
  uint8_t bitMask;
  uint8_t r = 0;

  for (bitMask = 0x01; bitMask; bitMask <<= 1)
  {
    if (MeOneWire::read_bit())
    {
      r |= bitMask;
    }
  }
  return(r);
}

/**
 * \par Function
 *   read_bytes
 * \par Description
 *   Read certain number of data
 * \param[out]
 *   buf - The buffer used to store the read data
 * \param[in]
 *   count - The count of the bytes we need to read
 * \par Output
 *   None 
 * \return
 *   None
 * \par Others
 *   None
 */
void MeOneWire::read_bytes(uint8_t *buf, uint16_t count)
{
  for (uint16_t i = 0; i < count; i++)
  {
    buf[i] = read();
  }
}

/**
 * \par Function
 *   select
 * \par Description
 *   Issue a 1-Wire rom select command.
 * \param[in]
 *   rom[8] - 64bit ROM code.
 * \par Output
 *   None 
 * \return
 *   None
 * \par Others
 *   None
 */
void MeOneWire::select(const uint8_t rom[8])
{
  uint8_t i;

  write(0x55);       /* Choose ROM */

  for (i = 0; i < 8; i++)
  {
    write(rom[i]);
  }
}

/**
 * \par Function
 *   skip
 * \par Description
 *   Issue a 1-Wire rom skip command.
 * \par Output
 *   None 
 * \return
 *   None
 * \par Others
 *   None
 */
void MeOneWire::skip(void)
{
  write(0xCC);       /* Skip ROM */
}

/**
 * \par Function
 *   depower
 * \par Description
 *   Stop forcing power onto the bus. You only need to do this if
 *   you used the 'power' flag to write() or used a write_bit() call
 *   and aren't about to do another read or write. You would rather
 *   not leave this powered if you don't have to, just in case
 *   someone shorts your bus.
 * \par Output
 *   None 
 * \return
 *   None
 * \par Others
 *   None
 */
void MeOneWire::depower(void)
{
  noInterrupts();
  MeDIRECT_MODE_INPUT(baseReg, bitmask);
  interrupts();
}

/**
 * \par Function
 *   reset_search
 * \par Description
 *   If we need search a new device, we need call this function to clear 
 *   the search state and all stored values  
 * \par Output
 *   Reset all stored values 
 * \return
 *   None
 * \par Others
 *   None
 */
void MeOneWire::reset_search(void)
{
  /* reset the search state */
  LastDiscrepancy = 0;
  LastDeviceFlag = false;
  LastFamilyDiscrepancy = 0;
  for (int16_t i = 7;; i--)
  {
    ROM_NO[i] = 0;
    if (i == 0)
    {
      break;
    }
  }
}

/**
 * \par Function
 *   target_search
 * \par Description
 *   Setup the search to find the device type 'family_code' on the next call
 *   of search(*newAddr) if it is present.
 * \param[in]
 *   family_code - the device type we need search
 * \par Output
 *   None
 * \return
 *   None
 * \par Others
 *   None
 */
void MeOneWire::target_search(uint8_t family_code)
{
  /* set the search state to find SearchFamily type devices */
  ROM_NO[0] = family_code;
  for (uint8_t i = 1; i < 8; i++)
  {
    ROM_NO[i] = 0;
  }
  LastDiscrepancy = 64;
  LastFamilyDiscrepancy = 0;
  LastDeviceFlag = false;
}

/**
 * \par Function
 *   search
 * \par Description
 *   Perform a search. If this function returns a '1' then it has
 *   enumerated the next device and you may retrieve the ROM from the
 *   MeOneWire::address variable. If there are no devices, no further
 *   devices, or something horrible happens in the middle of the
 *   enumeration then a '0' is returned. If a new device is found then
 *   its address is copied to newAddr.  Use MeOneWire::reset_search() to
 *   start over. you can get the algorithm from
 *   doc\Me_Temperature\Datasheet\1-Wire_Search_Algorithm.pdf
 * \param[out]
 *   newAddr - The adrress to store the ROM data 
 * \par Output
 *   None
 * \return
 *   true - device found, ROM number in ROM_NO buffer\r\n
 *   false - device not found, end of search
 * \par Others
 *   None
 */
uint8_t MeOneWire::search(uint8_t *newAddr)
{
  uint8_t id_bit_number;
  uint8_t last_zero, rom_byte_number, search_result;
  uint8_t id_bit, cmp_id_bit;

  uint8_t rom_byte_mask, search_direction;

  /* initialize for search */
  id_bit_number = 1;
  last_zero = 0;
  rom_byte_number = 0;
  rom_byte_mask = 1;
  search_result = 0;

  /* if the last call was not the last one */
  if (!LastDeviceFlag)
  {
    /* 1-Wire reset */
    if (!reset())
    {
      /* reset the search */
      LastDiscrepancy = 0;
      LastDeviceFlag = false;
      LastFamilyDiscrepancy = 0;
      return(false);
    }

    /* issue the search command */
    write(0xF0);

    /* loop to do the search */
    do
    {
      /* read a bit and its complement */
      id_bit = read_bit();
      cmp_id_bit = read_bit();

      /* check for no devices on 1-wire */
      if ((id_bit == 1) && (cmp_id_bit == 1))
      {
        break;
      }
      else
      {
        /* all devices coupled have 0 or 1 */
        if (id_bit != cmp_id_bit)
        {
          search_direction = id_bit; /* bit write value for search */
        }
        else
        {
          /*
             if this discrepancy if before the Last Discrepancy
             on a previous next then pick the same as last time
             */
          if (id_bit_number < LastDiscrepancy)
          {
            search_direction = ((ROM_NO[rom_byte_number] & rom_byte_mask) > 0);
          }
          else
          {
            /* if equal to last pick 1, if not then pick 0 */
            search_direction = (id_bit_number == LastDiscrepancy);
          }

          /* if 0 was picked then record its position in LastZero */
          if (search_direction == 0)
          {
            last_zero = id_bit_number;

            /* check for Last discrepancy in family */
            if (last_zero < 9)
            {
              LastFamilyDiscrepancy = last_zero;
            }
          }
        }

        /*
           set or clear the bit in the ROM byte rom_byte_number
           with mask rom_byte_mask
           */
        if (search_direction == 1)
        {
          ROM_NO[rom_byte_number] |= rom_byte_mask;
        }
        else
        {
          ROM_NO[rom_byte_number] &= ~rom_byte_mask;
        }

        /* serial number search direction write bit */
        write_bit(search_direction);

        /*
           increment the byte counter id_bit_number
           and shift the mask rom_byte_mask
           */
        id_bit_number++;
        rom_byte_mask <<= 1;

        /* if the mask is 0 then go to new SerialNum byte rom_byte_number and reset mask */
        if (rom_byte_mask == 0)
        {
          rom_byte_number++;
          rom_byte_mask = 1;
        }
      }
    }
    while (rom_byte_number < 8); /* loop until through all ROM bytes 0-7 */

    /* if the search was successful then */
    if (!(id_bit_number < 65))
    {
      /* search successful so set LastDiscrepancy,LastDeviceFlag,search_result */
      LastDiscrepancy = last_zero;

      /* check for last device */
      if (LastDiscrepancy == 0)
      {
        LastDeviceFlag = true;
      }

      search_result = true;
    }
  }

  /* if no device found then reset counters so next 'search' will be like a first */
  if (!search_result || !ROM_NO[0])
  {
    LastDiscrepancy = 0;
    LastDeviceFlag = false;
    LastFamilyDiscrepancy = 0;
    search_result = false;
  }
  for (int16_t i = 0; i < 8; i++)
  {
    newAddr[i] = ROM_NO[i];
  }
  return(search_result);
}

