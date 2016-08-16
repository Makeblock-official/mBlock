/*************************************************************************
* File Name          : shield_firmware.ino
* Author             : Ander, Mark Yan
* Updated            : Ander, Mark Yan
* Version            : V0c.01.105
* Date               : 07/06/2016
* Description        : Firmware for Makeblock Electronic modules with Scratch.  
* License            : CC-BY-SA 3.0
* Copyright (C) 2013 - 2016 Maker Works Technology Co., Ltd. All right reserved.
* http://www.makeblock.cc/
**************************************************************************/
#include <Wire.h>
#include <SoftwareSerial.h>
#include <Arduino.h>
#include <MeShield.h>

Servo servos[8];  
MeDCMotor dc;
MeTemperature ts;
MeRGBLed led;
MeUltrasonicSensor us;
Me7SegmentDisplay seg;
MePort generalDevice;
MeInfraredReceiver *ir = NULL;
MeGyro gyro;
MeJoystick joystick;
MeStepper steppers[4];
MeBuzzer buzzer;
MeHumiture humiture;
MeFlameSensor FlameSensor;
MeGasSensor GasSensor;
MeTouchSensor touchSensor;
Me4Button buttonSensor;

typedef struct MeModule
{
    int device;
    int port;
    int slot;
    int pin;
    int index;
    float values[3];
} MeModule;

union{
    byte byteVal[4];
    float floatVal;
    long longVal;
}val;

union{
  byte byteVal[8];
  double doubleVal;
}valDouble;

union{
  byte byteVal[2];
  short shortVal;
}valShort;
MeModule modules[12];
#if defined(__AVR_ATmega32U4__) 
  int analogs[12]={A0,A1,A2,A3,A4,A5,A6,A7,A8,A9,A10,A11};
#endif
#if defined(__AVR_ATmega328P__) or defined(__AVR_ATmega168__)
  int analogs[8]={A0,A1,A2,A3,A4,A5,A6,A7};
  MeEncoderMotor encoders[2];
#endif
#if defined(__AVR_ATmega1280__)|| defined(__AVR_ATmega2560__)
  int analogs[16]={A0,A1,A2,A3,A4,A5,A6,A7,A8,A9,A10,A11,A12,A13,A14,A15};
#endif
String mVersion = "0c.01.105";
boolean isAvailable = false;
boolean isBluetooth = false;

int len = 52;
char buffer[52];
char bufferBt[52];
byte index = 0;
byte dataLen;
byte modulesLen=0;
boolean isStart = false;
unsigned char irRead;
char serialRead;
#define VERSION 0
#define ULTRASONIC_SENSOR 1
#define TEMPERATURE_SENSOR 2
#define LIGHT_SENSOR 3
#define POTENTIONMETER 4
#define JOYSTICK 5
#define GYRO 6
#define SOUND_SENSOR 7
#define RGBLED 8
#define SEVSEG 9
#define MOTOR 10
#define SERVO 11
#define ENCODER 12
#define IR 13
#define IRREMOTE 14
#define PIRMOTION 15
#define INFRARED 16
#define LINEFOLLOWER 17
#define IRREMOTECODE 18
#define SHUTTER 20
#define LIMITSWITCH 21
#define BUTTON 22
#define HUMITURE 23
#define FLAMESENSOR 24
#define GASSENSOR 25
#define COMPASS 26
#define DIGITAL 30
#define ANALOG 31
#define PWM 32
#define SERVO_PIN 33
#define TONE 34
#define PULSEIN 37
#define ULTRASONIC_ARDUINO 36
#define STEPPER 40
#define LEDMATRIX 41
#define TIMER 50
#define TOUCH_SENSOR 51

#define GET 1
#define RUN 2
#define RESET 4
#define START 5
float angleServo = 90.0;
int servo_pins[8]={0,0,0,0,0,0,0,0};
unsigned char prevc=0;
double lastTime = 0.0;
double currentTime = 0.0;
uint8_t keyPressed = 0;
uint8_t command_index = 0;

void setup(){
  pinMode(13,OUTPUT);
  digitalWrite(13,HIGH);
  delay(300);
  digitalWrite(13,LOW);
  Serial.begin(115200);
  delay(500);
  buzzerOn();
  delay(100);
  buzzerOff();
  #if defined(__AVR_ATmega328P__) or defined(__AVR_ATmega168__)
    encoders[0] = MeEncoderMotor(SLOT_1);
    encoders[1] = MeEncoderMotor(SLOT_2);
    encoders[0].begin();
    encoders[1].begin();
    delay(500);
    encoders[0].runSpeed(0);
    encoders[1].runSpeed(0);
  #else
    Serial1.begin(115200);
  #endif
    gyro.begin();
  Serial.print("Version: ");
  Serial.println(mVersion);
}
void loop(){
  keyPressed = buttonSensor.pressed();
  currentTime = millis()/1000.0-lastTime;
  if(ir != NULL)
  {
    ir->loop();
  }
  readSerial();
  steppers[0].runSpeedToPosition();
  steppers[1].runSpeedToPosition();
  steppers[2].runSpeedToPosition();
  steppers[3].runSpeedToPosition();
  if(isAvailable){
    unsigned char c = serialRead&0xff;
    if(c==0x55&&isStart==false){
     if(prevc==0xff){
      index=1;
      isStart = true;
     }
    }else{
      prevc = c;
      if(isStart){
        if(index==2){
         dataLen = c; 
        }else if(index>2){
          dataLen--;
        }
        writeBuffer(index,c);
      }
    }
     index++;
     if(index>51){
      index=0; 
      isStart=false;
     }
     if(isStart&&dataLen==0&&index>3){ 
        isStart = false;
        parseData(); 
        index=0;
     }
  }
}
unsigned char readBuffer(int index){
 return isBluetooth?bufferBt[index]:buffer[index]; 
}
void writeBuffer(int index,unsigned char c){
 if(isBluetooth){
  bufferBt[index]=c;
 }else{
  buffer[index]=c;
 } 
}
void writeHead(){
  writeSerial(0xff);
  writeSerial(0x55);
}
void writeEnd(){
  Serial.println(); 
 #if defined(__AVR_ATmega32U4__) 
  Serial1.println();
 #endif
}
void writeSerial(unsigned char c){
 Serial.write(c);
 #if defined(__AVR_ATmega32U4__) 
   Serial1.write(c);
 #endif
}
void readSerial(){
  isAvailable = false;
  if(Serial.available()>0){
    isAvailable = true;
    isBluetooth = false;
    serialRead = Serial.read();
  }
//#if defined(__AVR_ATmega32U4__) 
//  if(Serial1.available()>0){
//    isAvailable = true;
//    isBluetooth = false;
//    serialRead = Serial1.read();
//  }
// #endif
}
/*
ff 55 len idx action device port  slot  data a
0  1  2   3   4      5      6     7     8
*/
void parseData(){
  isStart = false;
  int idx = readBuffer(3);
  command_index = (uint8_t)idx;
  int action = readBuffer(4);
  int device = readBuffer(5);
  switch(action){
    case GET:{
        if(device != ULTRASONIC_SENSOR){
          writeHead();
          writeSerial(idx);
        }
        readSensor(device);
        writeEnd();
     }
     break;
     case RUN:{
       runModule(device);
       callOK();
     }
      break;
      case RESET:{
        //reset
        dc.reset(M1);
        dc.run(0);
        dc.reset(M2);
        dc.run(0);
        dc.reset(PORT_1);
        dc.run(0);
        dc.reset(PORT_2);
        dc.run(0);
        
        #if defined(__AVR_ATmega328P__)
          encoders[0].runSpeed(0);
          encoders[1].runSpeed(0);
        #endif
        callOK();
      }
     break;
     case START:{
        //start
        callOK();
      }
     break;
  }
}
void callOK(){
    writeSerial(0xff);
    writeSerial(0x55);
    writeEnd();
}
void sendByte(char c){
  writeSerial(1);
  writeSerial(c);
}
void sendString(String s){
  int l = s.length();
  writeSerial(4);
  writeSerial(l);
  for(int i=0;i<l;i++){
    writeSerial(s.charAt(i));
  }
}
void sendFloat(float value){ 
     writeSerial(0x2);
     val.floatVal = value;
     writeSerial(val.byteVal[0]);
     writeSerial(val.byteVal[1]);
     writeSerial(val.byteVal[2]);
     writeSerial(val.byteVal[3]);
}
void sendShort(double value){
     writeSerial(3);
     valShort.shortVal = value;
     writeSerial(valShort.byteVal[0]);
     writeSerial(valShort.byteVal[1]);
}
void sendDouble(double value){
     writeSerial(2);
     valDouble.doubleVal = value;
     writeSerial(valDouble.byteVal[0]);
     writeSerial(valDouble.byteVal[1]);
     writeSerial(valDouble.byteVal[2]);
     writeSerial(valDouble.byteVal[3]);
}
short readShort(int idx){
  valShort.byteVal[0] = readBuffer(idx);
  valShort.byteVal[1] = readBuffer(idx+1);
  return valShort.shortVal; 
}
float readFloat(int idx){
  val.byteVal[0] = readBuffer(idx);
  val.byteVal[1] = readBuffer(idx+1);
  val.byteVal[2] = readBuffer(idx+2);
  val.byteVal[3] = readBuffer(idx+3);
  return val.floatVal;
}
long readLong(int idx){
  val.byteVal[0] = readBuffer(idx);
  val.byteVal[1] = readBuffer(idx+1);
  val.byteVal[2] = readBuffer(idx+2);
  val.byteVal[3] = readBuffer(idx+3);
  return val.longVal;
}
void runModule(int device){
  //0xff 0x55 0x6 0x0 0x1 0xa 0x9 0x0 0x0 0xa
  int port = readBuffer(6);
  int pin = port;
  switch(device){
   case MOTOR:{
     int speed = readShort(7);
     dc.reset(port);
     dc.run(speed);
    }
    break;
    case JOYSTICK:{
     int leftSpeed = readShort(6);
     dc.reset(M1);
     dc.run(leftSpeed);
     int rightSpeed = readShort(8);
     dc.reset(M2);
     dc.run(rightSpeed);
    }
    break;
    case STEPPER:{
     int maxSpeed = readShort(7);
     long distance = readLong(9);
     if(port==PORT_1){
      steppers[0] = MeStepper(PORT_1);
      steppers[0].moveTo(distance);
      steppers[0].setMaxSpeed(maxSpeed);
      steppers[0].setSpeed(maxSpeed);
     }else if(port==PORT_2){
      steppers[1] = MeStepper(PORT_2);
      steppers[1].moveTo(distance);
      steppers[1].setMaxSpeed(maxSpeed);
      steppers[1].setSpeed(maxSpeed);
     }else if(port==M1){
      steppers[2] = MeStepper(M1);
      steppers[2].moveTo(distance);
      steppers[2].setMaxSpeed(maxSpeed);
      steppers[2].setSpeed(maxSpeed);
     }else if(port==M2){
      steppers[3] = MeStepper(M2);
      steppers[3].moveTo(distance);
      steppers[3].setMaxSpeed(maxSpeed);
      steppers[3].setSpeed(maxSpeed);
     }
    }
    break;
    case ENCODER:{
      int slot = readBuffer(7);
      int maxSpeed = readShort(8);
      float distance = readFloat(10);
      #if defined(__AVR_ATmega328P__)
        if(slot==SLOT_1){
           encoders[0].move(distance,maxSpeed);
        }else if(slot==SLOT_2){
           encoders[1].move(distance,maxSpeed);
        }
      #endif
    }
    break;
   case RGBLED:{
     int slot = readBuffer(7);
     int idx = readBuffer(8);
     int r = readBuffer(9);
     int g = readBuffer(10);
     int b = readBuffer(11);
     led.reset(port,slot);
     if(idx>0){
       led.setColorAt(idx-1,r,g,b); 
     }else{
        led.setColor(r,g,b); 
     }
     led.show();
   }
   break;
   case SERVO:{
     int slot = readBuffer(7);
     pin = slot==1?mePort[port].s1:mePort[port].s2;
     int v = readBuffer(8);
     Servo sv = servos[searchServoPin(pin)];
     if(v>=0&&v<=180){
       if(port>0){
         sv.attach(pin);
       }else{
         sv.attach(pin);
       }
       sv.write(v);
     }
   }
   break;
   case SEVSEG:{
     if(seg.getPort()!=port){
       seg.reset(port);
     }
     float v = readFloat(7);
     seg.display(v);
   }
   break;
   case LIGHT_SENSOR:{
     if(generalDevice.getPort()!=port){
       generalDevice.reset(port);
     }
     int v = readBuffer(7);
     generalDevice.dWrite1(v);
   }
   break;
   case SHUTTER:{
     if(generalDevice.getPort()!=port){
       generalDevice.reset(port);
     }
     int v = readBuffer(7);
     if(v<2){
       generalDevice.dWrite1(v);
     }else{
       generalDevice.dWrite2(v-2);
     }
   }
   break;
   case DIGITAL:{
     pinMode(pin,OUTPUT);
     int v = readBuffer(7);
     digitalWrite(pin,v);
   }
   break;
   case PWM:{
     pinMode(pin,OUTPUT);
     int v = readBuffer(7);
     analogWrite(pin,v);
   }
   break;
   case TONE:{
     pinMode(pin,OUTPUT);
     int hz = readShort(7);
     int ms = readShort(9);
     if(ms>0){
       buzzer.tone(pin, hz, ms); 
     }else{
       buzzer.noTone(pin); 
     }
   }
   break;
   case SERVO_PIN:{
     int v = readBuffer(7);
     if(v>=0&&v<=180){
       Servo sv = servos[searchServoPin(pin)];
       sv.attach(pin);
       sv.write(v);
     }
   }
   break;
   case TIMER:{
    lastTime = millis()/1000.0; 
   }
   break;
  }
}

int searchServoPin(int pin){
    for(int i=0;i<8;i++){
      if(servo_pins[i] == pin){
        return i;
      }
      if(servo_pins[i]==0){
        servo_pins[i] = pin;
        return i;
      }
    }
    return 0;
}
void readSensor(int device){
  /**************************************************
      ff 55 len idx action device port slot data a
      0  1  2   3   4      5      6    7    8
  ***************************************************/
  float value=0.0;
  int port,slot,pin;
  port = readBuffer(6);
  pin = port;
  switch(device){
   case  ULTRASONIC_SENSOR:{
     if(us.getPort()!=port){
       us.reset(port);
     }
     value = us.distanceCm();
     writeHead();
     writeSerial(command_index);
     sendFloat(value);
   }
   break;
   case  TEMPERATURE_SENSOR:{
     slot = readBuffer(7);
     if(ts.getPort()!=port||ts.getSlot()!=slot){
       ts.reset(port,slot);
     }
     value = ts.temperature();
     sendFloat(value);
   }
   break;
   case  LIGHT_SENSOR:
   case  SOUND_SENSOR:
   case  POTENTIONMETER:{
     if(generalDevice.getPort()!=port){
       generalDevice.reset(port);
       pinMode(generalDevice.pin2(),INPUT);
     }
     value = generalDevice.aRead2();
     sendFloat(value);
   }
   break;
   case  JOYSTICK:{
     slot = readBuffer(7);
     if(joystick.getPort() != port){
       joystick.reset(port);
     }
     value = joystick.read(slot);
     sendFloat(value);
   }
   break;
   case  INFRARED:
   {
     if(ir == NULL)
     {
       ir = new MeInfraredReceiver(port);
       ir->begin();
     }
     else if(ir->getPort() != port)
     {
       delete ir;
       ir = new MeInfraredReceiver(port);
       ir->begin();
     }
     irRead = ir->getCode();
     if((irRead < 255) && (irRead > 0))
     {
       sendFloat((float)irRead);
     }
     else
     {
       sendFloat(0);
     }
   }
   break;
   case  PIRMOTION:{
     if(generalDevice.getPort()!=port){
       generalDevice.reset(port);
       pinMode(generalDevice.pin2(),INPUT);
     }
     value = generalDevice.dRead2();
     sendFloat(value);
   }
   break;
   case  LINEFOLLOWER:{
     if(generalDevice.getPort()!=port){
       generalDevice.reset(port);
         pinMode(generalDevice.pin1(),INPUT);
         pinMode(generalDevice.pin2(),INPUT);
     }
     value = generalDevice.dRead1()*2+generalDevice.dRead2();
     sendFloat(value);
   }
   break;
   case LIMITSWITCH:{
     slot = readBuffer(7);
     if(generalDevice.getPort()!=port||generalDevice.getSlot()!=slot){
       generalDevice.reset(port,slot);
     }
     if(slot==1){
       pinMode(generalDevice.pin1(),INPUT_PULLUP);
       value = !generalDevice.dRead1();
     }else{
       pinMode(generalDevice.pin2(),INPUT_PULLUP);
       value = !generalDevice.dRead2();
     }
     sendFloat(value);  
   }
   break;
//   case COMPASS:{
//     if(Compass.getPort()!=port){
//       Compass.reset(port);
//       Compass.setpin(Compass.pin1(),Compass.pin2());
//     }
//     double CompassAngle;
//     CompassAngle = Compass.getAngle();
//     sendDouble(CompassAngle);
//   }
//   break;
   case HUMITURE:{
     uint8_t index = readBuffer(7);
     if(humiture.getPort()!=port){
       humiture.reset(port);
     }
     uint8_t HumitureData;
     humiture.update();
     HumitureData = humiture.getValue(index);
     sendByte(HumitureData);
   }
   break;
   case FLAMESENSOR:{
     if(FlameSensor.getPort()!=port){
       FlameSensor.reset(port);
       FlameSensor.setpin(FlameSensor.pin2(),FlameSensor.pin1());
     }
     int16_t FlameData; 
     FlameData = FlameSensor.readAnalog();
     sendShort(FlameData);
   }
   break;
   case GASSENSOR:{
     if(GasSensor.getPort()!=port){
       GasSensor.reset(port);
       GasSensor.setpin(GasSensor.pin2(),GasSensor.pin1());
     }
     int16_t GasData; 
     GasData = GasSensor.readAnalog();
     sendShort(GasData);
   }
   break;
   case  GYRO:{
       int axis = readBuffer(7);
       gyro.update();
       if(axis == 1){
         value = gyro.getAngleX();
         sendFloat(value);
       }else if(axis == 2){
         value = gyro.getAngleY();
         sendFloat(value);
       }else if(axis == 3){
         value = gyro.getAngleZ();
         sendFloat(value);
       }
   }
   break;
   case  VERSION:{
     sendString(mVersion);
   }
   break;
   case  DIGITAL:{
     pinMode(pin,INPUT);
     sendFloat(digitalRead(pin));
   }
   break;
   case  ANALOG:{
     pin = analogs[pin];
     pinMode(pin,INPUT);
     sendFloat(analogRead(pin));
   }
   break;
   case  PULSEIN:{
     int pw = readShort(7);
     pinMode(pin, INPUT);
     sendShort(pulseIn(pin,HIGH,pw));
   }
   break;
   case ULTRASONIC_ARDUINO:{
     int trig = readBuffer(6);
     int echo = readBuffer(7);
     pinMode(trig,OUTPUT);
     digitalWrite(trig,LOW);
     delayMicroseconds(2);
     digitalWrite(trig,HIGH);
     delayMicroseconds(10);
     digitalWrite(trig,LOW);
     pinMode(echo, INPUT);
     sendFloat(pulseIn(echo,HIGH,30000)/58.0);
   }
   break;
   case TIMER:{
     sendFloat((float)currentTime);
   }
   break;
   case TOUCH_SENSOR:
   {
     if(touchSensor.getPort() != port){
       touchSensor.reset(port);
     }
     sendByte(touchSensor.touched());
   }
   break;
   case BUTTON:
   {
     if(buttonSensor.getPort() != port){
       buttonSensor.reset(port);
     }
     sendByte(keyPressed == readBuffer(7));
   }
   break;
  }
}
