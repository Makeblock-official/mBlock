#include "MeUltrasonic.h"
/*           UltrasonicSenser                 */
 MeUltrasonic::MeUltrasonic(): MePort(PORT_0)
 {
 }
MeUltrasonic::MeUltrasonic(uint8_t pin)
{
    s2 = pin;
}
MeUltrasonic::MeUltrasonic(MEPORT port): MePort(port)
{
}

double MeUltrasonic::distanceCm(uint16_t maxCm)
{
    long distance = measure(maxCm * 55 + 200);
    return (double)distance / 58.0;
}

double MeUltrasonic::distanceInch(uint16_t maxInch)
{
    long distance = measure(maxInch * 145 + 200);
    return (double)(distance / 148.0);
}

double MeUltrasonic::distanceCm(){
  return distanceCm(400);
}
double MeUltrasonic::distanceInch(){
  return distanceInch(5);
}
long MeUltrasonic::measure(unsigned long timeout)
{
    long duration;
    // MePort::dWrite2(LOW);
    // delayMicroseconds(2);
    // MePort::dWrite2(HIGH);
    // delayMicroseconds(10);
    // MePort::dWrite2(LOW);
    // pinMode(s2, INPUT);
    // duration = pulseIn(s2, HIGH, timeout);
    digitalWrite(s2,LOW);
    delayMicroseconds(2);
    digitalWrite(s2,HIGH);
    delayMicroseconds(10);
    digitalWrite(s2,LOW);
    pinMode(s2,INPUT);
    duration = pulseIn(s2,HIGH,timeout);
    return duration;
}
