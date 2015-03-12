#ifndef MeRGBLed_h
#define MeRGBLed_h 
#include "MePort.h"
struct cRGB { 
	uint8_t g; 
	uint8_t r; 
	uint8_t b;
};

///@brief Class for RGB Led Module(http://www.makeblock.cc/me-rgb-led-v1-0/) and Led Strip(http://www.makeblock.cc/led-rgb-strip-addressable-sealed-1m/)
class MeRGBLed:public MePort {
public: 
	MeRGBLed();
	MeRGBLed(uint8_t pin);
	MeRGBLed(MEPORT port);
	MeRGBLed(MEPORT port,uint8_t slot);
	~MeRGBLed();
	void reset(MEPORT port);
	void reset(MEPORT port,uint8_t slot);
        void reset(int pin);
	///@brief set the count of leds.
	void setNumber(uint8_t num_led);
	///@brief get the count of leds.
	uint8_t getNumber();
	///@brief get the rgb value of the led with the index.
	cRGB getColorAt(uint8_t index);
	///@brief set the rgb value of the led with the index.
	bool setColorAt(uint8_t index, uint8_t red,uint8_t green,uint8_t blue);
	bool setColorAt(uint8_t index, long value);
	void setColor(uint8_t index, uint8_t red,uint8_t green,uint8_t blue);
	void setColor(uint8_t red,uint8_t green,uint8_t blue);
	void setColor(long value);
	void clear();
	///@brief become effective of all led's change.
	void show();
	
private:
	uint16_t count_led;
	uint8_t *pixels;
	
	void rgbled_sendarray_mask(uint8_t *array,uint16_t length, uint8_t pinmask,uint8_t *port);

	const volatile uint8_t *ws2812_port;
	uint8_t pinMask; 
};
#endif
