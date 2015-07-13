///@file Makeblock.h head file of Makeblock Library V2.1.0625
///Define the interface of Makeblock Library

//#include <inttypes.h>

#ifndef Mbot_h
#define Mbot_h

#include "MeDCMotor.h"
#include "MeBuzzer.h"
#include "MeTemperature.h"
#include "Me7SegmentDisplay.h"
#include "MeRGBLed.h"
#include "MeUltrasonic.h"
#include "MeInfraredReceiver.h"

#include <Arduino.h>
// #include <SoftwareSerial.h>
// #include <Wire.h>
#include <avr/interrupt.h>
#include <avr/io.h>
#ifndef F_CPU
#define  F_CPU 16000000UL
#endif
#include <util/delay.h>
#include <stdint.h>
#include <stdlib.h>




#define MeBaseBoard     1
#define MakeblockOrion  2
#define mBot            3


///@brief Class for MeBoard
class MeBoard
{
public:
    MeBoard(uint8_t boards);
};



#endif
