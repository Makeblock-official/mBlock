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
#include "MeGasSensor.h"

#ifdef ME_PORT_DEFINED
MeGasSensor::MeGasSensor() : MePort(0)
{
}

MeGasSensor::MeGasSensor(uint8_t port) : MePort(port)
{
}

#endif /* ME_PORT_DEFINED */


uint8_t MeGasSensor::readDigital()
{
	return( MePort::dRead2() );
}

uint16_t MeGasSensor::readAnalog()
{
	return( MePort::aRead1() );
}

/**
 * Modify History:
 * $Log
 */
