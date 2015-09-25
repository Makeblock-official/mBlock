/*******************************************************************************
   Copyright (C), 2012-2015, MakeBlock

   FileName: MeGasSensor.cpp

   Author:   Lawrence, MakeBlock
   Version : V1.0
   Date: 2015/8/14

 
   History:
    <Author>     <Time>     <Version >     <Description>
    Lawrence    2015/8/14      1.0         new module lib
*******************************************************************************/
#ifndef MeGasSensor_H
#define MeGasSensor_H

#include <stdint.h>
#include <stdbool.h>
#include <arduino.h>
#include "MeConfig.h"


#ifdef ME_PORT_DEFINED
#include "MePort.h"
#endif // ME_PORT_DEFINED

#define Gas   (0x00)
#define NoGas (0x01)

#ifndef ME_PORT_DEFINED  
class MeGasSensor
#else // !ME_PORT_DEFINED


/**
 * CLASS:  MeGasSensor
 * TODO: DESCRIPTION
 */
class MeGasSensor : public MePort
#endif  // !ME_PORT_DEFINED
{
public:
#ifdef ME_PORT_DEFINED
  MeGasSensor();
  MeGasSensor(uint8_t port);
#endif  // ME_PORT_DEFINED
  
  uint8_t readDigital();
  uint16_t readAnalog();
};
#endif


/**
 * Moidfy History:
 * $Log
 */
