#ifndef MeTemperature_h
#define MeTemperature_h 
#include "MePort.h"
#include "Me1Wire.h"

///@brief Class for temperature sensor
class MeTemperature:public MePort{
	public:
		MeTemperature();
		MeTemperature(uint8_t port);
//		MeTemperature(uint8_t pin);
		MeTemperature(uint8_t port,uint8_t slot);
		void reset(uint8_t port, uint8_t slot);
		///@brief get the celsius of temperature
		float temperature();
	private:
		Me1Wire _ts;	
}; 
#endif
