#include "MeServo.h"
 
MeServo::MeServo() {
  isAttached = false;
  servoPin = 0;
  angle = 90;
  mTime = micros();
  pinState = false;
  _index=0;
  
}
MeServo::MeServo(uint8_t port): MePort(port)
{
  attach(s1);
}
MeServo::MeServo(uint8_t port,uint8_t slot): MePort(port,slot)
{
  attach(slot==SLOT_1?s1:s2);
}
void MeServo::reset(uint8_t port,uint8_t slot){
        //detach();
        _port = port;
        _slot = slot;
	s2 = mePort[port].s2;
	s1 = mePort[port].s1;
        servoPin = slot==SLOT_1?s1:s2;
        attach(servoPin);
}
void MeServo::attach(int pin) {
  if(indexOfServo(pin)==-1&&_index<8){
    pins[_index]=pin;
    _index++;
  }
  if(indexOfServo(pin)>-1){
    isAttached = true;
    pinMode(pin, OUTPUT);
    if(!servos[indexOfServo(pin)].attached()){
      servos[indexOfServo(pin)].attach(pin);
    }
  }
}
int MeServo::indexOfServo(int pin){
  for(int i=0;i<8;i++){
   if(pin==pins[i]){
    return i;
   } 
  }
 return -1; 
}
void MeServo::detach(int pin) {
  isAttached = false;
//  pinMode(servoPin, INPUT);
  if(indexOfServo(pin)>-1){
    pins[indexOfServo(pin)]=-1;
    if(servos[indexOfServo(pin)].attached()){
      servos[indexOfServo(pin)].detach();
    }
  }
}

boolean  MeServo::attached(void) {
  return isAttached;
}

void MeServo::write(int pin,uint8_t a) {
  angle = a;
  if(indexOfServo(pin)>-1){
    servos[indexOfServo(pin)].write(a);
  }
}

void MeServo::refresh(void) {
//  if(isAttached){
//    digitalWrite(servoPin, HIGH); 
//    delayMicroseconds(delayTime);
//    digitalWrite(servoPin, LOW);
//  }
}
