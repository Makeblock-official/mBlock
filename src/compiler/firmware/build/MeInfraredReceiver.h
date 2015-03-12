#ifndef MeInfraredReceiver_H_
#define MeInfraredReceiver_H_
#include "MePort.h"
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
