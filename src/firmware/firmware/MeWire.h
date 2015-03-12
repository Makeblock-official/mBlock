
#ifndef _I2CDEV_H_
#define _I2CDEV_H_

// -----------------------------------------------------------------------------
// I2C interface implementation setting
// -----------------------------------------------------------------------------
//#define I2CDEV_IMPLEMENTATION       I2CDEV_ARDUINO_WIRE
#define I2CDEV_IMPLEMENTATION       I2CDEV_BUILTIN_FASTWIRE

// comment this out if you are using a non-optimal IDE/implementation setting
// but want the compiler to shut up about it
#define I2CDEV_IMPLEMENTATION_WARNINGS

// -----------------------------------------------------------------------------
// I2C interface implementation options
// -----------------------------------------------------------------------------
#define I2CDEV_ARDUINO_WIRE         1 // Wire object from Arduino
#define I2CDEV_BUILTIN_NBWIRE       2 // Tweaked Wire object from Gene Knight's NBWire project
                                      // ^^^ NBWire implementation is still buggy w/some interrupts!
#define I2CDEV_BUILTIN_FASTWIRE     3 // FastWire object from Francesco Ferrara's project
#define I2CDEV_I2CMASTER_LIBRARY    4 // I2C object from DSSCircuits I2C-Master Library at https://github.com/DSSCircuits/I2C-Master-Library

// -----------------------------------------------------------------------------
// Arduino-style "Serial.print" debug constant (uncomment to enable)
// -----------------------------------------------------------------------------
//#define I2CDEV_SERIAL_DEBUG

#ifdef ARDUINO
    #if ARDUINO < 100
        #include "WProgram.h"
    #else
        #include "Arduino.h"
    #endif
    #if I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE
        #include <Wire.h>
    #endif
    #if I2CDEV_IMPLEMENTATION == I2CDEV_I2CMASTER_LIBRARY
        #include <I2C.h>
    #endif
#endif

// 1000ms default read timeout (modify with "I2Cdev::readTimeout = [ms];")
#define I2CDEV_DEFAULT_READ_TIMEOUT     1000

class I2Cdev {
    public:
        I2Cdev();
        
        static int8_t readBit(uint8_t devAddr, uint8_t regAddr, uint8_t bitNum, uint8_t *data, uint16_t timeout=I2Cdev::readTimeout);
        static int8_t readBitW(uint8_t devAddr, uint8_t regAddr, uint8_t bitNum, uint16_t *data, uint16_t timeout=I2Cdev::readTimeout);
        static int8_t readBits(uint8_t devAddr, uint8_t regAddr, uint8_t bitStart, uint8_t length, uint8_t *data, uint16_t timeout=I2Cdev::readTimeout);
        static int8_t readBitsW(uint8_t devAddr, uint8_t regAddr, uint8_t bitStart, uint8_t length, uint16_t *data, uint16_t timeout=I2Cdev::readTimeout);
        static int8_t readByte(uint8_t devAddr, uint8_t regAddr, uint8_t *data, uint16_t timeout=I2Cdev::readTimeout);
        static int8_t readWord(uint8_t devAddr, uint8_t regAddr, uint16_t *data, uint16_t timeout=I2Cdev::readTimeout);
        static int8_t readBytes(uint8_t devAddr, uint8_t regAddr, uint8_t length, uint8_t *data, uint16_t timeout=I2Cdev::readTimeout);
        static int8_t readWords(uint8_t devAddr, uint8_t regAddr, uint8_t length, uint16_t *data, uint16_t timeout=I2Cdev::readTimeout);

        static bool writeBit(uint8_t devAddr, uint8_t regAddr, uint8_t bitNum, uint8_t data);
        static bool writeBitW(uint8_t devAddr, uint8_t regAddr, uint8_t bitNum, uint16_t data);
        static bool writeBits(uint8_t devAddr, uint8_t regAddr, uint8_t bitStart, uint8_t length, uint8_t data);
        static bool writeBitsW(uint8_t devAddr, uint8_t regAddr, uint8_t bitStart, uint8_t length, uint16_t data);
        static bool writeByte(uint8_t devAddr, uint8_t regAddr, uint8_t data);
        static bool writeWord(uint8_t devAddr, uint8_t regAddr, uint16_t data);
        static bool writeBytes(uint8_t devAddr, uint8_t regAddr, uint8_t length, uint8_t *data);
        static bool writeWords(uint8_t devAddr, uint8_t regAddr, uint8_t length, uint16_t *data);

        static uint16_t readTimeout;
};

    //////////////////////
    // FastWire 0.24
    // This is a library to help faster programs to read I2C devices.
    // Copyright(C) 2012
    // Francesco Ferrara
    //////////////////////
    
    /* Master */
    #define TW_START                0x08
    #define TW_REP_START            0x10

    /* Master Transmitter */
    #define TW_MT_SLA_ACK           0x18
    #define TW_MT_SLA_NACK          0x20
    #define TW_MT_DATA_ACK          0x28
    #define TW_MT_DATA_NACK         0x30
    #define TW_MT_ARB_LOST          0x38

    /* Master Receiver */
    #define TW_MR_ARB_LOST          0x38
    #define TW_MR_SLA_ACK           0x40
    #define TW_MR_SLA_NACK          0x48
    #define TW_MR_DATA_ACK          0x50
    #define TW_MR_DATA_NACK         0x58

    #define TW_OK                   0
    #define TW_ERROR                1

    class Fastwire {
        private:
            static boolean waitInt();

        public:
            static void setup(int khz, boolean pullup);
            static byte beginTransmission(byte device);
            static byte write(byte value);
            static byte writeBuf(byte device, byte address, byte *data, byte num);
            static byte readBuf(byte device, byte address, byte *data, byte num);
            static void reset();
            static byte stop();
    };


#endif /* _I2CDEV_H_ */
