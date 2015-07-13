#include "MeTemperature.h"

// DS18B20 commands
#define STARTCONVO 0x44 // Tells device to take a temperature reading and put it on the scratchpad
#define COPYSCRATCH 0x48 // Copy EEPROM
#define READSCRATCH 0xBE // Read EEPROM
#define WRITESCRATCH 0x4E // Write to EEPROM
#define RECALLSCRATCH 0xB8 // Reload from last known
#define READPOWERSUPPLY 0xB4 // Determine if device needs parasite power
#define ALARMSEARCH 0xEC // Query bus for devices with an alarm condition

MeTemperature::MeTemperature():MePort(){
}
MeTemperature::MeTemperature(uint8_t port):MePort(port){
	
}
/*MeTemperature::MeTemperature(uint8_t pin){
	_ts.reset(pin);
}*/
MeTemperature::MeTemperature(uint8_t port,uint8_t slot):MePort(port){
	MePort::reset(port, slot);
	_ts.reset( slot == SLOT_2 ? s2 : s1);
}
void MeTemperature::reset(uint8_t port,uint8_t slot){
	MePort::reset(port, slot);
	_ts.reset( slot == SLOT_2 ? s2 : s1);
}
float MeTemperature::temperature(){
	byte i;
	byte present = 0;
	byte type_s;
	byte data[12];
	// byte addr[8];
	float celsius;
	long time;
	_ts.reset();
	_ts.skip();
	_ts.write(STARTCONVO); // start conversion, with parasite power on at the end
	time = millis();
	while(!_ts.readIO() && (millis()-time)<750);
	present = _ts.reset();
	_ts.skip();
	_ts.write(READSCRATCH);
	for ( i = 0; i < 5; i++) { // we need 9 bytes
		data[i] = _ts.read();
	}
	int16_t rawTemperature = (data[1] << 8) | data[0];
	return (float)rawTemperature * 0.0625;// 12 bit
}
