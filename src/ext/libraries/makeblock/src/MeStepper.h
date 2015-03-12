#ifndef MeStepper_h
#define MeStepper_h
#include "MePort.h"

#if ARDUINO >= 100
 #include "Arduino.h"
#else
 #include "WProgram.h"
 #include "stdlib.h"
 #include "wiring.h"
#endif


// These defs cause trouble on some versions of Arduino
#undef round

/////////////////////////////////////////////////////////////////////
/// \class MeStepper MeStepper.h <MeStepper.h>
class MeStepper:public MePort
{
public:
    MeStepper();
    MeStepper(uint8_t port);
    
    void    moveTo(long absolute); 

    void    move(long relative);
    boolean run();
    boolean runSpeed();
    void    setMaxSpeed(float speed);
    void    setAcceleration(float acceleration);
    void    setSpeed(float speed);
    float   speed();
    long    distanceToGo();
    long    targetPosition();
    long    currentPosition();  
    void    setCurrentPosition(long position);  
    void    runToPosition();
    boolean runSpeedToPosition();
    void    runToNewPosition(long position);
    void    disableOutputs();
    void    enableOutputs();

protected:

    void           computeNewSpeed();
    virtual void   step();

    virtual float  desiredSpeed();
    
private:
    uint8_t        _dir;          // 2 or 4
    uint8_t        _dirPin, _stpPin;
	long           _currentPos;    // Steps
	long           _targetPos;     // Steps
	float          _speed;         // Steps per second
    float          _maxSpeed;
    float          _acceleration;
    unsigned long  _stepInterval;
    unsigned long  _lastStepTime;
};

#endif 
