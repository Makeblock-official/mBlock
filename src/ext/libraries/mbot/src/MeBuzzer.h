#ifndef MeBuzzer_H
#define MeBuzzer_H

#include "MePort.h"

///@brief Class for MeBuzzer module
class MeBuzzer : public MePort
{
public:
    MeBuzzer();
    MeBuzzer(uint8_t pin);
    MeBuzzer(MEPORT port);
    MeBuzzer(MEPORT port, uint8_t slot);
    void tone(uint16_t frequency, uint32_t duration = 0);
    void noTone();
};

#endif
