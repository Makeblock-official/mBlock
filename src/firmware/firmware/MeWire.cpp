

#include "MeWire.h"

#if I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE

    #ifdef I2CDEV_IMPLEMENTATION_WARNINGS
        #if ARDUINO < 100
            #warning Using outdated Arduino IDE with Wire library is functionally limiting.
            #warning Arduino IDE v1.0.1+ with I2Cdev Fastwire implementation is recommended.
            #warning This I2Cdev implementation does not support:
            #warning - Repeated starts conditions
            #warning - Timeout detection (some Wire requests block forever)
        #elif ARDUINO == 100
            #warning Using outdated Arduino IDE with Wire library is functionally limiting.
            #warning Arduino IDE v1.0.1+ with I2Cdev Fastwire implementation is recommended.
            #warning This I2Cdev implementation does not support:
            #warning - Repeated starts conditions
            #warning - Timeout detection (some Wire requests block forever)
        #elif ARDUINO > 100
            #warning Using current Arduino IDE with Wire library is functionally limiting.
            #warning Arduino IDE v1.0.1+ with I2CDEV_BUILTIN_FASTWIRE implementation is recommended.
            #warning This I2Cdev implementation does not support:
            #warning - Timeout detection (some Wire requests block forever)
        #endif
    #endif

#elif I2CDEV_IMPLEMENTATION == I2CDEV_BUILTIN_FASTWIRE

    //#error The I2CDEV_BUILTIN_FASTWIRE implementation is known to be broken right now. Patience, Iago!


#endif

/** Default constructor.
 */
I2Cdev::I2Cdev() {
}

/** Read a single bit from an 8-bit device register.
 * @param devAddr I2C slave device address
 * @param regAddr Register regAddr to read from
 * @param bitNum Bit position to read (0-7)
 * @param data Container for single bit value
 * @param timeout Optional read timeout in milliseconds (0 to disable, leave off to use default class value in I2Cdev::readTimeout)
 * @return Status of read operation (true = success)
 */
int8_t I2Cdev::readBit(uint8_t devAddr, uint8_t regAddr, uint8_t bitNum, uint8_t *data, uint16_t timeout) {
    uint8_t b;
    uint8_t count = readByte(devAddr, regAddr, &b, timeout);
    *data = b & (1 << bitNum);
    return count;
}

/** Read a single bit from a 16-bit device register.
 * @param devAddr I2C slave device address
 * @param regAddr Register regAddr to read from
 * @param bitNum Bit position to read (0-15)
 * @param data Container for single bit value
 * @param timeout Optional read timeout in milliseconds (0 to disable, leave off to use default class value in I2Cdev::readTimeout)
 * @return Status of read operation (true = success)
 */
int8_t I2Cdev::readBitW(uint8_t devAddr, uint8_t regAddr, uint8_t bitNum, uint16_t *data, uint16_t timeout) {
    uint16_t b;
    uint8_t count = readWord(devAddr, regAddr, &b, timeout);
    *data = b & (1 << bitNum);
    return count;
}

/** Read multiple bits from an 8-bit device register.
 * @param devAddr I2C slave device address
 * @param regAddr Register regAddr to read from
 * @param bitStart First bit position to read (0-7)
 * @param length Number of bits to read (not more than 8)
 * @param data Container for right-aligned value (i.e. '101' read from any bitStart position will equal 0x05)
 * @param timeout Optional read timeout in milliseconds (0 to disable, leave off to use default class value in I2Cdev::readTimeout)
 * @return Status of read operation (true = success)
 */
int8_t I2Cdev::readBits(uint8_t devAddr, uint8_t regAddr, uint8_t bitStart, uint8_t length, uint8_t *data, uint16_t timeout) {
    // 01101001 read byte
    // 76543210 bit numbers
    //    xxx   args: bitStart=4, length=3
    //    010   masked
    //   -> 010 shifted
    uint8_t count, b;
    if ((count = readByte(devAddr, regAddr, &b, timeout)) != 0) {
        uint8_t mask = ((1 << length) - 1) << (bitStart - length + 1);
        b &= mask;
        b >>= (bitStart - length + 1);
        *data = b;
    }
    return count;
}

/** Read multiple bits from a 16-bit device register.
 * @param devAddr I2C slave device address
 * @param regAddr Register regAddr to read from
 * @param bitStart First bit position to read (0-15)
 * @param length Number of bits to read (not more than 16)
 * @param data Container for right-aligned value (i.e. '101' read from any bitStart position will equal 0x05)
 * @param timeout Optional read timeout in milliseconds (0 to disable, leave off to use default class value in I2Cdev::readTimeout)
 * @return Status of read operation (1 = success, 0 = failure, -1 = timeout)
 */
int8_t I2Cdev::readBitsW(uint8_t devAddr, uint8_t regAddr, uint8_t bitStart, uint8_t length, uint16_t *data, uint16_t timeout) {
    // 1101011001101001 read byte
    // fedcba9876543210 bit numbers
    //    xxx           args: bitStart=12, length=3
    //    010           masked
    //           -> 010 shifted
    uint8_t count;
    uint16_t w;
    if ((count = readWord(devAddr, regAddr, &w, timeout)) != 0) {
        uint16_t mask = ((1 << length) - 1) << (bitStart - length + 1);
        w &= mask;
        w >>= (bitStart - length + 1);
        *data = w;
    }
    return count;
}

/** Read single byte from an 8-bit device register.
 * @param devAddr I2C slave device address
 * @param regAddr Register regAddr to read from
 * @param data Container for byte value read from device
 * @param timeout Optional read timeout in milliseconds (0 to disable, leave off to use default class value in I2Cdev::readTimeout)
 * @return Status of read operation (true = success)
 */
int8_t I2Cdev::readByte(uint8_t devAddr, uint8_t regAddr, uint8_t *data, uint16_t timeout) {
    return readBytes(devAddr, regAddr, 1, data, timeout);
}

/** Read single word from a 16-bit device register.
 * @param devAddr I2C slave device address
 * @param regAddr Register regAddr to read from
 * @param data Container for word value read from device
 * @param timeout Optional read timeout in milliseconds (0 to disable, leave off to use default class value in I2Cdev::readTimeout)
 * @return Status of read operation (true = success)
 */
int8_t I2Cdev::readWord(uint8_t devAddr, uint8_t regAddr, uint16_t *data, uint16_t timeout) {
    return readWords(devAddr, regAddr, 1, data, timeout);
}

/** Read multiple bytes from an 8-bit device register.
 * @param devAddr I2C slave device address
 * @param regAddr First register regAddr to read from
 * @param length Number of bytes to read
 * @param data Buffer to store read data in
 * @param timeout Optional read timeout in milliseconds (0 to disable, leave off to use default class value in I2Cdev::readTimeout)
 * @return Number of bytes read (-1 indicates failure)
 */
int8_t I2Cdev::readBytes(uint8_t devAddr, uint8_t regAddr, uint8_t length, uint8_t *data, uint16_t timeout) {
    #ifdef I2CDEV_SERIAL_DEBUG
        Serial.print("I2C (0x");
        Serial.print(devAddr, HEX);
        Serial.print(") reading ");
        Serial.print(length, DEC);
        Serial.print(" bytes from 0x");
        Serial.print(regAddr, HEX);
        Serial.print("...");
    #endif

    int8_t count = 0;
    uint32_t t1 = millis();

    #if (I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE)

        #if (ARDUINO < 100)
            // Arduino v00xx (before v1.0), Wire library

            // I2C/TWI subsystem uses internal buffer that breaks with large data requests
            // so if user requests more than BUFFER_LENGTH bytes, we have to do it in
            // smaller chunks instead of all at once
            for (uint8_t k = 0; k < length; k += min(length, BUFFER_LENGTH)) {
                Wire.beginTransmission(devAddr);
                Wire.send(regAddr);
                Wire.endTransmission();
                Wire.beginTransmission(devAddr);
                Wire.requestFrom(devAddr, (uint8_t)min(length - k, BUFFER_LENGTH));

                for (; Wire.available() && (timeout == 0 || millis() - t1 < timeout); count++) {
                    data[count] = Wire.receive();
                    #ifdef I2CDEV_SERIAL_DEBUG
                        Serial.print(data[count], HEX);
                        if (count + 1 < length) Serial.print(" ");
                    #endif
                }

                Wire.endTransmission();
            }
        #elif (ARDUINO == 100)
            // Arduino v1.0.0, Wire library
            // Adds standardized write() and read() stream methods instead of send() and receive()

            // I2C/TWI subsystem uses internal buffer that breaks with large data requests
            // so if user requests more than BUFFER_LENGTH bytes, we have to do it in
            // smaller chunks instead of all at once
            for (uint8_t k = 0; k < length; k += min(length, BUFFER_LENGTH)) {
                Wire.beginTransmission(devAddr);
                Wire.write(regAddr);
                Wire.endTransmission();
                Wire.beginTransmission(devAddr);
                Wire.requestFrom(devAddr, (uint8_t)min(length - k, BUFFER_LENGTH));
        
                for (; Wire.available() && (timeout == 0 || millis() - t1 < timeout); count++) {
                    data[count] = Wire.read();
                    #ifdef I2CDEV_SERIAL_DEBUG
                        Serial.print(data[count], HEX);
                        if (count + 1 < length) Serial.print(" ");
                    #endif
                }
        
                Wire.endTransmission();
            }
        #elif (ARDUINO > 100)
            // Arduino v1.0.1+, Wire library
            // Adds official support for repeated start condition, yay!

            // I2C/TWI subsystem uses internal buffer that breaks with large data requests
            // so if user requests more than BUFFER_LENGTH bytes, we have to do it in
            // smaller chunks instead of all at once
            for (uint8_t k = 0; k < length; k += min(length, BUFFER_LENGTH)) {
                Wire.beginTransmission(devAddr);
                Wire.write(regAddr);
                Wire.endTransmission();
                Wire.beginTransmission(devAddr);
                Wire.requestFrom(devAddr, (uint8_t)min(length - k, BUFFER_LENGTH));
        
                for (; Wire.available() && (timeout == 0 || millis() - t1 < timeout); count++) {
                    data[count] = Wire.read();
                    #ifdef I2CDEV_SERIAL_DEBUG
                        Serial.print(data[count], HEX);
                        if (count + 1 < length) Serial.print(" ");
                    #endif
                }
            }
        #endif

    #elif (I2CDEV_IMPLEMENTATION == I2CDEV_BUILTIN_FASTWIRE)

        // Fastwire library
        // no loop required for fastwire
        uint8_t status = Fastwire::readBuf(devAddr << 1, regAddr, data, length);
        if (status == 0) {
            count = length; // success
        } else {
            count = -1; // error
        }

    #endif

    // check for timeout
    if (timeout > 0 && millis() - t1 >= timeout && count < length) count = -1; // timeout

    #ifdef I2CDEV_SERIAL_DEBUG
        Serial.print(". Done (");
        Serial.print(count, DEC);
        Serial.println(" read).");
    #endif

    return count;
}

/** Read multiple words from a 16-bit device register.
 * @param devAddr I2C slave device address
 * @param regAddr First register regAddr to read from
 * @param length Number of words to read
 * @param data Buffer to store read data in
 * @param timeout Optional read timeout in milliseconds (0 to disable, leave off to use default class value in I2Cdev::readTimeout)
 * @return Number of words read (-1 indicates failure)
 */
int8_t I2Cdev::readWords(uint8_t devAddr, uint8_t regAddr, uint8_t length, uint16_t *data, uint16_t timeout) {
    #ifdef I2CDEV_SERIAL_DEBUG
        Serial.print("I2C (0x");
        Serial.print(devAddr, HEX);
        Serial.print(") reading ");
        Serial.print(length, DEC);
        Serial.print(" words from 0x");
        Serial.print(regAddr, HEX);
        Serial.print("...");
    #endif

    int8_t count = 0;
    uint32_t t1 = millis();

    #if (I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE)

        #if (ARDUINO < 100)
            // Arduino v00xx (before v1.0), Wire library

            // I2C/TWI subsystem uses internal buffer that breaks with large data requests
            // so if user requests more than BUFFER_LENGTH bytes, we have to do it in
            // smaller chunks instead of all at once
            for (uint8_t k = 0; k < length * 2; k += min(length * 2, BUFFER_LENGTH)) {
                Wire.beginTransmission(devAddr);
                Wire.send(regAddr);
                Wire.endTransmission();
                Wire.beginTransmission(devAddr);
                Wire.requestFrom(devAddr, (uint8_t)(length * 2)); // length=words, this wants bytes
    
                bool msb = true; // starts with MSB, then LSB
                for (; Wire.available() && count < length && (timeout == 0 || millis() - t1 < timeout);) {
                    if (msb) {
                        // first byte is bits 15-8 (MSb=15)
                        data[count] = Wire.receive() << 8;
                    } else {
                        // second byte is bits 7-0 (LSb=0)
                        data[count] |= Wire.receive();
                        #ifdef I2CDEV_SERIAL_DEBUG
                            Serial.print(data[count], HEX);
                            if (count + 1 < length) Serial.print(" ");
                        #endif
                        count++;
                    }
                    msb = !msb;
                }

                Wire.endTransmission();
            }
        #elif (ARDUINO == 100)
            // Arduino v1.0.0, Wire library
            // Adds standardized write() and read() stream methods instead of send() and receive()
    
            // I2C/TWI subsystem uses internal buffer that breaks with large data requests
            // so if user requests more than BUFFER_LENGTH bytes, we have to do it in
            // smaller chunks instead of all at once
            for (uint8_t k = 0; k < length * 2; k += min(length * 2, BUFFER_LENGTH)) {
                Wire.beginTransmission(devAddr);
                Wire.write(regAddr);
                Wire.endTransmission();
                Wire.beginTransmission(devAddr);
                Wire.requestFrom(devAddr, (uint8_t)(length * 2)); // length=words, this wants bytes
    
                bool msb = true; // starts with MSB, then LSB
                for (; Wire.available() && count < length && (timeout == 0 || millis() - t1 < timeout);) {
                    if (msb) {
                        // first byte is bits 15-8 (MSb=15)
                        data[count] = Wire.read() << 8;
                    } else {
                        // second byte is bits 7-0 (LSb=0)
                        data[count] |= Wire.read();
                        #ifdef I2CDEV_SERIAL_DEBUG
                            Serial.print(data[count], HEX);
                            if (count + 1 < length) Serial.print(" ");
                        #endif
                        count++;
                    }
                    msb = !msb;
                }
        
                Wire.endTransmission();
            }
        #elif (ARDUINO > 100)
            // Arduino v1.0.1+, Wire library
            // Adds official support for repeated start condition, yay!

            // I2C/TWI subsystem uses internal buffer that breaks with large data requests
            // so if user requests more than BUFFER_LENGTH bytes, we have to do it in
            // smaller chunks instead of all at once
            for (uint8_t k = 0; k < length * 2; k += min(length * 2, BUFFER_LENGTH)) {
                Wire.beginTransmission(devAddr);
                Wire.write(regAddr);
                Wire.endTransmission();
                Wire.beginTransmission(devAddr);
                Wire.requestFrom(devAddr, (uint8_t)(length * 2)); // length=words, this wants bytes
        
                bool msb = true; // starts with MSB, then LSB
                for (; Wire.available() && count < length && (timeout == 0 || millis() - t1 < timeout);) {
                    if (msb) {
                        // first byte is bits 15-8 (MSb=15)
                        data[count] = Wire.read() << 8;
                    } else {
                        // second byte is bits 7-0 (LSb=0)
                        data[count] |= Wire.read();
                        #ifdef I2CDEV_SERIAL_DEBUG
                            Serial.print(data[count], HEX);
                            if (count + 1 < length) Serial.print(" ");
                        #endif
                        count++;
                    }
                    msb = !msb;
                }
        
                Wire.endTransmission();
            }
        #endif

    #elif (I2CDEV_IMPLEMENTATION == I2CDEV_BUILTIN_FASTWIRE)

        // Fastwire library
        // no loop required for fastwire
        uint16_t intermediate[(uint8_t)length];
        uint8_t status = Fastwire::readBuf(devAddr << 1, regAddr, (uint8_t *)intermediate, (uint8_t)(length * 2));
        if (status == 0) {
            count = length; // success
            for (uint8_t i = 0; i < length; i++) {
                data[i] = (intermediate[2*i] << 8) | intermediate[2*i + 1];
            }
        } else {
            count = -1; // error
        }

    #endif

    if (timeout > 0 && millis() - t1 >= timeout && count < length) count = -1; // timeout

    #ifdef I2CDEV_SERIAL_DEBUG
        Serial.print(". Done (");
        Serial.print(count, DEC);
        Serial.println(" read).");
    #endif
    
    return count;
}

/** write a single bit in an 8-bit device register.
 * @param devAddr I2C slave device address
 * @param regAddr Register regAddr to write to
 * @param bitNum Bit position to write (0-7)
 * @param value New bit value to write
 * @return Status of operation (true = success)
 */
bool I2Cdev::writeBit(uint8_t devAddr, uint8_t regAddr, uint8_t bitNum, uint8_t data) {
    uint8_t b;
    readByte(devAddr, regAddr, &b);
    b = (data != 0) ? (b | (1 << bitNum)) : (b & ~(1 << bitNum));
    return writeByte(devAddr, regAddr, b);
}

/** write a single bit in a 16-bit device register.
 * @param devAddr I2C slave device address
 * @param regAddr Register regAddr to write to
 * @param bitNum Bit position to write (0-15)
 * @param value New bit value to write
 * @return Status of operation (true = success)
 */
bool I2Cdev::writeBitW(uint8_t devAddr, uint8_t regAddr, uint8_t bitNum, uint16_t data) {
    uint16_t w;
    readWord(devAddr, regAddr, &w);
    w = (data != 0) ? (w | (1 << bitNum)) : (w & ~(1 << bitNum));
    return writeWord(devAddr, regAddr, w);
}

/** Write multiple bits in an 8-bit device register.
 * @param devAddr I2C slave device address
 * @param regAddr Register regAddr to write to
 * @param bitStart First bit position to write (0-7)
 * @param length Number of bits to write (not more than 8)
 * @param data Right-aligned value to write
 * @return Status of operation (true = success)
 */
bool I2Cdev::writeBits(uint8_t devAddr, uint8_t regAddr, uint8_t bitStart, uint8_t length, uint8_t data) {
    //      010 value to write
    // 76543210 bit numbers
    //    xxx   args: bitStart=4, length=3
    // 00011100 mask byte
    // 10101111 original value (sample)
    // 10100011 original & ~mask
    // 10101011 masked | value
    uint8_t b;
    if (readByte(devAddr, regAddr, &b) != 0) {
        uint8_t mask = ((1 << length) - 1) << (bitStart - length + 1);
        data <<= (bitStart - length + 1); // shift data into correct position
        data &= mask; // zero all non-important bits in data
        b &= ~(mask); // zero all important bits in existing byte
        b |= data; // combine data with existing byte
        return writeByte(devAddr, regAddr, b);
    } else {
        return false;
    }
}

/** Write multiple bits in a 16-bit device register.
 * @param devAddr I2C slave device address
 * @param regAddr Register regAddr to write to
 * @param bitStart First bit position to write (0-15)
 * @param length Number of bits to write (not more than 16)
 * @param data Right-aligned value to write
 * @return Status of operation (true = success)
 */
bool I2Cdev::writeBitsW(uint8_t devAddr, uint8_t regAddr, uint8_t bitStart, uint8_t length, uint16_t data) {
    //              010 value to write
    // fedcba9876543210 bit numbers
    //    xxx           args: bitStart=12, length=3
    // 0001110000000000 mask word
    // 1010111110010110 original value (sample)
    // 1010001110010110 original & ~mask
    // 1010101110010110 masked | value
    uint16_t w;
    if (readWord(devAddr, regAddr, &w) != 0) {
        uint16_t mask = ((1 << length) - 1) << (bitStart - length + 1);
        data <<= (bitStart - length + 1); // shift data into correct position
        data &= mask; // zero all non-important bits in data
        w &= ~(mask); // zero all important bits in existing word
        w |= data; // combine data with existing word
        return writeWord(devAddr, regAddr, w);
    } else {
        return false;
    }
}

/** Write single byte to an 8-bit device register.
 * @param devAddr I2C slave device address
 * @param regAddr Register address to write to
 * @param data New byte value to write
 * @return Status of operation (true = success)
 */
bool I2Cdev::writeByte(uint8_t devAddr, uint8_t regAddr, uint8_t data) {
    return writeBytes(devAddr, regAddr, 1, &data);
}

/** Write single word to a 16-bit device register.
 * @param devAddr I2C slave device address
 * @param regAddr Register address to write to
 * @param data New word value to write
 * @return Status of operation (true = success)
 */
bool I2Cdev::writeWord(uint8_t devAddr, uint8_t regAddr, uint16_t data) {
    return writeWords(devAddr, regAddr, 1, &data);
}

/** Write multiple bytes to an 8-bit device register.
 * @param devAddr I2C slave device address
 * @param regAddr First register address to write to
 * @param length Number of bytes to write
 * @param data Buffer to copy new data from
 * @return Status of operation (true = success)
 */
bool I2Cdev::writeBytes(uint8_t devAddr, uint8_t regAddr, uint8_t length, uint8_t* data) {
    #ifdef I2CDEV_SERIAL_DEBUG
        Serial.print("I2C (0x");
        Serial.print(devAddr, HEX);
        Serial.print(") writing ");
        Serial.print(length, DEC);
        Serial.print(" bytes to 0x");
        Serial.print(regAddr, HEX);
        Serial.print("...");
    #endif
    uint8_t status = 0;
    #if ((I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE && ARDUINO < 100) || I2CDEV_IMPLEMENTATION == I2CDEV_BUILTIN_NBWIRE)
        Wire.beginTransmission(devAddr);
        Wire.send((uint8_t) regAddr); // send address
    #elif (I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE && ARDUINO >= 100)
        Wire.beginTransmission(devAddr);
        Wire.write((uint8_t) regAddr); // send address
    #elif (I2CDEV_IMPLEMENTATION == I2CDEV_BUILTIN_FASTWIRE)
        Fastwire::beginTransmission(devAddr);
        Fastwire::write(regAddr);
    #endif
    for (uint8_t i = 0; i < length; i++) {
        #ifdef I2CDEV_SERIAL_DEBUG
            Serial.print(data[i], HEX);
            if (i + 1 < length) Serial.print(" ");
        #endif
        #if ((I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE && ARDUINO < 100) || I2CDEV_IMPLEMENTATION == I2CDEV_BUILTIN_NBWIRE)
            Wire.send((uint8_t) data[i]);
        #elif (I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE && ARDUINO >= 100)
            Wire.write((uint8_t) data[i]);
        #elif (I2CDEV_IMPLEMENTATION == I2CDEV_BUILTIN_FASTWIRE)
            Fastwire::write((uint8_t) data[i]);
        #endif
    }
    #if ((I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE && ARDUINO < 100) || I2CDEV_IMPLEMENTATION == I2CDEV_BUILTIN_NBWIRE)
        Wire.endTransmission();
    #elif (I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE && ARDUINO >= 100)
        status = Wire.endTransmission();
    #elif (I2CDEV_IMPLEMENTATION == I2CDEV_BUILTIN_FASTWIRE)
        Fastwire::stop();
        //status = Fastwire::endTransmission();
    #endif
    #ifdef I2CDEV_SERIAL_DEBUG
        Serial.println(". Done.");
    #endif
    return status == 0;
}

/** Write multiple words to a 16-bit device register.
 * @param devAddr I2C slave device address
 * @param regAddr First register address to write to
 * @param length Number of words to write
 * @param data Buffer to copy new data from
 * @return Status of operation (true = success)
 */
bool I2Cdev::writeWords(uint8_t devAddr, uint8_t regAddr, uint8_t length, uint16_t* data) {
    #ifdef I2CDEV_SERIAL_DEBUG
        Serial.print("I2C (0x");
        Serial.print(devAddr, HEX);
        Serial.print(") writing ");
        Serial.print(length, DEC);
        Serial.print(" words to 0x");
        Serial.print(regAddr, HEX);
        Serial.print("...");
    #endif
    uint8_t status = 0;
    #if ((I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE && ARDUINO < 100) || I2CDEV_IMPLEMENTATION == I2CDEV_BUILTIN_NBWIRE)
        Wire.beginTransmission(devAddr);
        Wire.send(regAddr); // send address
    #elif (I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE && ARDUINO >= 100)
        Wire.beginTransmission(devAddr);
        Wire.write(regAddr); // send address
    #elif (I2CDEV_IMPLEMENTATION == I2CDEV_BUILTIN_FASTWIRE)
        Fastwire::beginTransmission(devAddr);
        Fastwire::write(regAddr);
    #endif
    for (uint8_t i = 0; i < length * 2; i++) {
        #ifdef I2CDEV_SERIAL_DEBUG
            Serial.print(data[i], HEX);
            if (i + 1 < length) Serial.print(" ");
        #endif
        #if ((I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE && ARDUINO < 100) || I2CDEV_IMPLEMENTATION == I2CDEV_BUILTIN_NBWIRE)
            Wire.send((uint8_t)(data[i] >> 8));     // send MSB
            Wire.send((uint8_t)data[i++]);          // send LSB
        #elif (I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE && ARDUINO >= 100)
            Wire.write((uint8_t)(data[i] >> 8));    // send MSB
            Wire.write((uint8_t)data[i++]);         // send LSB
        #elif (I2CDEV_IMPLEMENTATION == I2CDEV_BUILTIN_FASTWIRE)
            Fastwire::write((uint8_t)(data[i] >> 8));       // send MSB
            status = Fastwire::write((uint8_t)data[i++]);   // send LSB
            if (status != 0) break;
        #endif
    }
    #if ((I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE && ARDUINO < 100) || I2CDEV_IMPLEMENTATION == I2CDEV_BUILTIN_NBWIRE)
        Wire.endTransmission();
    #elif (I2CDEV_IMPLEMENTATION == I2CDEV_ARDUINO_WIRE && ARDUINO >= 100)
        status = Wire.endTransmission();
    #elif (I2CDEV_IMPLEMENTATION == I2CDEV_BUILTIN_FASTWIRE)
        Fastwire::stop();
        //status = Fastwire::endTransmission();
    #endif
    #ifdef I2CDEV_SERIAL_DEBUG
        Serial.println(". Done.");
    #endif
    return status == 0;
}

/** Default timeout value for read operations.
 * Set this to 0 to disable timeout detection.
 */
uint16_t I2Cdev::readTimeout = I2CDEV_DEFAULT_READ_TIMEOUT;


    // I2C library
    //////////////////////
    // Copyright(C) 2012
    // Francesco Ferrara
    // ferrara[at]libero[point]it
    //////////////////////

    /*
    FastWire
    - 0.24 added stop
    - 0.23 added reset

     This is a library to help faster programs to read I2C devices.
     Copyright(C) 2012 Francesco Ferrara
     occhiobello at gmail dot com
     [used by Jeff Rowberg for I2Cdevlib with permission]
     */

    boolean Fastwire::waitInt() {
        int l = 250;
        while (!(TWCR & (1 << TWINT)) && l-- > 0);
        return l > 0;
    }

    void Fastwire::setup(int khz, boolean pullup) {
        TWCR = 0;
        #if defined(__AVR_ATmega168__) || defined(__AVR_ATmega8__) || defined(__AVR_ATmega328P__)
            // activate internal pull-ups for twi (PORTC bits 4 & 5)
            // as per note from atmega8 manual pg167
            if (pullup) PORTC |= ((1 << 4) | (1 << 5));
            else        PORTC &= ~((1 << 4) | (1 << 5));
        #elif defined(__AVR_ATmega644P__) || defined(__AVR_ATmega644__)
            // activate internal pull-ups for twi (PORTC bits 0 & 1)
            if (pullup) PORTC |= ((1 << 0) | (1 << 1));
            else        PORTC &= ~((1 << 0) | (1 << 1));
        #else
            // activate internal pull-ups for twi (PORTD bits 0 & 1)
            // as per note from atmega128 manual pg204
            if (pullup) PORTD |= ((1 << 0) | (1 << 1));
            else        PORTD &= ~((1 << 0) | (1 << 1));
        #endif

        TWSR = 0; // no prescaler => prescaler = 1
        TWBR = ((16000L / khz) - 16) / 2; // change the I2C clock rate
        TWCR = 1 << TWEN; // enable twi module, no interrupt
    }

    // added by Jeff Rowberg 2013-05-07:
    // Arduino Wire-style "beginTransmission" function
    // (takes 7-bit device address like the Wire method, NOT 8-bit: 0x68, not 0xD0/0xD1)
    byte Fastwire::beginTransmission(byte device) {
        byte twst, retry;
        retry = 2;
        do {
            TWCR = (1 << TWINT) | (1 << TWEN) | (1 << TWSTO) | (1 << TWSTA);
            if (!waitInt()) return 1;
            twst = TWSR & 0xF8;
            if (twst != TW_START && twst != TW_REP_START) return 2;

            //Serial.print(device, HEX);
            //Serial.print(" ");
            TWDR = device << 1; // send device address without read bit (1)
            TWCR = (1 << TWINT) | (1 << TWEN);
            if (!waitInt()) return 3;
            twst = TWSR & 0xF8;
        } while (twst == TW_MT_SLA_NACK && retry-- > 0);
        if (twst != TW_MT_SLA_ACK) return 4;
        return 0;
    }

    byte Fastwire::writeBuf(byte device, byte address, byte *data, byte num) {
        byte twst, retry;

        retry = 2;
        do {
            TWCR = (1 << TWINT) | (1 << TWEN) | (1 << TWSTO) | (1 << TWSTA);
            if (!waitInt()) return 1;
            twst = TWSR & 0xF8;
            if (twst != TW_START && twst != TW_REP_START) return 2;

            //Serial.print(device, HEX);
            //Serial.print(" ");
            TWDR = device & 0xFE; // send device address without read bit (1)
            TWCR = (1 << TWINT) | (1 << TWEN);
            if (!waitInt()) return 3;
            twst = TWSR & 0xF8;
        } while (twst == TW_MT_SLA_NACK && retry-- > 0);
        if (twst != TW_MT_SLA_ACK) return 4;

        //Serial.print(address, HEX);
        //Serial.print(" ");
        TWDR = address; // send data to the previously addressed device
        TWCR = (1 << TWINT) | (1 << TWEN);
        if (!waitInt()) return 5;
        twst = TWSR & 0xF8;
        if (twst != TW_MT_DATA_ACK) return 6;

        for (byte i = 0; i < num; i++) {
            //Serial.print(data[i], HEX);
            //Serial.print(" ");
            TWDR = data[i]; // send data to the previously addressed device
            TWCR = (1 << TWINT) | (1 << TWEN);
            if (!waitInt()) return 7;
            twst = TWSR & 0xF8;
            if (twst != TW_MT_DATA_ACK) return 8;
        }
        //Serial.print("\n");

        return 0;
    }

    byte Fastwire::write(byte value) {
        byte twst;
        //Serial.println(value, HEX);
        TWDR = value; // send data
        TWCR = (1 << TWINT) | (1 << TWEN);
        if (!waitInt()) return 1;
        twst = TWSR & 0xF8;
        if (twst != TW_MT_DATA_ACK) return 2;
        return 0;
    }

    byte Fastwire::readBuf(byte device, byte address, byte *data, byte num) {
        byte twst, retry;

        retry = 2;
        do {
            TWCR = (1 << TWINT) | (1 << TWEN) | (1 << TWSTO) | (1 << TWSTA);
            if (!waitInt()) return 16;
            twst = TWSR & 0xF8;
            if (twst != TW_START && twst != TW_REP_START) return 17;

            //Serial.print(device, HEX);
            //Serial.print(" ");
            TWDR = device & 0xfe; // send device address to write
            TWCR = (1 << TWINT) | (1 << TWEN);
            if (!waitInt()) return 18;
            twst = TWSR & 0xF8;
        } while (twst == TW_MT_SLA_NACK && retry-- > 0);
        if (twst != TW_MT_SLA_ACK) return 19;

        //Serial.print(address, HEX);
        //Serial.print(" ");
        TWDR = address; // send data to the previously addressed device
        TWCR = (1 << TWINT) | (1 << TWEN);
        if (!waitInt()) return 20;
        twst = TWSR & 0xF8;
        if (twst != TW_MT_DATA_ACK) return 21;

        /***/

        retry = 2;
        do {
            TWCR = (1 << TWINT) | (1 << TWEN) | (1 << TWSTO) | (1 << TWSTA);
            if (!waitInt()) return 22;
            twst = TWSR & 0xF8;
            if (twst != TW_START && twst != TW_REP_START) return 23;

            //Serial.print(device, HEX);
            //Serial.print(" ");
            TWDR = device | 0x01; // send device address with the read bit (1)
            TWCR = (1 << TWINT) | (1 << TWEN);
            if (!waitInt()) return 24;
            twst = TWSR & 0xF8;
        } while (twst == TW_MR_SLA_NACK && retry-- > 0);
        if (twst != TW_MR_SLA_ACK) return 25;

        for (uint8_t i = 0; i < num; i++) {
            if (i == num - 1)
                TWCR = (1 << TWINT) | (1 << TWEN);
            else
                TWCR = (1 << TWINT) | (1 << TWEN) | (1 << TWEA);
            if (!waitInt()) return 26;
            twst = TWSR & 0xF8;
            if (twst != TW_MR_DATA_ACK && twst != TW_MR_DATA_NACK) return twst;
            data[i] = TWDR;
            //Serial.print(data[i], HEX);
            //Serial.print(" ");
        }
        //Serial.print("\n");
        stop();

        return 0;
    }

    void Fastwire::reset() {
        TWCR = 0;
    }

    byte Fastwire::stop() {
        TWCR = (1 << TWINT) | (1 << TWEN) | (1 << TWSTO);
        if (!waitInt()) return 1;
        return 0;
    }
