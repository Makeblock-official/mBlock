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
#include "MeFlameSensor.h"

#ifdef ME_PORT_DEFINED
MeFlameSensor::MeFlameSensor() : MePort(0)
{
}

MeFlameSensor::MeFlameSensor(uint8_t port) : MePort(port)
{
}

#endif // ME_PORT_DEFINED


uint8_t MeFlameSensor::readSensor()
{
  return( MePort::dRead2() );
}
