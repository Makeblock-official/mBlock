#ifndef Me7SegmentDisplay_H
#define Me7SegmentDisplay_H 
#include "MePort.h"
//************definitions for TM1637*********************
#define ADDR_AUTO 0x40
#define ADDR_FIXED 0x44
#define STARTADDR 0xc0
/**** definitions for the clock point of the digit tube *******/
#define POINT_ON 1
#define POINT_OFF 0
/**************definitions for brightness***********************/
#define BRIGHT_DARKEST 0
#define BRIGHT_TYPICAL 2
#define BRIGHTEST 7
///@brief Class for numeric display module
class Me7SegmentDisplay:public MePort
{
	public:
		Me7SegmentDisplay();
		Me7SegmentDisplay(uint8_t dataPin,uint8_t clkPin);
		Me7SegmentDisplay(uint8_t port);
		void init(void); //To clear the display
		void set(uint8_t = BRIGHT_TYPICAL,uint8_t = 0x40,uint8_t = 0xc0);//To take effect the next time it displays.
		void reset(uint8_t port);
		void write(int8_t SegData[]);
    	void write(uint8_t BitAddr, int8_t SegData);
		void display(uint16_t value);
	    void display(int16_t value);
	    void display(double value, uint8_t = 1) ;
	    void display(int8_t DispData[]);
	    void display(uint8_t BitAddr, int8_t DispData);
		void clearDisplay(void);
	private:
		uint8_t Cmd_SetData;
		uint8_t Cmd_SetAddr;
		uint8_t Cmd_DispCtrl;
		boolean _PointFlag; //_PointFlag=1:the clock point on
		void writeByte(int8_t wr_data);//write 8bit data to tm1637
		void start(void);//send start bits
		void stop(void); //send stop bits
		void point(boolean PointFlag);//whether to light the clock point ":".To take effect the next time it displays.
		void coding(int8_t DispData[]);
		int8_t coding(int8_t DispData);
		int checkNum(float v,int b);
		uint8_t _clkPin;
		uint8_t _dataPin;
}; 
#endif
