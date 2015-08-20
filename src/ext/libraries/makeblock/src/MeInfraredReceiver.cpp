#include "MeInfraredReceiver.h"

MeInfraredReceiver::MeInfraredReceiver():SoftwareSerial(0,1){
        _port = 0;
}

MeInfraredReceiver::MeInfraredReceiver(uint8_t port):SoftwareSerial(mePort[port].s2,0){
        _port = port;
	pinMode(mePort[port].s1,INPUT);
}
		
bool MeInfraredReceiver::buttonState(){
  if(_port>0){
	return digitalRead(mePort[_port].s1)==0;
  }
  return 0;
}
uint8_t MeInfraredReceiver::getPort(){
   return _port; 
}
uint8_t MeInfraredReceiver::getCode(){
	if(available()){
    int r = read();
    if(r<0xff){
      return r;
    }else{
      return read();
    }
	}
	return 0;
}
