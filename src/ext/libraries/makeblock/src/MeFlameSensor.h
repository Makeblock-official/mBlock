/*******************************************************************************
   Copyright (C), 2012-2015, MakeBlock

   FileName: MeFlameSensor.cpp

   Author:   Lawrence, MakeBlock
   Version : V1.0
   Date: 2015/8/14


   History:
    <Author>     <Time>     <Version >     <Description>
    Lawrence    2015/8/14      1.0         new module lib
*******************************************************************************/
#ifndef MeFlameSensor_H
#define MeFlameSensor_H

#include <stdint.h>
#include <stdbool.h>
#include <arduino.h>
#include "MeConfig.h"


#ifdef ME_PORT_DEFINED
#include "MePort.h"
#endif // ME_PORT_DEFINED

#define Fire   (0x00)
#define NoFire (0x01)

#ifndef ME_PORT_DEFINED
class MeFlameSensor
#else // !ME_PORT_DEFINED


/**
 * CLASS:  MeFireSensor
 * TODO: DESCRIPTION
 */
class MeFlameSensor : public MePort
#endif  // !ME_PORT_DEFINED
{
public:
#ifdef ME_PORT_DEFINED
  MeFlameSensor();
  MeFlameSensor(uint8_t port);
#endif  // ME_PORT_DEFINED

  uint8_t readSensor();
};
#endif

