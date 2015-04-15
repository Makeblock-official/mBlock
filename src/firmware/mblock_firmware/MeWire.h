#ifndef MeWire_h
#define MeWire_h
#include "Wire.h"
#include "MePort.h"
//Wire Setup
#define BEGIN_FLAG  		0x1E
#define BEGIN_STATE  		0x91
///@brief class of MeWire
class MeWire: public MePort
{
public:
    MeWire(uint8_t address);
    ///@brief initialize
    ///@param port port number of device
    MeWire(uint8_t port, uint8_t address);
    ///@brief reset start index of i2c slave address.
    void setI2CBaseAddress(uint8_t baseAddress);
    bool isRunning();
    ///@brief Initiate the Wire library and join the I2C bus as a master or slave. This should normally be called only once.
    ///@param address the 7-bit slave address (optional); if not specified, join the bus as a master.
    void begin();
    ///@brief send one byte data request for read one byte from slave address.
    byte read(byte dataAddress);
    void read(byte dataAddress, uint8_t *buf, int len);
    ///@brief send one byte data request for write one byte to slave address.
    void write(byte dataAddress, byte data);
    void request(byte *writeData, byte *readData, int wlen, int rlen);
protected:
    int _slaveAddress;
};
#endif
