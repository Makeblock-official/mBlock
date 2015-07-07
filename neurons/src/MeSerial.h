#ifndef MeSerial_H_
#define MeSerial_H_

#include <Arduino.h>
class MeSerial
{
public:
	MeSerial();
	boolean dataLineAvailable();
	String readDataLine();
	String concatenateWith(String s1,String s2);
	char letterOf(int i,String s);
	int stringLength(String s);
	boolean equalString(String s1,String s2);
	float getValue(String key);
protected:
	char buffer[64];
	String lastLine;
	int bufferIndex;
};
#endif