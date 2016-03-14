/*************************************************************************
* File Name          : Firmware_for_Auriga.ino
* Author             : myan
* Updated            : myan
* Version            : V09.01.108
* Date               : 03/14/2016
* Description        : Firmware for Makeblock Electronic modules with Scratch.  
* License            : CC-BY-SA 3.0
* Copyright (C) 2013 - 2016 Maker Works Technology Co., Ltd. All right reserved.
* http://www.makeblock.cc/
**************************************************************************/
#include <Arduino.h>
#include <MeAuriga.h>
#include "MeEEPROM.h"
#include <Wire.h>
#include <SoftwareSerial.h>

//#define DEBUG_INFO
//#define DEBUG_INFO1

Servo servos[8];  
MeDCMotor dc;
MeTemperature ts;
MeRGBLed led;
MeUltrasonicSensor *us = NULL;
Me7SegmentDisplay seg;
MePort generalDevice;
MeLEDMatrix ledMx;
MeInfraredReceiver *ir = NULL;
MeGyro gyro_ext(0,0x68);  //外接陀螺仪
MeGyro gyro(1,0x69);      //板载陀螺仪
MeCompass Compass;
MeJoystick joystick;
MeStepper steppers[2];
MeBuzzer buzzer;
MeHumiture humiture;
MeFlameSensor FlameSensor;
MeGasSensor GasSensor;
MeEncoderOnBoard Encoder_1(SLOT1);
MeEncoderOnBoard Encoder_2(SLOT2);
MeLineFollower line(PORT_10);
MeSerial mySerial(PORT_9);

typedef struct MeModule
{
  int16_t device;
  int16_t port;
  int16_t slot;
  int16_t pin;
  int16_t index;
  float values[3];
} MeModule;

union
{
  byte byteVal[4];
  float floatVal;
  long longVal;
}val;

union
{
  byte byteVal[8];
  double doubleVal;
}valDouble;

union
{
  byte byteVal[2];
  short shortVal;
}valShort;
MeModule modules[12];
#if defined(__AVR_ATmega32U4__) 
  int analogs[12]={A0,A1,A2,A3,A4,A5,A6,A7,A8,A9,A10,A11};
#endif
#if defined(__AVR_ATmega328P__) or defined(__AVR_ATmega168__)
  int analogs[8]={A0,A1,A2,A3,A4,A5,A6,A7};
#endif
#if defined(__AVR_ATmega1280__)|| defined(__AVR_ATmega2560__)
  int analogs[16]={A0,A1,A2,A3,A4,A5,A6,A7,A8,A9,A10,A11,A12,A13,A14,A15};
#endif

int16_t len = 52;
int16_t servo_pins[8]={0,0,0,0,0,0,0,0};
//Just for mbot ranger
int16_t moveSpeed = 250;
int16_t turnSpeed = 200;
int16_t minSpeed = 45;
int16_t factor = 23;
int16_t distance=0;
int16_t randnum = 0;                                                                               
int16_t auriga_power = 0;
int16_t LineFollowFlag=0;

#define MOVE_STOP       0x00
#define MOVE_FORWARD    0x01
#define MOVE_BACKWARD   0x02
int16_t move_status = MOVE_STOP;

#define BLUETOOTH_MODE                       0x00
#define AUTOMATIC_OBSTACLE_AVOIDANCE_MODE    0x01
#define BALANCED_MODE                        0x02
#define IR_REMOTE_MODE                       0x03
#define LINE_FOLLOW_MODE                     0x04

#define POWER_PORT                           A4
#define BUZZER_PORT                          45
#define RGBLED_PORT                          44

uint8_t command_index = 0;
uint8_t auriga_mode = BLUETOOTH_MODE;
uint8_t index = 0;
uint8_t dataLen;
uint8_t modulesLen=0;
uint8_t irRead = 0;
uint8_t prevc=0;
char serialRead;
char buffer[52];

double lastTime = 0.0;
double currentTime = 0.0;
double  CompAngleY, CompAngleX, GyroXangle;
double  LastCompAngleY, LastCompAngleX, LastGyroXangle;
double  last_turn_setpoint_filter = 0.0;
double  last_speed_setpoint_filter = 0.0;
double  last_speed_error_filter = 0.0;
double  angle_speed = 0.0;

float angleServo = 90.0;
float dt;

long measurement_speed_time = 0;
long lasttime_angle = 0;
long lasttime_speed = 0;
long last_Pulse_pos_encoder1 = 0;
long last_Pulse_pos_encoder2 = 0;

boolean isStart = false;
boolean isAvailable = false;
boolean leftflag;
boolean rightflag;
boolean start_flag = false;
boolean move_flag = false;

String mVersion = "09.01.107";

//////////////////////////////////////////////////////////////////////////////////////
float RELAX_ANGLE = -1;                    //自然平衡角度,根据车子自己的重心与传感器安装位置调整
#define PWM_MIN_OFFSET   4

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
#define PIRMOTION 15
#define INFRARED 16
#define LINEFOLLOWER 17
#define SHUTTER 20
#define LIMITSWITCH 21
#define BUTTON 22
#define HUMITURE 23
#define FLAMESENSOR 24
#define GASSENSOR 25
#define COMPASS 26
#define TEMPERATURE_SENSOR_1 27
#define DIGITAL 30
#define ANALOG 31
#define PWM 32
#define SERVO_PIN 33
#define TONE 34
#define PULSEIN 35
#define ULTRASONIC_ARDUINO 36
#define STEPPER 40
#define LEDMATRIX 41
#define TIMER 50
#define JOYSTICK_MOVE 52
#define COMMON_COMMONCMD 60
  //Secondary command
  #define SET_STARTER_MODE     0x10
  #define SET_AURIGA_MODE      0x11
  #define SET_MEGAPI_MODE      0x12
  #define GET_BATTERY_POWER    0x70
#define ENCODER_BOARD 61
  //Read type
  #define ENCODER_BOARD_POS    0x01
  #define ENCODER_BOARD_SPEED  0x02

#define GET 1
#define RUN 2
#define RESET 4
#define START 5

typedef struct
{
  double P, I, D;
  double Setpoint, Output, Integral,differential, last_error;
} PID;

PID  PID_angle, PID_speed, PID_turn;
PID  PID_speed_left, PID_speed_right;

void isr_process_encoder1(void)
{
  if(digitalRead(Encoder_1.GetPortB()) == 0)
  {
    Encoder_1.PulsePosMinus();
  }
  else
  {
    Encoder_1.PulsePosPlus();;
  }
}

void isr_process_encoder2(void)
{
  if(digitalRead(Encoder_2.GetPortB()) == 0)
  {
    Encoder_2.PulsePosMinus();
  }
  else
  {
    Encoder_2.PulsePosPlus();
  }
}

void WriteBalancedDataToEEPROM(void)
{
  EEPROM.write(BALANCED_CAR_PARTITION_CHECK, EEPROM_IF_HAVEPID_CHECK1);
  EEPROM.write(BALANCED_CAR_PARTITION_CHECK + 1, EEPROM_IF_HAVEPID_CHECK2);
  EEPROM.write(BALANCED_CAR_START_ADDR, EEPROM_CHECK_START);

  EEPROM.put(BALANCED_CAR_NATURAL_BALANCE, RELAX_ANGLE);
  EEPROM.put(BALANCED_CAR_ANGLE_PID_ADDR, PID_angle.P);
  EEPROM.put(BALANCED_CAR_ANGLE_PID_ADDR+4, PID_angle.I);
  EEPROM.put(BALANCED_CAR_ANGLE_PID_ADDR+8, PID_angle.D);

  EEPROM.put(BALANCED_CAR_SPEED_PID_ADDR, PID_speed.P);
  EEPROM.put(BALANCED_CAR_SPEED_PID_ADDR+4, PID_speed.I);
  EEPROM.put(BALANCED_CAR_SPEED_PID_ADDR+8, PID_speed.D);

  EEPROM.put(BALANCED_CAR_DIR_PID_ADDR, PID_turn.P);
  EEPROM.write(BALANCED_CAR_END_ADDR, EEPROM_CHECK_END);

  EEPROM.write(AURIGA_MODE_START_ADDR, EEPROM_CHECK_START);
  EEPROM.write(BALANCED_CAR_SPEED_PID_ADDR, auriga_mode);
  EEPROM.write(AURIGA_MODE_END_ADDR, EEPROM_CHECK_END);
}

void WriteAurigaModeToEEPROM(void)
{
  EEPROM.write(AURIGA_MODE_PARTITION_CHECK, EEPROM_IF_HAVEPID_CHECK1);
  EEPROM.write(AURIGA_MODE_PARTITION_CHECK + 1, EEPROM_IF_HAVEPID_CHECK2);
  EEPROM.write(AURIGA_MODE_START_ADDR, EEPROM_CHECK_START);
  EEPROM.write(AURIGA_MODE_CONFIGURE, auriga_mode);
  EEPROM.write(AURIGA_MODE_END_ADDR, EEPROM_CHECK_END);
}

int readEEPROM(void)
{
  if((EEPROM.read(BALANCED_CAR_PARTITION_CHECK) == EEPROM_IF_HAVEPID_CHECK1) && (EEPROM.read(BALANCED_CAR_PARTITION_CHECK + 1) == EEPROM_IF_HAVEPID_CHECK2))
  {
    if((EEPROM.read(BALANCED_CAR_START_ADDR)  == EEPROM_CHECK_START) && (EEPROM.read(BALANCED_CAR_END_ADDR)  == EEPROM_CHECK_END))
    {
      EEPROM.get(BALANCED_CAR_NATURAL_BALANCE, RELAX_ANGLE);
      EEPROM.get(BALANCED_CAR_ANGLE_PID_ADDR, PID_angle.P);
      EEPROM.get(BALANCED_CAR_ANGLE_PID_ADDR+4, PID_angle.I);
      EEPROM.get(BALANCED_CAR_ANGLE_PID_ADDR+8, PID_angle.D);

      EEPROM.get(BALANCED_CAR_SPEED_PID_ADDR, PID_speed.P);
      EEPROM.get(BALANCED_CAR_SPEED_PID_ADDR+4, PID_speed.I);
      EEPROM.get(BALANCED_CAR_SPEED_PID_ADDR+8, PID_speed.D);

      EEPROM.get(BALANCED_CAR_DIR_PID_ADDR, PID_turn.P);
//#ifdef DEBUG_INFO
      Serial.println( "Read data from EEPROM:");
      Serial.print(RELAX_ANGLE);
      Serial.print( "  ");
      Serial.print(PID_angle.P);
      Serial.print( "  ");
      Serial.print(PID_angle.I);
      Serial.print( "  ");
      Serial.print(PID_angle.D);
      Serial.print( "  ");
      Serial.print(PID_speed.P);
      Serial.print( "  ");
      Serial.print(PID_speed.I);
      Serial.print( "  ");
      Serial.print(PID_speed.D);
      Serial.print( "  ");
      Serial.println(PID_turn.P);
//#endif
    }
    else
    {
      Serial.println( "Data area damage on balanced car pid!" );
    }
  }
  else
  {
#ifdef DEBUG_INFO
    Serial.println( "First written Balanced data!" );
#endif
    WriteBalancedDataToEEPROM();
  }

  if((EEPROM.read(AURIGA_MODE_PARTITION_CHECK) == EEPROM_IF_HAVEPID_CHECK1) && (EEPROM.read(AURIGA_MODE_PARTITION_CHECK + 1) == EEPROM_IF_HAVEPID_CHECK2))
  {
    if((EEPROM.read(AURIGA_MODE_START_ADDR)  == EEPROM_CHECK_START) && (EEPROM.read(AURIGA_MODE_END_ADDR)  == EEPROM_CHECK_END))
    {
      EEPROM.get(AURIGA_MODE_CONFIGURE, auriga_mode);
#ifdef DEBUG_INFO
      Serial.print( "Read auriga_mode from EEPROM:");
      Serial.println(auriga_mode);
#endif
    }
    else
    {
      Serial.println( "Data area damage on auriga mode!" );
    }
  }
  else
  {
#ifdef DEBUG_INFO
    Serial.println( "First written auriga mode!" );
#endif
    WriteAurigaModeToEEPROM();
  }
}

void Forward(void)
{
  Encoder_1.setMotorPwm(-moveSpeed);
  Encoder_2.setMotorPwm(moveSpeed);
//  PID_speed_left.Setpoint = -moveSpeed;
//  PID_speed_right.Setpoint = moveSpeed;
//  move_status = MOVE_FORWARD;
//  PWM_Calcu();
}

void Backward(void)
{
  Encoder_1.setMotorPwm(moveSpeed);
  Encoder_2.setMotorPwm(-moveSpeed);
//  PID_speed_left.Setpoint = moveSpeed;
//  PID_speed_right.Setpoint = -moveSpeed;
//  move_status = MOVE_BACKWARD;
//  PWM_Calcu();
}

void BackwardAndTurnLeft(void)
{
  Encoder_1.setMotorPwm(moveSpeed/2);
  Encoder_2.setMotorPwm(-moveSpeed);
}

void BackwardAndTurnRight(void)
{
  Encoder_1.setMotorPwm(moveSpeed);
  Encoder_2.setMotorPwm(-moveSpeed/2);
}

void TurnLeft(void)
{
  Encoder_1.setMotorPwm(moveSpeed);
  Encoder_2.setMotorPwm(moveSpeed/2);
}

void TurnRight(void)
{
  Encoder_1.setMotorPwm(-moveSpeed);
  Encoder_2.setMotorPwm(-moveSpeed/2);
}

void TurnLeft1(void)
{
  Encoder_1.setMotorPwm(moveSpeed);
  Encoder_2.setMotorPwm(moveSpeed);
}

void TurnRight1(void)
{
  Encoder_1.setMotorPwm(-moveSpeed);
  Encoder_2.setMotorPwm(-moveSpeed);
}

void Stop(void)
{
  Encoder_1.setMotorPwm(0);
  Encoder_2.setMotorPwm(0);
  move_status = MOVE_STOP;
}

void ChangeSpeed(int spd)
{
  moveSpeed = spd;
}

void ultrCarProcess(void)
{
  distance = us->distanceCm();
  randomSeed(analogRead(A4));
  if((distance > 10) && (distance < 40))
  {
    randnum=random(300);
    if((randnum > 190) && (!rightflag))
    {
      leftflag=true;
      TurnLeft();   
    }
    else
    {
      rightflag=true;
      TurnRight();  
    }
  }
  else if(distance < 10)
  {
    randnum=random(300);
    if(randnum > 190)
    {
      BackwardAndTurnLeft();
    }
    else
    {
      BackwardAndTurnRight();
    }
  }
  else
  {
    leftflag=false;
    rightflag=false;
    Forward();
  }
}

unsigned char readBuffer(int index)
{
  return buffer[index]; 
}

void writeBuffer(int index,unsigned char c)
{
  buffer[index]=c;
}

void writeHead(void)
{
  writeSerial(0xff);
  writeSerial(0x55);
}

void writeEnd(void)
{
  Serial.println(); 
}

void writeSerial(unsigned char c)
{
  Serial.write(c);
}

void readSerial(void)
{
  isAvailable = false;
  if(Serial.available() > 0)
  {
    isAvailable = true;
    serialRead = Serial.read();
  }
}
/*
ff 55 len idx action device port  slot  data a
0  1  2   3   4      5      6     7     8
*/
void parseData(void)
{
  isStart = false;
  int idx = readBuffer(3);
  int action = readBuffer(4);
  int device = readBuffer(5);
  command_index = (uint8_t)idx;
  switch(action)
  {
    case GET:
      {
        if(device != ULTRASONIC_SENSOR)
        {
          writeHead();
          writeSerial(idx);
        }
        readSensor(device);
        writeEnd();
      }
      break;
    case RUN:
      {
        runModule(device);
        callOK();
      }
      break;
    case RESET:
      {
        //reset
        Encoder_1.setMotorPwm(0);
        Encoder_2.setMotorPwm(0);
        Encoder_1.SetPulsePos(0);
        Encoder_2.SetPulsePos(0);
        PID_speed_left.Setpoint = 0;
        PID_speed_right.Setpoint = 0;
        dc.reset(M1);
        dc.run(0);
        dc.reset(M2);
        dc.run(0);
        dc.reset(PORT_1);
        dc.run(0);
        dc.reset(PORT_2);
        dc.run(0);
        callOK();
      }
      break;
     case START:
      {
        //start
        callOK();
      }
      break;
  }
}

void callOK(void)
{
  writeSerial(0xff);
  writeSerial(0x55);
  writeEnd();
}

void sendByte(char c)
{
  writeSerial(1);
  writeSerial(c);
}

void sendString(String s)
{
  int l = s.length();
  writeSerial(4);
  writeSerial(l);
  for(int i=0;i<l;i++)
  {
    writeSerial(s.charAt(i));
  }
}

void sendFloat(float value)
{ 
  writeSerial(2);
  val.floatVal = value;
  writeSerial(val.byteVal[0]);
  writeSerial(val.byteVal[1]);
  writeSerial(val.byteVal[2]);
  writeSerial(val.byteVal[3]);
}

void sendLong(long value)
{ 
  writeSerial(6);
  val.longVal = value;
  writeSerial(val.byteVal[0]);
  writeSerial(val.byteVal[1]);
  writeSerial(val.byteVal[2]);
  writeSerial(val.byteVal[3]);
}

void sendShort(short value)
{
  writeSerial(3);
  valShort.shortVal = value;
  writeSerial(valShort.byteVal[0]);
  writeSerial(valShort.byteVal[1]);
}

void sendDouble(double value)
{
  writeSerial(5);
  valDouble.doubleVal = value;
  writeSerial(valDouble.byteVal[0]);
  writeSerial(valDouble.byteVal[1]);
  writeSerial(valDouble.byteVal[2]);
  writeSerial(valDouble.byteVal[3]);
}

short readShort(int idx)
{
  valShort.byteVal[0] = readBuffer(idx);
  valShort.byteVal[1] = readBuffer(idx+1);
  return valShort.shortVal; 
}

float readFloat(int idx)
{
  val.byteVal[0] = readBuffer(idx);
  val.byteVal[1] = readBuffer(idx+1);
  val.byteVal[2] = readBuffer(idx+2);
  val.byteVal[3] = readBuffer(idx+3);
  return val.floatVal;
}

long readLong(int idx)
{
  val.byteVal[0] = readBuffer(idx);
  val.byteVal[1] = readBuffer(idx+1);
  val.byteVal[2] = readBuffer(idx+2);
  val.byteVal[3] = readBuffer(idx+3);
  return val.longVal;
}

char _receiveStr[20] = {};
uint8_t _receiveUint8[16] = {};

char* readString(int idx,int len)
{
  for(int i=0;i<len;i++)
  {
    _receiveStr[i]=readBuffer(idx+i);
  }
  _receiveStr[len] = '\0';
  return _receiveStr;
}

uint8_t* readUint8(int idx,int len)
{
  for(int i=0;i<len;i++)
  {
    if(i > 15)
    {
      break;
    }
    _receiveUint8[i] = readBuffer(idx+i);
  }
  return _receiveUint8;
}

void runModule(int device)
{
  //0xff 0x55 0x6 0x0 0x1 0xa 0x9 0x0 0x0 0xa
  int port = readBuffer(6);
  int pin = port;
  switch(device)
  {
    case MOTOR:
      {
        int speed = readShort(7);
        dc.reset(port);
        dc.run(speed);
      }
      break;
    case ENCODER_BOARD:
      if(port == 0)
      {
        uint8_t slot = readBuffer(7);
        int16_t speed_value = readShort(8);
        if(slot == SLOT_1)
        {
//          PID_speed_left.Setpoint = speed_value;
          Encoder_1.setMotorPwm(speed_value);
        }
        else if(slot == SLOT_2)
        {
//          PID_speed_right.Setpoint = speed_value;
          Encoder_2.setMotorPwm(speed_value);
        }
      }
      break;
    case JOYSTICK:
      {
        int leftSpeed = readShort(6);
        Encoder_1.setMotorPwm(leftSpeed);
        int rightSpeed = readShort(8);
        Encoder_2.setMotorPwm(rightSpeed);
      }
      break;
    case STEPPER:
      {
        int maxSpeed = readShort(7);
        int distance = readShort(9);
        if(port == PORT_1)
        {
          steppers[0] = MeStepper(PORT_1);
          steppers[0].moveTo(distance);
          steppers[0].setMaxSpeed(maxSpeed);
          steppers[0].setSpeed(maxSpeed);
        }
        else if(port == PORT_2)
        {
          steppers[1] = MeStepper(PORT_2);
          steppers[1].moveTo(distance);
          steppers[1].setMaxSpeed(maxSpeed);
          steppers[1].setSpeed(maxSpeed);
        }
      } 
      break;
    case RGBLED:
      {
        int slot = readBuffer(7);
        int idx = readBuffer(8);
        int r = readBuffer(9);
        int g = readBuffer(10);
        int b = readBuffer(11);
        if(port != 0)
        {
          led.reset(port,slot);
        }
        else
        {
          led.setpin(RGBLED_PORT);
        }
        if(idx>0)
        {
          led.setColorAt(idx-1,r,g,b); 
        }
        else
        {
          led.setColor(r,g,b); 
        }
        led.show();
      }
      break;
    case COMMON_COMMONCMD:
      {
        int8_t subcmd = port;
        int8_t cmd_data = readBuffer(7);
        if(SET_AURIGA_MODE == subcmd)
        {
          Stop();
          if((cmd_data == BALANCED_MODE) || 
             (cmd_data == AUTOMATIC_OBSTACLE_AVOIDANCE_MODE) || 
             (cmd_data == BLUETOOTH_MODE) ||
             (cmd_data == IR_REMOTE_MODE) ||
             (cmd_data == LINE_FOLLOW_MODE))
          {
            buzzer.tone(BUZZER_PORT, 500, 100);
            delay(100);
            buzzer.noTone(BUZZER_PORT);
            delay(100);
            auriga_mode = cmd_data;
            EEPROM.write(AURIGA_MODE_CONFIGURE, auriga_mode);
          }
          else
          {
            auriga_mode = BLUETOOTH_MODE;
            EEPROM.write(AURIGA_MODE_CONFIGURE, auriga_mode);
          }
        }
      }
      break;
    case SERVO:
      {
        int slot = readBuffer(7);
        pin = slot==1?mePort[port].s1:mePort[port].s2;
        int v = readBuffer(8);
        Servo sv = servos[searchServoPin(pin)];
        if(v >= 0 && v <= 180)
        {
          if(port > 0)
          {
            sv.attach(pin);
          }
          else
          {
            sv.attach(pin);
          }
          sv.write(v);
        }
      }
      break;
    case SEVSEG:
      {
        if(seg.getPort() != port)
        {
          seg.reset(port);
        }
        float v = readFloat(7);
        seg.display(v);
      }
      break;
    case LEDMATRIX:
      {
        if(ledMx.getPort()!=port)
        {
          ledMx.reset(port);
        }
        int action = readBuffer(7);
        if(action==1)
        {
          int px = buffer[8];
          int py = buffer[9];
          int len = readBuffer(10);
          char *s = readString(11,len);
          ledMx.drawStr(px,py,s);
        }
        else if(action==2)
        {
          int px = readBuffer(8);
          int py = readBuffer(9);
          uint8_t *ss = readUint8(10,16);
          ledMx.drawBitmap(px,py,16,ss);
        }
        else if(action==3)
        {
          int point = readBuffer(8);
          int hours = readBuffer(9);
          int minutes = readBuffer(10);
          ledMx.showClock(hours,minutes,point);
        }
        else if(action == 4)
        {
          ledMx.showNum(readFloat(8),3);
        }
      }
      break;
    case LIGHT_SENSOR:
      {
        if(generalDevice.getPort() != port)
        {
          generalDevice.reset(port);
        }
        int v = readBuffer(7);
        generalDevice.dWrite1(v);
      }
      break;
    case SHUTTER:
      {
        if(generalDevice.getPort() != port)
        {
          generalDevice.reset(port);
        }
        int v = readBuffer(7);
        if(v < 2)
        {
          generalDevice.dWrite1(v);
        }
        else
        {
          generalDevice.dWrite2(v-2);
        }
      }
      break;
    case DIGITAL:
      {
        pinMode(pin,OUTPUT);
        int v = readBuffer(7);
        digitalWrite(pin,v);
     }
     break;
    case PWM:
      {
        pinMode(pin,OUTPUT);
        int v = readBuffer(7);
        analogWrite(pin,v);
      }
      break;
    case TONE:
      {
        pinMode(pin,OUTPUT);
        int hz = readShort(7);
        int ms = readShort(9);
        if(ms > 0)
        {
          buzzer.tone(pin, hz, ms); 
        }
        else
        {
          buzzer.noTone(pin); 
        }
      }
      break;
    case SERVO_PIN:
      {
        int v = readBuffer(7);
        if(v >= 0 && v <= 180)
        {
          Servo sv = servos[searchServoPin(pin)];
          sv.attach(pin);
          sv.write(v);
        }
      }
      break;
    case TIMER:
      {
        lastTime = millis()/1000.0; 
      }
      break;
    case JOYSTICK_MOVE:
      {
        if(port == 0)
        {
           int joy_x = readShort(7);
           int joy_y = readShort(9);
           double joy_x_temp = -(double)joy_x * 0.3;
           double joy_y_temp = (double)joy_y * 0.2;
           PID_speed.Setpoint = joy_y_temp;
           PID_turn.Setpoint = joy_x_temp;
           if(abs(PID_speed.Setpoint) > 1)
           { 
             move_flag = true;
           }
           else if((move_flag = true) && (joy_y == 0))
           {
             PID_speed.Integral = 0;
           }
           Serial.print("Set Num:");
           Serial.print(PID_turn.Setpoint);
           Serial.print(" ,");
           Serial.println(PID_speed.Setpoint);
        }
      }
      break;
  }
}

int searchServoPin(int pin)
{
  for(int i=0;i<8;i++)
  {
    if(servo_pins[i] == pin)
    {
      return i;
    }
    if(servo_pins[i] == 0)
    {
      servo_pins[i] = pin;
      return i;
    }
  }
  return 0;
}

const int16_t TEMPERATURENOMINAL     = 25;    //Nominl temperature depicted on the datasheet
const int16_t SERIESRESISTOR         = 10000; // Value of the series resistor
const int16_t BCOEFFICIENT           = 3380;  // Beta value for our thermistor(3350-3399)
const int16_t TERMISTORNOMINAL       = 10000; // Nominal temperature value for the thermistor
float calculate_temp(int16_t In_temp)
{
  float media;
  float temperatura;
  media = (float)In_temp;
  // Convert the thermal stress value to resistance
  media = 1023.0 / media - 1;
  media = SERIESRESISTOR / media;
  //Calculate temperature using the Beta Factor equation

  temperatura = media / TERMISTORNOMINAL;              // (R/Ro)
  temperatura = log(temperatura); // ln(R/Ro)
  temperatura /= BCOEFFICIENT;                         // 1/B * ln(R/Ro)
  temperatura += 1.0 / (TEMPERATURENOMINAL + 273.15);  // + (1/To)
  temperatura = 1.0 / temperatura;                     // Invert the value
  temperatura -= 273.15;                               // Convert it to Celsius
  return temperatura;
}

void readSensor(int device)
{
  /**************************************************
      ff 55 len idx action device port slot data a
      0  1  2   3   4      5      6    7    8
  ***************************************************/
  float value=0.0;
  int8_t port,slot,pin;
  port = readBuffer(6);
  pin = port;
  switch(device)
  {
    case ULTRASONIC_SENSOR:
      {
        if(us == NULL)
        {
          us = new MeUltrasonicSensor(port);
        }
        else if(us->getPort() != port)
        {
          delete us;
          us = new MeUltrasonicSensor(port);
        }
        value = (float)us->distanceCm(50000);
        delayMicroseconds(100);
        writeHead();
        writeSerial(command_index);
        sendFloat(value);
      }
      break;
    case  TEMPERATURE_SENSOR:
      {
        slot = readBuffer(7);
        if(ts.getPort() != port || ts.getSlot() != slot)
        {
          ts.reset(port,slot);
        }
        value = ts.temperature();
        sendFloat(value);
      }
      break;
    case  LIGHT_SENSOR:
    case  SOUND_SENSOR:
    case  POTENTIONMETER:
      {
        if(generalDevice.getPort() != port)
        {
          generalDevice.reset(port);
          pinMode(generalDevice.pin2(),INPUT);
        }
        value = generalDevice.aRead2();
        sendFloat(value);
      }
      break;
    case  TEMPERATURE_SENSOR_1:
      {
        if(generalDevice.getPort() != port)
        {
          generalDevice.reset(port);
          pinMode(generalDevice.pin2(),INPUT);
        }
        value = calculate_temp(generalDevice.aRead2());
        sendFloat(value);
      }
      break;
    case  JOYSTICK:
      {
        slot = readBuffer(7);
        if(joystick.getPort() != port)
        {
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
    case  PIRMOTION:
      {
        if(generalDevice.getPort() != port)
        {
          generalDevice.reset(port);
          pinMode(generalDevice.pin2(),INPUT);
        }
        value = generalDevice.dRead2();
        sendFloat(value);
      }
      break;
    case  LINEFOLLOWER:
      {
        if(generalDevice.getPort() != port)
        {
          generalDevice.reset(port);
          pinMode(generalDevice.pin1(),INPUT);
          pinMode(generalDevice.pin2(),INPUT);
        }
        value = generalDevice.dRead1()*2+generalDevice.dRead2();
        sendFloat(value);
      }
      break;
    case LIMITSWITCH:
      {
        slot = readBuffer(7);
        if(generalDevice.getPort() != port || generalDevice.getSlot() != slot)
        {
          generalDevice.reset(port,slot);
        }
        if(slot == 1)
        {
          pinMode(generalDevice.pin1(),INPUT_PULLUP);
          value = generalDevice.dRead1();
        }
        else
        {
          pinMode(generalDevice.pin2(),INPUT_PULLUP);
          value = generalDevice.dRead2();
        }
        sendFloat(value);  
      }
      break;
    case COMPASS:
      {
        if(Compass.getPort() != port)
        {
          Compass.reset(port);
          Compass.setpin(Compass.pin1(),Compass.pin2());
        }
        double CompassAngle;
        CompassAngle = Compass.getAngle();
        sendDouble(CompassAngle);
      }
      break;
    case HUMITURE:
      {
        uint8_t index = readBuffer(7);
        if(humiture.getPort() != port)
        {
          humiture.reset(port);
        }
        uint8_t HumitureData;
        humiture.update();
        HumitureData = humiture.getValue(index);
        sendByte(HumitureData);
      }
      break;
    case FLAMESENSOR:
      {
        if(FlameSensor.getPort() != port)
        {
          FlameSensor.reset(port);
          FlameSensor.setpin(FlameSensor.pin2(),FlameSensor.pin1());
        }
        int16_t FlameData; 
        FlameData = FlameSensor.readAnalog();
        sendShort(FlameData);
      }
      break;
    case GASSENSOR:
      {
        if(GasSensor.getPort() != port)
        {
          GasSensor.reset(port);
          GasSensor.setpin(GasSensor.pin2(),GasSensor.pin1());
        }
        int16_t GasData; 
        GasData = GasSensor.readAnalog();
        sendShort(GasData);
      }
      break;
    case  GYRO:
      {
        int axis = readBuffer(7);
        if((port == 0) && (gyro_ext.getDevAddr() == 0x68))      //extern gyro
        {
          value = gyro_ext.getAngle(axis);
          sendFloat(value);
        }
        else if((port == 1) && (gyro.getDevAddr() == 0x69))
        {
          value = gyro.getAngle(axis);
          sendFloat(value);
        }
      }
      break;
    case  VERSION:
      {
        sendString(mVersion);
      }
      break;
    case  DIGITAL:
      {
        pinMode(pin,INPUT);
        sendFloat(digitalRead(pin));
      }
      break;
    case  ANALOG:
      {
        pin = analogs[pin];
        pinMode(pin,INPUT);
        sendFloat(analogRead(pin));
      }
      break;
    case  PULSEIN:
      {
        int pw = readShort(7);
        pinMode(pin, INPUT);
        sendShort(pulseIn(pin,HIGH,pw));
      }
      break;
    case ULTRASONIC_ARDUINO:
      {
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
    case TIMER:
      {
        sendFloat((float)currentTime);
      }
      break;
    case ENCODER_BOARD:
      {
        if(port == 0)
        {
          slot = readBuffer(7);
          uint8_t read_type = readBuffer(8);
          if(slot == SLOT_1)
          {
            if(read_type == ENCODER_BOARD_POS)
            {
              sendLong(Encoder_1.GetPulsePos());
            }
            else if(read_type == ENCODER_BOARD_SPEED)
            {
              sendFloat(Encoder_1.GetCurrentSpeed());
            }
          }
          else if(slot == SLOT_2)
          {
            if(read_type == ENCODER_BOARD_POS)
            {
              sendLong(Encoder_2.GetPulsePos());
            }
            else if(read_type == ENCODER_BOARD_SPEED)
            {
              sendFloat(Encoder_2.GetCurrentSpeed());
            }
          }
        }
      }
      break;
    case COMMON_COMMONCMD:
      {
        int8_t subcmd = port;
        if(GET_BATTERY_POWER == subcmd)
        {
          sendFloat(get_power());
        }
      }
      break;    
  }//switch
}

float get_power(void)
{
  float power;
  auriga_power = analogRead(POWER_PORT);
  power = (auriga_power/1024.0) * 15;
  return power;
}

void PID_angle_compute(void)   //PID
{
  CompAngleX = -gyro.getAngleX();
  double error = CompAngleX - PID_angle.Setpoint;
  PID_angle.Integral += error;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
  if(abs(CompAngleX - PID_angle.Setpoint) < 1)
  {
    PID_angle.Integral = 0;
  }

  //PID_angle.differential = CompAngleX - LastCompAngleX;
  PID_angle.differential = angle_speed;
  LastCompAngleX = CompAngleX;
  PID_angle.Output = PID_angle.P * error + PID_angle.I * PID_angle.Integral + PID_angle.D * PID_angle.differential;
  if(PID_angle.Output > 0)
  {
    PID_angle.Output = PID_angle.Output + PWM_MIN_OFFSET;
  }
  else
  {
    PID_angle.Output = PID_angle.Output - PWM_MIN_OFFSET;
  }

  double pwm_left = PID_angle.Output - PID_turn.Output;
  double pwm_right = -PID_angle.Output - PID_turn.Output;

#ifdef DEBUG_INFO
  Serial.print("Relay: ");
  Serial.print(PID_angle.Setpoint);
  Serial.print(" AngX: ");
  Serial.print(CompAngleX);
  Serial.print(" Output: ");
  Serial.print(PID_angle.Output);
  Serial.print(" dif: ");
  Serial.println(PID_angle.differential);
#endif

  pwm_left = constrain(pwm_left, -255, 255);
  pwm_right = constrain(pwm_right, -255, 255);

  Encoder_1.setMotorPwm(pwm_left);
  Encoder_2.setMotorPwm(pwm_right);
}

void PID_speed_compute(void)
{
  double speed_now = (Encoder_2.GetCurrentSpeed() - Encoder_1.GetCurrentSpeed())/2;

  last_speed_setpoint_filter  = last_speed_setpoint_filter  * 0.8;
  last_speed_setpoint_filter  += PID_speed.Setpoint * 0.2;
 
  if((move_flag == true) && (abs(speed_now) < 8) && (PID_speed.Setpoint == 0))
  {
    move_flag = false;
    last_speed_setpoint_filter = 0;
    PID_speed.Integral = 0;
  }

  double error = speed_now - last_speed_setpoint_filter;
  PID_speed.Integral += error;

  if(move_flag == true)
  {
    PID_speed.Integral = constrain(PID_speed.Integral , -600, 600);
    if(abs(PID_speed.Integral) == 600)
    {
      PID_speed.Integral = 0;
    }
    PID_speed.Output = PID_speed.P * error + PID_speed.I * PID_speed.Integral;
    PID_speed.Output = constrain(PID_speed.Output , -10.0, 10.0);
  }
  else
  {
    PID_speed.Integral = constrain(PID_speed.Integral , -1200, 1200);
    PID_speed.Output = PID_speed.P * speed_now + PID_speed.I * PID_speed.Integral;
    PID_speed.Output = constrain(PID_speed.Output , -20.0, 20.0);
  }

#ifdef DEBUG_INFO
  Serial.print(speed_now);
  Serial.print(","); 
  Serial.print(PID_speed.Setpoint);
  Serial.print(",");      
  Serial.print(last_speed_error_filter);
  Serial.print(",");
  Serial.print(last_speed_setpoint_filter);
  Serial.print(",");
  Serial.print(PID_speed.Integral);
  Serial.print(",");
  Serial.println(PID_speed.Output);
#endif
  PID_angle.Setpoint =  RELAX_ANGLE - PID_speed.Output;
}

int agx_start_count;
void reset(void)
{
  if((start_flag == false) && (abs(gyro.getAngleX()) < 5))
  {
    agx_start_count++;
  }
  if((start_flag == true) && (abs(gyro.getAngleX()) > 32))
  {
    agx_start_count = 0;
    Encoder_1.setMotorPwm(0);
    Encoder_2.setMotorPwm(0);
    PID_speed.Integral = 0;
    PID_angle.Setpoint = RELAX_ANGLE;
    PID_speed.Setpoint = 0;
    PID_turn.Setpoint = 0;
    Encoder_1.SetPulsePos(0);
    Encoder_2.SetPulsePos(0);
    PID_speed.Integral = 0;
    start_flag = false;
    last_speed_setpoint_filter = 0.0;
    last_turn_setpoint_filter = 0.0;
#ifdef DEBUG_INFO
    Serial.println("> 32");
#endif
  }
  else if(agx_start_count > 20)
  {
    agx_start_count = 0;
    PID_speed.Integral = 0;
    Encoder_1.setMotorPwm(0);
    Encoder_2.setMotorPwm(0);
    PID_angle.Setpoint = RELAX_ANGLE;
    Encoder_1.SetPulsePos(0);
    Encoder_2.SetPulsePos(0);
    lasttime_speed = lasttime_angle = millis();
    start_flag = true;
#ifdef DEBUG_INFO
    Serial.println("< 5");
#endif
  }
}

void parseGcode(char * cmd)
{
  char * tmp;
  char * str;
  char g_code_cmd;
  float p_value = 0;
  float i_value = 0;
  float d_value = 0;
  float relax_angle = 0;
  str = strtok_r(cmd, " ", &tmp);
  g_code_cmd = str[0];
  while(str!=NULL)
  {
    str = strtok_r(0, " ", &tmp);
    if((str[0]=='P') || (str[0]=='p')){
      p_value = atof(str+1);
    }else if((str[0]=='I') || (str[0]=='i')){
      i_value = atof(str+1);
    }else if((str[0]=='D') || (str[0]=='d')){
      d_value = atof(str+1);
    }
    else if((str[0]=='Z') || (str[0]=='z')){
      relax_angle  = atof(str+1);
    }
    else if((str[0]=='M') || (str[0]=='m')){
      auriga_mode  = atof(str+1);
    }
  }
//#ifdef DEBUG_INFO
  Serial.print("PID: ");
  Serial.print(p_value);
  Serial.print(", ");
  Serial.print(i_value);
  Serial.print(",  ");
  Serial.println(d_value);
//#endif
  if(g_code_cmd == '1')
  {
    PID_angle.P = p_value;
    PID_angle.I = i_value;
    PID_angle.D = d_value;
    EEPROM.put(BALANCED_CAR_ANGLE_PID_ADDR, PID_angle.P);
    EEPROM.put(BALANCED_CAR_ANGLE_PID_ADDR+4, PID_angle.I);
    EEPROM.put(BALANCED_CAR_ANGLE_PID_ADDR+8, PID_angle.D);
  }
  else if(g_code_cmd == '2')
  {
    PID_speed.P = p_value;
    PID_speed.I = i_value;
    PID_speed.D = d_value;
    EEPROM.put(BALANCED_CAR_SPEED_PID_ADDR, PID_speed.P);
    EEPROM.put(BALANCED_CAR_SPEED_PID_ADDR+4, PID_speed.I);
    EEPROM.put(BALANCED_CAR_SPEED_PID_ADDR+8, PID_speed.D);
  }
  else if(g_code_cmd == '3')
  {
    RELAX_ANGLE = relax_angle;
    EEPROM.put(BALANCED_CAR_NATURAL_BALANCE, relax_angle);
  }
  else if(g_code_cmd == '4')
  {
    EEPROM.write(AURIGA_MODE_CONFIGURE, auriga_mode);
    Serial.print("auriga_mode: ");
    Serial.println(auriga_mode);
  }
}

void parseCmd(char * cmd)
{
  if((cmd[0]=='g') || (cmd[0]=='G'))
  { 
    // gcode
    parseGcode(cmd+1);
  }
}

char buf[64];
char bufindex;
void balanced_model(void)
{
  reset();
  if(start_flag == true)
  {
    if((millis() - lasttime_angle) > 10)
    {
      PID_angle_compute();
      lasttime_angle = millis();
    }    
    if((millis() - lasttime_speed) > 100)
    {
      PID_speed_compute();
      last_turn_setpoint_filter  = last_turn_setpoint_filter  * 0.8;
      last_turn_setpoint_filter  += PID_turn.Setpoint * 0.2;
      PID_turn.Output = last_turn_setpoint_filter;
      lasttime_speed = millis();
    }
  }
  else
  {
    Encoder_1.setMotorPwm(0);
    Encoder_2.setMotorPwm(0);
  } 
}

//void PWM_Calcu()
//{
//  double speed1;
//  double speed2;
//  if((millis() - lasttime_speed) > 20)
//  {
//    speed1 = Encoder_1.GetCurrentSpeed();
//    speed2 = Encoder_2.GetCurrentSpeed();
//
//#ifdef DEBUG_INFO
//    Serial.print("S1: ");
//    Serial.print(speed1);
//    Serial.print(" S2: ");
//    Serial.print(speed2);
//    Serial.print("left: ");
//    Serial.print(PID_speed_left.Setpoint);
//    Serial.print(" right: ");
//    Serial.println(PID_speed_right.Setpoint);
//#endif
//
//    if(abs(abs(PID_speed_left.Setpoint) - abs(PID_speed_right.Setpoint)) >= 0)
//    {
//      Encoder_1.setMotorPwm(PID_speed_left.Setpoint);
//      Encoder_2.setMotorPwm(PID_speed_right.Setpoint);
//      return;
//    }
//
//    if((abs(PID_speed_left.Setpoint) == 0) && (abs(PID_speed_right.Setpoint) == 0))
//    {
//      return;
//    }
//
//    if(abs(speed1) - abs(speed2) >= 0)
//    {
//      if(PID_speed_left.Setpoint > 0)
//      {
//        Encoder_1.setMotorPwm(PID_speed_left.Setpoint - (abs(speed1) - abs(speed2)));
//        Encoder_2.setMotorPwm(PID_speed_right.Setpoint);
//      }
//      else
//      {
//        Encoder_1.setMotorPwm(PID_speed_left.Setpoint + (abs(speed1) - abs(speed2)));
//        Encoder_2.setMotorPwm(PID_speed_right.Setpoint);
//      }
//    }
//    else
//    {
//      if(PID_speed_right.Setpoint > 0)
//      {
//        Encoder_1.setMotorPwm(PID_speed_left.Setpoint);
//        Encoder_2.setMotorPwm(PID_speed_right.Setpoint - (abs(speed2) - abs(speed1)));
//      }
//      else
//      {
//        Encoder_1.setMotorPwm(PID_speed_left.Setpoint);
//        Encoder_2.setMotorPwm(PID_speed_right.Setpoint + (abs(speed2) - abs(speed1)));
//      }
//    }
//    lasttime_speed = millis(); 
//  }
//}

void IrProcess()
{
  ir->loop();
  irRead =  ir->getCode();
  if((irRead != IR_BUTTON_TEST) && (auriga_mode != IR_REMOTE_MODE))
  {
    return;
  }
  switch(irRead)
  {
    case IR_BUTTON_PLUS: 
      Forward();
      break;
    case IR_BUTTON_MINUS:
      Backward();
      break;
    case IR_BUTTON_NEXT:
      TurnRight();
      break;
    case IR_BUTTON_PREVIOUS:
      TurnLeft();
      break;
    case IR_BUTTON_9:
      ChangeSpeed(factor*9+minSpeed);
      break;
    case IR_BUTTON_8:
      ChangeSpeed(factor*8+minSpeed);
      break;
    case IR_BUTTON_7:
      ChangeSpeed(factor*7+minSpeed);
      break;
    case IR_BUTTON_6:
      ChangeSpeed(factor*6+minSpeed);
      break;
    case IR_BUTTON_5:
      ChangeSpeed(factor*5+minSpeed);
      break;
    case IR_BUTTON_4:
      ChangeSpeed(factor*4+minSpeed);
      break;
    case IR_BUTTON_3:
      ChangeSpeed(factor*3+minSpeed);
      break;
    case IR_BUTTON_2:
      ChangeSpeed(factor*2+minSpeed);
      break;
    case IR_BUTTON_1:
      ChangeSpeed(factor*1+minSpeed);
      break;
    case IR_BUTTON_0:
      Stop();
      break;
    case IR_BUTTON_TEST:
      Stop();
      while( ir->buttonState() != 0)
      {
         ir->loop();
      }
      auriga_mode = auriga_mode + 1;
      if(auriga_mode == 0x05)
      { 
        auriga_mode = 0;
      }
      break;
    default:
      Stop();
      break;
  }
}

void line_model()
{
  uint8_t val;
  val = line.readSensors();
  moveSpeed=150;
  Serial.print("val:");
  Serial.println(val);
  switch (val)
  {
    case S1_IN_S2_IN:
      Forward();
      LineFollowFlag=10;
      break;

    case S1_IN_S2_OUT:
       Forward();
      if (LineFollowFlag>1) LineFollowFlag--;
      break;

    case S1_OUT_S2_IN:
      Forward();
      if (LineFollowFlag<20) LineFollowFlag++;
      break;

    case S1_OUT_S2_OUT:
      if(LineFollowFlag==10) Backward();
      if(LineFollowFlag<10) TurnRight1();
      if(LineFollowFlag>10) TurnLeft1();
      break;
  }
}

void setup()
{
  delay(5);
  attachInterrupt(Encoder_1.GetIntNum(), isr_process_encoder1, RISING);
  attachInterrupt(Encoder_2.GetIntNum(), isr_process_encoder2, RISING);
  PID_speed_left.Setpoint = 0;
  PID_speed_right.Setpoint = 0;
  led.setpin(RGBLED_PORT);
  delay(1);
  led.setColor(0,0,0);
  led.show();
  gyro_ext.begin();
  gyro.begin();
  delay(100);
  Serial.begin(115200);
  delay(500);
  buzzer.tone(BUZZER_PORT, 500, 100);
  delay(100);
  buzzer.noTone(BUZZER_PORT);
  delay(500);
  leftflag=false;
  rightflag=false;
  randomSeed(analogRead(0));
  PID_angle.Setpoint = RELAX_ANGLE;
  PID_angle.P = 10;    //10;
  PID_angle.I = 0;     //0;
  PID_angle.D = -0.4;  //-0.4  PID_speed.Setpoint = 0;
  PID_speed.P = -0.3;        // -0.5
  PID_speed.I = -0.032;      // -0.032
  readEEPROM();

  if(auriga_mode == AUTOMATIC_OBSTACLE_AVOIDANCE_MODE)
  {
    us = new MeUltrasonicSensor(PORT_8);
  }
  else if(auriga_mode == IR_REMOTE_MODE)
  {
    ir = new MeInfraredReceiver(PORT_6);
    ir->begin();
  }
  Serial.print("Version: ");
  Serial.println(mVersion);
//  Encoder_1.setMotorPwm(255);
//  Encoder_2.setMotorPwm(255);
  measurement_speed_time = lasttime_speed = lasttime_angle = millis();
}

void loop()
{
  currentTime = millis()/1000.0-lastTime;
  if(ir != NULL)
  {
    IrProcess();
  }
  steppers[0].runSpeedToPosition();
  steppers[1].runSpeedToPosition();
  get_power();

  readSerial();
  if(isAvailable)
  {
    unsigned char c = serialRead & 0xff;
    if((c == 0x55) && (isStart == false))
    {
      if(prevc == 0xff)
      {
        index=1;
        isStart = true;
      }
    }
    else
    {
      prevc = c;
      if(isStart)
      {
        if(index == 2)
        {
          dataLen = c; 
        }
        else if(index > 2)
        {
          dataLen--;
        }
        writeBuffer(index,c);
      }
    }
    index++;
    if(index > 51)
    {
      index=0; 
      isStart=false;
    }
    if(isStart && (dataLen == 0) && (index > 3))
    { 
      isStart = false;
      parseData(); 
      index=0;
    }
  }
//  while(Serial.available() > 0)
//  {
//    char c = Serial.read();
//    Serial.write(c);
//    buf[bufindex++]=c;
//    if((c=='\n') || (c=='#'))
//    {
//      parseCmd(buf);
//      memset(buf,0,64);
//      bufindex = 0;
//    }
//  }
  gyro.fast_update();
  gyro_ext.update();
  angle_speed = gyro.getGyroY();

//  generalDevice.reset(13);
//  pinMode(generalDevice.pin2(),INPUT);
//
//  float value_temp = calculate_temp(generalDevice.aRead2());
//  Serial.print("value_temp: ");
//  Serial.println(value_temp);
     
  if(auriga_mode == BLUETOOTH_MODE)
  {

  }
  else if(auriga_mode == AUTOMATIC_OBSTACLE_AVOIDANCE_MODE)
  { 
    ultrCarProcess();    
  }
  else if(auriga_mode == BALANCED_MODE)
  {
    balanced_model();
  }
  else if(auriga_mode == LINE_FOLLOW_MODE)
  {
    line_model();
  }
}
