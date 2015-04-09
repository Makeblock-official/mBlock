#ifndef MeInfraredReceiver_H_
#define MeInfraredReceiver_H_
#include "MePort.h"

//NEC Code table
#define IR_BUTTON_POWER 	0x45
#define IR_BUTTON_A 		0x45
#define IR_BUTTON_B 		0x46
#define IR_BUTTON_MENU 		0x47
#define IR_BUTTON_C 		0x47
#define IR_BUTTON_TEST 		0x44
#define IR_BUTTON_D 		0x44
#define IR_BUTTON_PLUS 		0x40
#define IR_BUTTON_UP 		0x40
#define IR_BUTTON_RETURN 	0x43
#define IR_BUTTON_E 		0x43
#define IR_BUTTON_PREVIOUS 	0x07
#define IR_BUTTON_LEFT 		0x07
#define IR_BUTTON_PLAY 		0x15
#define IR_BUTTON_SETTING 	0x15
#define IR_BUTTON_NEXT 		0x09
#define IR_BUTTON_RIGHT 	0x09
#define IR_BUTTON_MINUS 	0x19
#define IR_BUTTON_DOWN 		0x19
#define IR_BUTTON_CLR 		0x0D
#define IR_BUTTON_F 		0x0D
#define IR_BUTTON_0 		0x16
#define IR_BUTTON_1 		0x0C
#define IR_BUTTON_2 		0x18
#define IR_BUTTON_3 		0x5E
#define IR_BUTTON_4 		0x08
#define IR_BUTTON_5 		0x1C
#define IR_BUTTON_6 		0x5A
#define IR_BUTTON_7 		0x42
#define IR_BUTTON_8 		0x52
#define IR_BUTTON_9 		0x4A

class MeInfraredReceiver:public MePort{
	public :
		MeInfraredReceiver();
		MeInfraredReceiver(uint8_t port);
		int available();
		unsigned char read();
		unsigned char poll();
		bool buttonState();
	private:
		unsigned char _buffer; 
};
#endif
