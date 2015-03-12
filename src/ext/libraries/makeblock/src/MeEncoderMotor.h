#ifndef MeEncoderMotor_h
#define MeEncoderMotor_h
#include "MeWire.h"


///@brief Class for Encoder Motor Driver
class MeEncoderMotor:public MeWire{
    public:
        MeEncoderMotor(uint8_t addr,uint8_t slot);
        MeEncoderMotor(uint8_t slot);
        MeEncoderMotor();
        void begin();
        boolean reset();
        boolean move(float angle, float speed);
        boolean moveTo(float angle, float speed);
        boolean runTurns(float turns, float speed);
        boolean runSpeed(float speed);
        boolean runSpeedAndTime(float speed, float time);
        float getCurrentSpeed();
        float getCurrentPosition();
    private:
        uint8_t _slot;    
};
#endif
