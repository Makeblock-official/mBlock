#include "MeDCMotor.h"
 MeDCMotor::MeDCMotor(): MePort(0)
 {

 }
MeDCMotor::MeDCMotor(uint8_t port): MePort(port)
{
    pinMode(_dirPin,OUTPUT);
}

MeDCMotor::MeDCMotor(uint8_t pwmPin,uint8_t dirPin)
{  
    s1 = pwmPin;
    s2 = dirPin;
    pinMode(s2,OUTPUT);
}
void MeDCMotor::run(int speed)
{
    speed = speed > 255 ? 255 : speed;
    speed = speed < -255 ? -255 : speed;
    // constrain(speed,-255,255);
    if(speed >= 0) {
      pinMode(s1,OUTPUT);
      pinMode(s2,OUTPUT);
        digitalWrite(s2,HIGH);
        analogWrite(s1,speed);
        // MePort::dWrite2(HIGH);
        // MePort::aWrite1(speed);
    } else {
      pinMode(s1,OUTPUT);
      pinMode(s2,OUTPUT);
        digitalWrite(s2,LOW);
        analogWrite(s1,-speed);
        // MePort::dWrite2(LOW);
        // MePort::aWrite1(-speed);
    }
}
void MeDCMotor::move(int direction, int speed){
	int leftSpeed = 0;
	int rightSpeed = 0;
	if(direction==1){
		leftSpeed = speed;
		rightSpeed = -speed;
	}else if(direction==2){
		leftSpeed = -speed;
		rightSpeed = speed;
	}else if(direction==3){
		leftSpeed = speed;
		rightSpeed = speed;
	}else if(direction==4){
		leftSpeed = -speed;
		rightSpeed = -speed;
	}
	reset(M1);
	run(leftSpeed);
	reset(M2);
	run(rightSpeed);
}
void MeDCMotor::stop()
{
    MeDCMotor::run(0);
}
