
#ifndef MEULTRASONIC_H_
#define MEULTRASONIC_H_
#include "MePort.h"
///@brief Class for Ultrasonic Sensor Module
class MeUltrasonic: public MePort
{
	public:
		MeUltrasonic();
		//MeUltrasonic(uint8_t pin);
	    MeUltrasonic(uint8_t port);
	    double distanceCm();
	    double distanceInch();
	    double distanceCm(uint16_t maxCm);
	    double distanceInch(uint16_t maxInch);
	    long measure(unsigned long timeout);
	private:
		uint8_t _pin;
};
#endif
