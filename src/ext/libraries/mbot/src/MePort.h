#ifndef MEPORT_H_
#define MEPORT_H_

#include <Arduino.h>
#include <avr/interrupt.h>
#include <avr/io.h>
#include "wiring_private.h"
#ifndef F_CPU
#define  F_CPU 16000000UL
#endif
#include <util/delay.h>
#include <stdint.h>
#include <stdlib.h>

typedef struct
{
    uint8_t s1;
    uint8_t s2;
} MePort_Sig;
extern MePort_Sig mePort[11];//mePort[0] is nonsense

#define NC 					-1

// #define PORT_1 				0x01
// #define PORT_2 				0x02
// #define PORT_3 				0x03
// #define PORT_4 				0x04
// #define PORT_5 				0x05
// #define PORT_6 				0x06
// #define PORT_7 				0x07
// #define PORT_8 				0x08
// #define M1     				0x09
// #define M2     				0x0a

typedef enum
{
    PORT_0,
    PORT_1,
    PORT_2,
    PORT_3,
    PORT_4,
    PORT_5,
    PORT_6,
    PORT_7,
    PORT_8,
    M1,
    M2,
}MEPORT;

// #if defined(__AVR_ATmega32U4__) 
// // buzzer 
// #define buzzerOn()  DDRE |= 0x04,PORTE |= B00000100
// #define buzzerOff() DDRE |= 0x04,PORTE &= B11111011
// #else
// #define buzzerOn()  DDRC |= 0x20,PORTC |= B00100000;
// #define buzzerOff() DDRC |= 0x20,PORTC &= B11011111;
// #endif
#define SLOT1 1
#define SLOT2 2
#define SLOT_1 SLOT1
#define SLOT_2 SLOT2

#define FALSE 0
#define TRUE  1

// Platform specific I/O definitions

// #if defined(__AVR__)
// #define MePIN_TO_BASEREG(pin)             (portInputRegister(digitalPinToPort(pin)))
// #define MePIN_TO_BITMASK(pin)             (digitalPinToBitMask(pin))
// #define MeIO_REG_TYPE uint8_t
// #define MeIO_REG_ASM asm("r30")
// #define MeDIRECT_READ(base, mask)         (((*(base)) & (mask)) ? 1 : 0)
// #define MeDIRECT_MODE_INPUT(base, mask)   ((*((base)+1)) &= ~(mask)),((*((base)+2)) |= (mask))//INPUT_PULLUP
// #define MeDIRECT_MODE_OUTPUT(base, mask)  ((*((base)+1)) |= (mask))
// #define MeDIRECT_WRITE_LOW(base, mask)    ((*((base)+2)) &= ~(mask))
// #define MeDIRECT_WRITE_HIGH(base, mask)   ((*((base)+2)) |= (mask))
// #endif

//#define MeDIRECT_MODE_INPUT(base, mask)   ((*((base)+1)) &= ~(mask)),((*((base)+2)) |= (mask))//INPUT_PULLUP

///@brief class of MePort,it contains two pin.
class MePort
{
public:
	MePort();
    ///@brief initialize the Port
    ///@param port port number of device
    MePort(MEPORT port);
    MePort(MEPORT port,uint8_t slot);
    ///@return the level of pin 1 of port
    ///@retval true on HIGH.
    ///@retval false on LOW.
    uint8_t getPort();
	uint8_t getSlot();
    ///@return the level of pin 1 of port
    ///@retval true on HIGH.
    ///@retval false on LOW.
    bool dRead1();
    ///@return the level of pin 2 of port
    ///@retval true on HIGH.
    ///@retval false on LOW.
    bool dRead2();
    ///@brief set the analog value of pin 1 of port
    ///@param value is HIGH or LOW
    void dWrite1(bool value);
    ///@brief set the level of pin 1 of port
    ///@param value is HIGH or LOW
    void dWrite2(bool value);
    ///@return the analog signal of pin 1 of port between 0 to 1023
    int aRead1();
    ///@return the analog signal of pin 2 of port between 0 to 1023
    int aRead2();
    ///@brief set the PWM outpu value of pin 1 of port
    ///@param value between 0 to 255
    void aWrite1(int value);
    ///@brief set the PWM outpu value of pin 2 of port
    ///@param value between 0 to 255
    void aWrite2(int value);
	void reset(uint8_t port);
	void reset(uint8_t port,uint8_t slot);
	uint8_t pin1();
	uint8_t pin2();
    uint8_t pin();
    uint8_t pin(uint8_t port,uint8_t slot);
protected:
    uint8_t s1;
    uint8_t s2;
    uint8_t _port;
    uint8_t _slot;
    uint8_t _pin;
};
#endif
