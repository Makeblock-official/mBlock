
#ifndef MEULTRASONIC_H_
#define MEULTRASONIC_H_
#include "MePort.h"
///@brief Class for Ultrasonic Sensor Module
class MeUltrasonic: public MePort
{
public :
	MeUltrasonic();
    MeUltrasonic(uint8_t port);
    long distanceCm();
    long distanceInch();
    long measure();
};
#endif
