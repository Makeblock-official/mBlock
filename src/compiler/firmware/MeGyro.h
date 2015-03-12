#ifndef MEGYRO_H_
#define MEGYRO_H_
#include <Arduino.h>
#include <Wire.h>
class MeGyro{
  public:
		MeGyro();
		void begin();
		void update();
		double getAngleX();
		double getAngleY();
		double getAngleZ();
		void close();
	private:
		int readData(int start, uint8_t *buffer, int size);
		int writeData(int start, const uint8_t *pData, int size);
		int writeReg(int reg, uint8_t data);
		int start();
		double gSensitivity; // for 500 deg/s, check data sheet
		double gx, gy, gz;
		double gyrX, gyrY, gyrZ;
		int16_t accX, accY, accZ;
		double gyrXoffs, gyrYoffs, gyrZoffs;
		double FREQ;
		uint8_t i2cData[14];
};
#endif
