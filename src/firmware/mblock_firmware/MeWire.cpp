#include "MeWire.h"
/*             Wire               */
MeWire::MeWire(uint8_t address): MePort()
{
    _slaveAddress = address + 1;
}
MeWire::MeWire(uint8_t port, uint8_t address): MePort(port)
{
    _slaveAddress = address + 1;
}
void MeWire::begin()
{
    delay(1000);
    Wire.begin();
    write(BEGIN_FLAG, 0x01);
}
bool MeWire::isRunning()
{
    return read(BEGIN_STATE);
}
void MeWire::setI2CBaseAddress(uint8_t baseAddress)
{
    byte w[2] = {0};
    byte r[4] = {0};
    w[0] = 0x21;
    w[1] = baseAddress;
    request(w, r, 2, 4);
}

byte MeWire::read(byte dataAddress)
{
    byte *b = {0};
    read(dataAddress, b, 1);
    return b[0];
}

void MeWire::read(byte dataAddress, uint8_t *buf, int len)
{
    byte rxByte;
    Wire.beginTransmission(_slaveAddress); // transmit to device
    Wire.write(dataAddress); // sends one byte
    Wire.endTransmission(); // stop transmitting
    delayMicroseconds(1);
    Wire.requestFrom(_slaveAddress, len); // request 6 bytes from slave device
    int index = 0;
    while(Wire.available()) // slave may send less than requested
    {
        rxByte = Wire.read(); // receive a byte as character
        buf[index] = rxByte;
        index++;
    }
}

void MeWire::write(byte dataAddress, byte data)
{
    Wire.beginTransmission(_slaveAddress); // transmit to device
    Wire.write(dataAddress); // sends one byte
    Wire.endTransmission(); // stop transmitting

    Wire.beginTransmission(_slaveAddress); // transmit to device
    Wire.write(data); // sends one byte
    Wire.endTransmission(); // stop transmitting
}
void MeWire::request(byte *writeData, byte *readData, int wlen, int rlen)
{

    uint8_t rxByte;
    uint8_t index = 0;

    Wire.beginTransmission(_slaveAddress); // transmit to device

    Wire.write(writeData, wlen);

    Wire.endTransmission();
    delayMicroseconds(2);
    Wire.requestFrom(_slaveAddress, rlen); // request 6 bytes from slave device
    delayMicroseconds(2);
    while(Wire.available()) // slave may send less than requested
    {
        rxByte = Wire.read(); // receive a byte as character

        readData[index] = rxByte;
        index++;
    }
}
