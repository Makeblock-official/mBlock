#ifndef MeInfraredReceiver_H_
#define MeInfraredReceiver_H_
#include "MePort.h"
class MeInfraredReceiver:public MePort{
	public :
		MeInfraredReceiver();
		MeInfraredReceiver(uint8_t port);
		int available();
		unsigned char read();
		unsigned char getCode();
		unsigned char poll();
		bool buttonState();
		void loop();
	private:
		unsigned char _irCode;
		unsigned char _buffer; 
};
#endif
