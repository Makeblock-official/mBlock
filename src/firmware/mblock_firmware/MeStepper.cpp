// MeStepper.cpp

#include "MeStepper.h"

void MeStepper::moveTo(long absolute)
{
    _targetPos = absolute;
    computeNewSpeed();
}

void MeStepper::move(long relative)
{
    moveTo(_currentPos + relative);
}

boolean MeStepper::runSpeed()
{
    unsigned long time = micros();
  
    if (time > _lastStepTime + _stepInterval)
    {
		if (_speed > 0)
		{
			// Clockwise
			_currentPos += 1;
		}
		else if (_speed < 0)
		{
			// Anticlockwise  
			_currentPos -= 1;
		}
		step();

		_lastStepTime = time;
		return true;
    }
    else
		return false;
}

long MeStepper::distanceToGo()
{
    return _targetPos - _currentPos;
}

long MeStepper::targetPosition()
{
    return _targetPos;
}

long MeStepper::currentPosition()
{
    return _currentPos;
}

void MeStepper::setCurrentPosition(long position)
{
    _currentPos = position;
}

void MeStepper::computeNewSpeed()
{
    setSpeed(desiredSpeed());
}

float MeStepper::desiredSpeed()
{
    long distanceTo = distanceToGo();

    float requiredSpeed;
    if (distanceTo == 0)
	return 0.0; 
    else if (distanceTo > 0) 
	requiredSpeed = sqrt(2.0 * distanceTo * _acceleration);
    else 
	requiredSpeed = -sqrt(2.0 * -distanceTo * _acceleration);

    if (requiredSpeed > _speed)
    {
	if (_speed == 0)
	    requiredSpeed = sqrt(2.0 * _acceleration);
	else
	    requiredSpeed = _speed + abs(_acceleration / _speed);
	if (requiredSpeed > _maxSpeed)
	    requiredSpeed = _maxSpeed;
    }
    else if (requiredSpeed < _speed)
    {
	if (_speed == 0)
	    requiredSpeed = -sqrt(2.0 * _acceleration);
	else
	    requiredSpeed = _speed - abs(_acceleration / _speed);
	if (requiredSpeed < -_maxSpeed)
	    requiredSpeed = -_maxSpeed;
    }
//  Serial.println(requiredSpeed);
    return requiredSpeed;
}

boolean MeStepper::run()
{
    if (_targetPos == _currentPos)
	return false;
    
    if (runSpeed())
	computeNewSpeed();
    return true;
}
MeStepper::MeStepper(): MePort(0){
}
MeStepper::MeStepper(uint8_t port): MePort(port)
{
    _currentPos = 0;
    _targetPos = 0;
    _speed = 0.0;
    _maxSpeed = 3000.0;
    _acceleration = 3000.0;
    _stepInterval = 0;
    _lastStepTime = 0;
	_dir = 1;
	pinMode(s1,OUTPUT);
	pinMode(s2,OUTPUT);
	digitalWrite(s1,_dir);
}
void MeStepper::setMaxSpeed(float speed)
{
    _maxSpeed = speed;
    computeNewSpeed();
}

void MeStepper::setAcceleration(float acceleration)
{
    _acceleration = acceleration;
    computeNewSpeed();
}

void MeStepper::setSpeed(float speed)
{
    _speed = speed;
    _stepInterval = abs(1000.0 / _speed)*1000.0;
	if(_speed>0){
		_dir = 1;
	}else{
		_dir = 0;
	}
	digitalWrite(s1,_dir);
}

float MeStepper::speed()
{
    return _speed;
}

void MeStepper::step()
{
	digitalWrite(s2, HIGH);
	delayMicroseconds(1);
	digitalWrite(s2, LOW);
}

// Blocks until the target position is reached
void MeStepper::runToPosition()
{
    while (run())
	;
}

boolean MeStepper::runSpeedToPosition()
{
    return _targetPos!=_currentPos ? MeStepper::runSpeed() : false;
}

// Blocks until the new target position is reached
void MeStepper::runToNewPosition(long position)
{
    moveTo(position);
    runToPosition();
}

