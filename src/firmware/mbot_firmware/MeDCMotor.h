#ifndef MEDCMOTOR_H_
#define MEDCMOTOR_H_
#include "MePort.h"
///@brief Class for DC Motor Module
class MeDCMotor: public MePort
{
	public:
            MeDCMotor();
	    MeDCMotor(MEPORT port);
	    MeDCMotor(uint8_t pwmPin,uint8_t dirPin);
	    void run(int speed);
	    void stop();
	private:
		uint8_t _dirPin;
		uint8_t _pwmPin;
};
#endif
