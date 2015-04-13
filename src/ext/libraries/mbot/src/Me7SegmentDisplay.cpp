#include "Me7SegmentDisplay.h"

static int8_t TubeTab[] = {0x3f, 0x06, 0x5b, 0x4f,
                           0x66, 0x6d, 0x7d, 0x07,
                           0x7f, 0x6f, 0x77, 0x7c,
                           0x39, 0x5e, 0x79, 0x71,
                           0xbf, 0x86, 0xdb, 0xcf,
                           0xe6, 0xed, 0xfd, 0x87,
                           0xff, 0xef, 0xf7, 0xfc,
                           0xb9, 0xde, 0xf9, 0xf1, 0, 0x40
                          };//0~9,A,b,C,d,E,F,''，-
Me7SegmentDisplay::Me7SegmentDisplay(): MePort()
{
}
Me7SegmentDisplay::Me7SegmentDisplay(uint8_t dataPin,uint8_t clkPin)
{	
    s1 = dataPin;
    s2 = clkPin;
    pinMode(s2, OUTPUT);
    pinMode(s1, OUTPUT);
    set();
    clearDisplay();
}
Me7SegmentDisplay::Me7SegmentDisplay(uint8_t port): MePort(port)
{   
    pinMode(s2, OUTPUT);
    pinMode(s1, OUTPUT);
    set();
    clearDisplay();
}
void Me7SegmentDisplay::reset(uint8_t port)
{
    reset(port);
    s2 = s2;
    s1 = s1;
    pinMode(s2, OUTPUT);
    pinMode(s1, OUTPUT);
    set();
    clearDisplay();
}
void Me7SegmentDisplay::init(void)
{
    clearDisplay();
}

void Me7SegmentDisplay::writeByte(int8_t wr_data)
{
    uint8_t i, count1;
    for(i = 0; i < 8; i++)  //sent 8bit data
    {
        digitalWrite(s2, LOW);
        if(wr_data & 0x01)digitalWrite(s1, HIGH); //LSB first
        else digitalWrite(s1, LOW);
        wr_data >>= 1;
        digitalWrite(s2, HIGH);

    }
    digitalWrite(s2, LOW); //wait for the ACK
    digitalWrite(s1, HIGH);
    digitalWrite(s2, HIGH);
    pinMode(s1, INPUT);
    while(digitalRead(s1))
    {
        count1 += 1;
        if(count1 == 200)//
        {
            pinMode(s1, OUTPUT);
            digitalWrite(s1, LOW);
            count1 = 0;
        }
        //pinMode(s1,INPUT);
    }
    pinMode(s1, OUTPUT);

}
//send start signal to TM1637
void Me7SegmentDisplay::start(void)
{
    digitalWrite(s2, HIGH); //send start signal to TM1637
    digitalWrite(s1, HIGH);
    digitalWrite(s1, LOW);
    digitalWrite(s2, LOW);
}
//End of transmission
void Me7SegmentDisplay::stop(void)
{
    digitalWrite(s2, LOW);
    digitalWrite(s1, LOW);
    digitalWrite(s2, HIGH);
    digitalWrite(s1, HIGH);
}


void Me7SegmentDisplay::display(uint16_t value)
{
    display((int)value);
    // display((double)value,0);
}

void Me7SegmentDisplay::display(int16_t value)
{
    display((double)value, 0);
}

void Me7SegmentDisplay::display(double value, uint8_t digits)
{


AA:
    int8_t buf[4] = {' ', ' ', ' ', ' '};
    int8_t tempBuf[4];
    uint8_t b = 0;
    uint8_t bit_num = 0;
    uint8_t  int_num = 0;
    uint8_t isNeg = 0;
    double number = value;
    if (number >= 9999.5 || number <= -999.5);
    else
    {
        // Handle negative numbers
        if (number < 0.0)
        {
            number = -number;
            isNeg = 1 ;
        }
        // Round correctly so that print(1.999, 2) prints as "2.00"
        double rounding = 0.5;
        for (uint8_t i = 0; i < digits; ++i)
            rounding /= 10.0;
        number += rounding;

        // Extract the integer part of the number and print it
        uint16_t int_part = (uint16_t )number;
        double remainder = number - (double)int_part;
        do
        {
            uint16_t m = int_part;
            int_part /= 10;
            char c = m - 10 * int_part;
            tempBuf[int_num] = c;
            int_num++;
        }
        while(int_part);

        bit_num = isNeg + int_num + digits;

        if(bit_num > 4)
        {
            bit_num = 4;
            digits = 4 - (isNeg + int_num);
            goto AA;
        }
        b = 4 - bit_num;
        if(isNeg)buf[b++] = 0x21;

        for(uint8_t i = int_num; i > 0; i--)buf[b++] = tempBuf[i-1];
        // Print the decimal point, but only if there are digits beyond
        if (digits > 0)
        {
            buf[b-1] += 0x10;
            // Extract digits from the remainder one at a time
            while (digits-- > 0)
            {
                remainder *= 10.0;
                int toPrint = int(remainder);
                buf[b++] = toPrint;
                remainder -= toPrint;
            }
        }
    }
    display(buf);
}

void Me7SegmentDisplay::write(int8_t SegData[])
{
    uint8_t i;
    start();          //start signal sent to TM1637 from MCU
    writeByte(ADDR_AUTO);
    stop();
    start();
    writeByte(Cmd_SetAddr);
    for(i = 0; i < 4; i ++)
    {
        writeByte(SegData[i]);
    }
    stop();
    start();
    writeByte(Cmd_DispCtrl);
    stop();
}
void Me7SegmentDisplay::write(uint8_t BitAddr, int8_t SegData)
{
    start();          //start signal sent to TM1637 from MCU
    writeByte(ADDR_FIXED);
    stop();
    start();
    writeByte(BitAddr | 0xc0);
    writeByte(SegData);
    stop();
    start();
    writeByte(Cmd_DispCtrl);
    stop();
}
void Me7SegmentDisplay::display(int8_t DispData[])
{
    int8_t SegData[4];
    uint8_t i;
    for(i = 0; i < 4; i ++)
    {
        SegData[i] = DispData[i];
    }
    coding(SegData);
    write(SegData);
}
//******************************************
void Me7SegmentDisplay::display(uint8_t BitAddr, int8_t DispData)
{
    int8_t SegData;

    if((DispData >= 'A' && DispData <= 'F'))DispData = DispData - 'A' + 10;
    else if((DispData >= 'a' && DispData <= 'f'))DispData = DispData - 'a' + 10;
    SegData = coding(DispData);
    write(BitAddr, SegData); //
}

void Me7SegmentDisplay::clearDisplay(void)
{
    int8_t buf[4] = {' ', ' ', ' ', ' '};
    display(buf);
}
//To take effect the next time it displays.
void Me7SegmentDisplay::set(uint8_t brightness, uint8_t SetData, uint8_t SetAddr)
{
    Cmd_SetData = SetData;
    Cmd_SetAddr = SetAddr;
    Cmd_DispCtrl = 0x88 + brightness;//Set the brightness and it takes effect the next time it displays.
}


void Me7SegmentDisplay::coding(int8_t DispData[])
{
    //  uint8_t PointData = 0;
    for(uint8_t i = 0; i < 4; i ++)
    {
        DispData[i] = TubeTab[DispData[i]];
    }
}
int8_t Me7SegmentDisplay::coding(int8_t DispData)
{
    //  uint8_t PointData = 0;
    DispData = TubeTab[DispData] ;//+ PointData;
    return DispData;
}
