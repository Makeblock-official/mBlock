#include "MeGyro.h"
static uint8_t buffers[14];
static float angleX=0;
static float angleY=0;
static float angleZ=0;
MeGyro::MeGyro(){
  
}
void MeGyro::begin(){ 
	gSensitivity = 65.5; // for 500 deg/s, check data sheet
	gx = 0;
	gy = 0;
	gz = 0;
	gyrX = 0;
	gyrY = 0;
	gyrZ = 0;
	accX = 0;
	accY = 0;
	accZ = 0;
	gyrXoffs = -281.00;
	gyrYoffs = 18.00;
	gyrZoffs = -83.00;
	FREQ=30.0;
  Wire.begin();
	delay(1000);
      
}
int MeGyro::start(){
  
	int error = writeReg (0x6b, 0x00);
	error += writeReg (0x1a, 0x01);
	error += writeReg(0x1b, 0x08);
	uint8_t sample_div = 1000 / FREQ - 1;
	error +=writeReg (0x19, sample_div);
 return error;
}
double MeGyro::getAngleX(){
	if(accZ==0)return 0;
	return (atan((float)accX/(float)accZ))*180/3.1415926;
} 
double MeGyro::getAngleY(){
	if(accZ==0)return 0;
	return (atan((float)accY/(float)accZ))*180/3.1415926;
} 
double MeGyro::getAngleZ(){
	if(gyrZ==0)return 0;
	return gyrZ/10.0;
} 
void MeGyro::close(){
}
void MeGyro::update(){
  unsigned long start_time = millis();
  uint8_t error;
  // read imu data
  if(start()!=0){
   return; 
  }
  error = readData(0x3b, i2cData, 14);
  if(error!=0){
   
    return;
  }

  double ax, ay, az;
  // assemble 16 bit sensor data
  accX = ((i2cData[0] << 8) | i2cData[1]);
  accY = ((i2cData[2] << 8) | i2cData[3]);
  accZ = ((i2cData[4] << 8) | i2cData[5]);

  gyrX = (((i2cData[8] << 8) | i2cData[9]) - gyrXoffs) / gSensitivity;
  gyrY = (((i2cData[10] << 8) | i2cData[11]) - gyrYoffs) / gSensitivity;
  gyrZ = (((i2cData[12] << 8) | i2cData[13]) - gyrZoffs) / (gSensitivity+1);
  ay = atan2(accX, sqrt( pow(accY, 2) + pow(accZ, 2))) * 180 / M_PI;
  ax = atan2(accY, sqrt( pow(accX, 2) + pow(accZ, 2))) * 180 / M_PI;

  // angles based on gyro (deg/s)
  gx = gx + gyrX / FREQ;
  gy = gy - gyrY / FREQ;
  gz += gyrZ / FREQ;

  // complementary filter
  // tau = DT*(A)/(1-A)
  // = 0.48sec
  gx = gx * 0.96 + ax * 0.04;
  gy = gy * 0.96 + ay * 0.04;

  //delay(((1/FREQ) * 1000) - (millis() - start_time)-time);
}
int MeGyro::readData(int start, uint8_t *buffer, int size)
{
	int i, n, error;
	Wire.beginTransmission(0x68);
	n = Wire.write(start);
	if (n != 1)
	return (-10);
	n = Wire.endTransmission(false);    // hold the I2C-bus
	if (n != 0)
	return (n);
	delayMicroseconds(1);
	// Third parameter is true: relase I2C-bus after data is read.
	Wire.requestFrom(0x68, size, true);
	i = 0;
	while(Wire.available() && i<size)
	{
	buffer[i++]=Wire.read();
	}
	delayMicroseconds(1);
	if ( i != size)
	return (-11);
	return (0);  // return : no error
}
int MeGyro::writeData(int start, const uint8_t *pData, int size)
{
  int n, error;
  Wire.beginTransmission(0x68);
  n = Wire.write(start);        // write the start address
  if (n != 1)
  return (-20);
  n = Wire.write(pData, size);  // write data bytes
  if (n != size)
  return (-21);
  error = Wire.endTransmission(true); // release the I2C-bus
  if (error != 0)
  return (error);
  return (0);         // return : no error
}
int MeGyro::writeReg(int reg, uint8_t data)
{
  int error;
  error = writeData(reg, &data, 1);
  return (error);
}
