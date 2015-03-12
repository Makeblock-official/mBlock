#ifndef MESERVO_H_
#define MESERVO_H_
#include <Arduino.h>
#include <Servo.h>
#include "MePort.h"
class MeServo : public MePort{
 public:
  MeServo();
  MeServo(uint8_t port);
  MeServo(uint8_t port,uint8_t slot);
  void reset(uint8_t port,uint8_t slot);
  void attach(int pin);
  void detach(int pin);
  boolean attached();
  void write(int pin,uint8_t a);
  void refresh(void);
  int indexOfServo(int pin);
 private:
  boolean isAttached;
  int angle,servoPin;
  uint16_t delayTime;
  unsigned long mTime;
  int pinState;
  int pins[8];
  int _index;
  Servo servos[8];
};
#endif
