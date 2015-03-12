#include "MeRGBLed.h"
MeRGBLed::MeRGBLed()
{
    pinMask = digitalPinToBitMask(13);
    ws2812_port = portOutputRegister(digitalPinToPort(13));
    pinMode(13, OUTPUT);
    setNumber(2);  
}

MeRGBLed::MeRGBLed(uint8_t pin)
{
    s2 = pin;
    pinMask = digitalPinToBitMask(pin);
    ws2812_port = portOutputRegister(digitalPinToPort(pin));
    pinMode(pin, OUTPUT);
    setNumber(4);
}

MeRGBLed::MeRGBLed(MEPORT port): MePort(port)
{
    pinMask = digitalPinToBitMask(s2);
    ws2812_port = portOutputRegister(digitalPinToPort(s2));
    pinMode(s2, OUTPUT);
    setNumber(4);
}
MeRGBLed::MeRGBLed(MEPORT port, uint8_t slot): MePort(port)
{
    if(slot == SLOT2)
    {
        pinMask = digitalPinToBitMask(s2);
        ws2812_port = portOutputRegister(digitalPinToPort(s2));
        pinMode(s2, OUTPUT);
    }
    else
    {
        pinMask = digitalPinToBitMask(s1);
        ws2812_port = portOutputRegister(digitalPinToPort(s1));
        pinMode(s1, OUTPUT);
    }
    setNumber(4);
}
void MeRGBLed::reset(int pin){
    pinMask = digitalPinToBitMask(pin);
    ws2812_port = portOutputRegister(digitalPinToPort(pin));
    pinMode(pin, OUTPUT);
}
void MeRGBLed::reset(MEPORT port)
{
    s2 = mePort[port].s2;
    s1 = mePort[port].s1;
    pinMask = digitalPinToBitMask(s2);
    ws2812_port = portOutputRegister(digitalPinToPort(s2));
    pinMode(s2, OUTPUT);
}

void MeRGBLed::reset(MEPORT port, uint8_t slot)
{
	s2 = mePort[port].s2;
    s1 = mePort[port].s1;
    if(slot == SLOT2)
    {
        pinMask = digitalPinToBitMask(s2);
        ws2812_port = portOutputRegister(digitalPinToPort(s2));
        pinMode(s2, OUTPUT);
    }
    else
    {
        pinMask = digitalPinToBitMask(s1);
        ws2812_port = portOutputRegister(digitalPinToPort(s1));
        pinMode(s1, OUTPUT);
    }
    setNumber(4);
}

void MeRGBLed::setNumber(uint8_t num_leds)
{
    count_led = num_leds;
    pixels = (uint8_t *)malloc(count_led * 3);
    clear();
}
cRGB MeRGBLed::getColorAt(uint8_t index)
{

    cRGB px_value;

    if(index < count_led)
    {

        uint8_t tmp;
        tmp = index * 3;

        px_value.g = pixels[tmp];
        px_value.r = pixels[tmp+1];
        px_value.b = pixels[tmp+2];
    }

    return px_value;
}

uint8_t MeRGBLed::getNumber()
{
    return count_led;
}
bool MeRGBLed::setColorAt(uint8_t index, uint8_t red, uint8_t green, uint8_t blue)
{
    if(index < count_led)
    {
        uint8_t tmp = index * 3;
        pixels[tmp] = green;
        pixels[tmp+1] = red;
        pixels[tmp+2] = blue;

        return true;
    }
    return false;
}
bool MeRGBLed::setColorAt(uint8_t index, long value)
{
    if(index < count_led)
    {
        uint8_t tmp = index * 3;
        uint8_t red = (value & 0xff0000) >> 16;
        uint8_t green = (value & 0xff00) >> 8;
        uint8_t blue = value & 0xff;
        pixels[tmp] = green;
        pixels[tmp+1] = red;
        pixels[tmp+2] = blue;
        return true;
    }
    return false;
}

void MeRGBLed::setColor(uint8_t index,uint8_t red, uint8_t green, uint8_t blue){
  if(index==0){
    setColor(red,green,blue);
  }else{
    setColorAt(index-1,red,green,blue);
  }
}
void MeRGBLed::setColor(uint8_t red, uint8_t green, uint8_t blue)
{
    for (int i = 0; i < count_led; ++i)
    {
        uint8_t tmp = i * 3;
        pixels[tmp] = green;
        pixels[tmp+1] = red;
        pixels[tmp+2] = blue;
    }
    show();   
}

void MeRGBLed::setColor(long value)
{
    for (int i = 0; i < count_led; ++i)
    {
        uint8_t tmp = i * 3;
        uint8_t red = (value & 0xff0000) >> 16;
        uint8_t green = (value & 0xff00) >> 8;
        uint8_t blue = value & 0xff;
        pixels[tmp] = green;
        pixels[tmp+1] = red;
        pixels[tmp+2] = blue;
    }
    show();
}

void MeRGBLed::clear()
{
    // for(int i = 0; i < count_led; i++)
    // {
    //     setColorAt(i, 0, 0, 0);
    // }
    memset(pixels,0,3*count_led);
    show();
}
/*
  This routine writes an array of bytes with RGB values to the Dataout pin
  using the fast 800kHz clockless WS2811/2812 protocol.
*/

// Timing in ns
#define w_zeropulse   350
#define w_onepulse    900
#define w_totalperiod 1250

// Fixed cycles used by the inner loop
#define w_fixedlow    3
#define w_fixedhigh   6
#define w_fixedtotal  10

// Insert NOPs to match the timing, if possible
#define w_zerocycles    (((F_CPU/1000)*w_zeropulse          )/1000000)
#define w_onecycles     (((F_CPU/1000)*w_onepulse    +500000)/1000000)
#define w_totalcycles   (((F_CPU/1000)*w_totalperiod +500000)/1000000)

// w1 - nops between rising edge and falling edge - low
#define w1 (w_zerocycles-w_fixedlow)
// w2   nops between fe low and fe high
#define w2 (w_onecycles-w_fixedhigh-w1)
// w3   nops to complete loop
#define w3 (w_totalcycles-w_fixedtotal-w1-w2)

#if w1>0
#define w1_nops w1
#else
#define w1_nops  0
#endif

// The only critical timing parameter is the minimum pulse length of the "0"
// Warn or throw error if this timing can not be met with current F_CPU settings.
#define w_lowtime ((w1_nops+w_fixedlow)*1000000)/(F_CPU/1000)
#if w_lowtime>550
#error "Light_ws2812: Sorry, the clock speed is too low. Did you set F_CPU correctly?"
#elif w_lowtime>450
#warning "Light_ws2812: The timing is critical and may only work on WS2812B, not on WS2812(S)."
#warning "Please consider a higher clockspeed, if possible"
#endif

#if w2>0
#define w2_nops w2
#else
#define w2_nops  0
#endif

#if w3>0
#define w3_nops w3
#else
#define w3_nops  0
#endif

#define w_nop1  "nop      \n\t"
#define w_nop2  "rjmp .+0 \n\t"
#define w_nop4  w_nop2 w_nop2
#define w_nop8  w_nop4 w_nop4
#define w_nop16 w_nop8 w_nop8

void  MeRGBLed::rgbled_sendarray_mask(uint8_t *data, uint16_t datlen, uint8_t maskhi, uint8_t *port)
{
    uint8_t curbyte, ctr, masklo;
    uint8_t oldSREG = SREG;
    cli();  //Disables all interrupts

    masklo = *port & ~maskhi;
    maskhi = *port | maskhi;

    while (datlen--)
    {
        curbyte = *data++;

        asm volatile(
            "       ldi   %0,8  \n\t"
            "loop%=:            \n\t"
            "       st    X,%3 \n\t"    //  '1' [02] '0' [02] - re
#if (w1_nops&1)
            w_nop1
#endif
#if (w1_nops&2)
            w_nop2
#endif
#if (w1_nops&4)
            w_nop4
#endif
#if (w1_nops&8)
            w_nop8
#endif
#if (w1_nops&16)
            w_nop16
#endif
            "       sbrs  %1,7  \n\t"    //  '1' [04] '0' [03]
            "       st    X,%4 \n\t"     //  '1' [--] '0' [05] - fe-low
            "       lsl   %1    \n\t"    //  '1' [05] '0' [06]
#if (w2_nops&1)
            w_nop1
#endif
#if (w2_nops&2)
            w_nop2
#endif
#if (w2_nops&4)
            w_nop4
#endif
#if (w2_nops&8)
            w_nop8
#endif
#if (w2_nops&16)
            w_nop16
#endif
            "       brcc skipone%= \n\t"    //  '1' [+1] '0' [+2] -
            "       st   X,%4      \n\t"    //  '1' [+3] '0' [--] - fe-high
            "skipone%=:               "     //  '1' [+3] '0' [+2] -

#if (w3_nops&1)
            w_nop1
#endif
#if (w3_nops&2)
            w_nop2
#endif
#if (w3_nops&4)
            w_nop4
#endif
#if (w3_nops&8)
            w_nop8
#endif
#if (w3_nops&16)
            w_nop16
#endif

            "       dec   %0    \n\t"    //  '1' [+4] '0' [+3]
            "       brne  loop%=\n\t"    //  '1' [+5] '0' [+4]
            :	"=&d" (ctr)
            //    :	"r" (curbyte), "I" (_SFR_IO_ADDR(ws2812_PORTREG)), "r" (maskhi), "r" (masklo)
            :	"r" (curbyte), "x" (port), "r" (maskhi), "r" (masklo)
        );
    }

    SREG = oldSREG;
}
void MeRGBLed::show()
{
    //	*ws2812_port_reg |= pinMask; // Enable DDR
    rgbled_sendarray_mask(pixels, 3 * count_led, pinMask, (uint8_t *) ws2812_port);
}

MeRGBLed::~MeRGBLed()
{


}
