#include "MeInfraredReceiver.h"

MeInfraredReceiver::MeInfraredReceiver():MePort(){

}

MeInfraredReceiver::MeInfraredReceiver(uint8_t port):MePort(port){
	pinMode(s1,INPUT);
	pinMode(s2,INPUT);
}
int MeInfraredReceiver::available(){
	char c = poll();
	if(c>0){
		_buffer = c;
		return 1;
	}	
	return 0;	
}
unsigned char MeInfraredReceiver::read(){
  unsigned char c = _buffer;
  _buffer = 0;
  return c;
}
		
bool MeInfraredReceiver::buttonState(){
  
  if(getPort()>0){
	return dRead1()==0;
  }
  return 0;
}
unsigned char MeInfraredReceiver::poll()
{
    //noInterrupts();
    unsigned char val = 0;
    int bitDelay = 1000000.0/9600.0 - clockCyclesToMicroseconds(50);
    if (digitalRead(s2) == LOW) {
        for(int offset=0;offset<8;offset++){    
            delayMicroseconds(bitDelay);
            val |= digitalRead(s2) << offset;
        }
        delayMicroseconds(bitDelay);
        //interrupts();
        return val&0xff;
    }
    //interrupts();
    return 0;
}
