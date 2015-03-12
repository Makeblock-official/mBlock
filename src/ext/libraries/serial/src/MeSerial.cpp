#include "MeSerial.h"
MeSerial::MeSerial(){
	
}
boolean MeSerial::dataLineAvailable(){
	if(Serial.available()){
		char c = Serial.read();
		if(c=='\n'){
			buffer[bufferIndex] = 0;
			return true;
		}else{
			buffer[bufferIndex]=c;
			bufferIndex++;
		}
	}
	return false;
}
String MeSerial::readDataLine(){
	if(bufferIndex>0){
		lastLine = buffer;
	}
	bufferIndex = 0;
	memset(buffer,0,64);
	return lastLine;
}
float MeSerial::getValue(String key){
	String s = readDataLine();
	if(stringLength(s)>2){
		char * tmp;
		char * str;
		str = strtok_r((char*)s.c_str(), "=", &tmp);
		if(str!=NULL && strcmp(str,key.c_str())==0){
		  float v = atof(tmp);
		  return v;
		}
	}
	return 0;
}
boolean MeSerial::equalString(String s1,String s2){
	return s1.equals(s2);
}
String MeSerial::concatenateWith(String s1,String s2){
	return s1+s2;
}
char MeSerial::letterOf(int i,String s){
	return s.charAt(i);
}
int MeSerial::stringLength(String s){
	return s.length();
}