#ifndef MeInfraredReceiver_H_
#define MeInfraredReceiver_H_
#include "MePort.h"
#include <SoftwareSerial.h>
class MeInfraredReceiver:public SoftwareSerial{
	public :
		MeInfraredReceiver();
		MeInfraredReceiver(uint8_t port);
		bool buttonState();
        uint8_t getPort();
		uint8_t getCode();
	private:
                uint8_t _port;
};
#endif
