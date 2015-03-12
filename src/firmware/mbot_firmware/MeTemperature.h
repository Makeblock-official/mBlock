#ifndef MeTemperature_h
#define MeTemperature_h 
#include "MePort.h"
#include "MeOneWire.h"

///@brief Class for temperature sensor
class MeTemperature:public MePort{
	public:
		MeTemperature();
		MeTemperature(MEPORT port);
		MeTemperature(uint8_t pin);
		MeTemperature(MEPORT port,uint8_t slot);
		void reset(uint8_t port, uint8_t slot);
		///@brief get the celsius of temperature
		float temperature();
	private:
		MeOneWire _ts;	
}; 
#endif
