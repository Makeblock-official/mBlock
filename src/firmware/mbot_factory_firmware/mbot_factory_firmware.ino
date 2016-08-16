/*************************************************************************
* File Name          : mbot_factory_firmware.ino
* Author             : Ander, Mark Yan
* Updated            : Ander, Mark Yan
* Version            : V06.01.007
* Date               : 07/06/2016
* Description        : Firmware for Makeblock Electronic modules with Scratch.  
* License            : CC-BY-SA 3.0
* Copyright (C) 2013 - 2016 Maker Works Technology Co., Ltd. All right reserved.
* http://www.makeblock.cc/
**************************************************************************/
#include <Wire.h>
#include <SoftwareSerial.h>
#include <MeMCore.h>
MeRGBLed rgb(0,16);
MeUltrasonicSensor ultr(PORT_3);
MeLineFollower line(PORT_2);
MeLEDMatrix ledMx;
MeIR ir;
MeBuzzer buzzer;
MeTemperature ts;
Me7SegmentDisplay seg;

MeDCMotor MotorL(M1);
MeDCMotor MotorR(M2);
MePort generalDevice;
Servo servo;

#define NTD1 294
#define NTD2 330
#define NTD3 350
#define NTD4 393
#define NTD5 441
#define NTD6 495
#define NTD7 556
#define NTDL1 147
#define NTDL2 165
#define NTDL3 175
#define NTDL4 196
#define NTDL5 221
#define NTDL6 248
#define NTDL7 278
#define NTDH1 589
#define NTDH2 661
#define NTDH3 700
#define NTDH4 786
#define NTDH5 882
#define NTDH6 990
#define NTDH7 112


#define RUN_F 0x01
#define RUN_B 0x01<<1
#define RUN_L 0x01<<2
#define RUN_R 0x01<<3
#define STOP 0

enum
{
  MODE_A,
  MODE_B,
  MODE_C
};

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

char buffer[52];
char bufferBt[52];
char serialRead;
byte index = 0;
byte dataLen;
byte modulesLen=0;
unsigned char prevc=0;
String mVersion = "06.01.007";

boolean isAvailable = false;
boolean isStart = false;
boolean buttonPressed = false;
boolean currentPressed = false;
boolean pre_buttonPressed = false;

float angleServo = 90.0;
double lastTime = 0.0;
double currentTime = 0.0;

int len = 52;
int LineFollowFlag=0;
int moveSpeed = 200;
int minSpeed = 48;
int factor = 23;
int analogs[8]={A0,A1,A2,A3,A4,A5,A6,A7};
int px = 0;

uint8_t command_index = 0;
uint8_t motor_sta = STOP;
uint8_t mode = MODE_A;

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
#define DIGITAL 30
#define ANALOG 31
#define PWM 32
#define SERVO_PIN 33
#define TONE 34
#define BUTTON_INNER 35
#define LEDMATRIX 41
#define TIMER 50

#define GET 1
#define RUN 2
#define RESET 4
#define START 5

unsigned char readBuffer(int index){
 return buffer[index]; 
}
void writeBuffer(int index,unsigned char c){
  buffer[index]=c;
}
void writeHead(){
  writeSerial(0xff);
  writeSerial(0x55);
}
void writeEnd(){
 Serial.println(); 
}
void writeSerial(unsigned char c){
 Serial.write(c);
}
void readSerial(){
  isAvailable = false;
  if(Serial.available()>0){
    isAvailable = true;
    serialRead = Serial.read();
  }
}
void serialHandle(){
  readSerial();
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

void buzzerOn(){
  buzzer.tone(500,1000); 
}
void buzzerOff(){
  buzzer.noTone(); 
}

void get_ir_command()
{
  static long time = millis();
  if (ir.decode())
  {
    uint32_t value = ir.value;
    time = millis();
    switch (value >> 16 & 0xff)
    {
      case IR_BUTTON_A:
        moveSpeed = 220;
        mode = MODE_A;
        Stop();
        cli();
        buzzer.tone(NTD1, 300);
        sei();
        rgb.setColor(0,0,0);
        rgb.setColor(10, 10, 10);
        rgb.show();
        break;
      case IR_BUTTON_B:
        moveSpeed = 200;
        mode = MODE_B;
        Stop();
        cli();
        buzzer.tone(NTD2, 300);
        sei();
        buzzer.noTone();  
        rgb.setColor(0,0,0);
        rgb.setColor(0, 10, 0);
        rgb.show();
        break;
      case IR_BUTTON_C:
        mode = MODE_C;
        moveSpeed = 120;
        Stop();
        cli();
        buzzer.tone(NTD3, 300);
        sei();
        rgb.setColor(0,0,0);
        rgb.setColor(0, 0, 10);
        rgb.show();
        break;
      case IR_BUTTON_PLUS:
        motor_sta = RUN_F;
        //buzzer.tone(NTD4, 300); 
        rgb.setColor(0,0,0);
        rgb.setColor(10, 10, 0);
        rgb.show();
        //               Forward();
        break;
      case IR_BUTTON_MINUS:
        motor_sta = RUN_B;
        rgb.setColor(0,0,0);
        rgb.setColor(10, 0, 0);
        rgb.show();
        //buzzer.tone(NTD4, 300); 
        //               Backward();
        break;
      case IR_BUTTON_NEXT:
        motor_sta = RUN_R;
        //buzzer.tone(NTD4, 300); 
        rgb.setColor(0,0,0);
        rgb.setColor(1,10, 10, 0);
        rgb.show();
        //               TurnRight();
        break;
      case IR_BUTTON_PREVIOUS:
        motor_sta = RUN_L;
        //buzzer.tone(NTD4, 300); 
        rgb.setColor(0,0,0);
        rgb.setColor(2,10, 10, 0);
        rgb.show();
        //               TurnLeft();
        break;
      case IR_BUTTON_9:
        cli();
        buzzer.tone(NTDH2, 300);
        sei();
        ChangeSpeed(factor * 9 + minSpeed);
        break;
      case IR_BUTTON_8:
        cli();
        buzzer.tone(NTDH1, 300);
        sei();
        ChangeSpeed(factor * 8 + minSpeed);
        break;
      case IR_BUTTON_7:
        cli();
        buzzer.tone(NTD7, 300);
        sei();
        ChangeSpeed(factor * 7 + minSpeed);
        break;
      case IR_BUTTON_6:
        cli();
        buzzer.tone(NTD6, 300);
        sei();
        ChangeSpeed(factor * 6 + minSpeed);
        break;
      case IR_BUTTON_5:
        cli();
        buzzer.tone(NTD5, 300);
        sei();
        ChangeSpeed(factor * 5 + minSpeed);
        break;
      case IR_BUTTON_4:
        cli();
        buzzer.tone(NTD4, 300);
        sei();
        ChangeSpeed(factor * 4 + minSpeed);
        break;
      case IR_BUTTON_3:
        cli();
        buzzer.tone(NTD3, 300);
        sei();
        ChangeSpeed(factor * 3 + minSpeed);
        break;
      case IR_BUTTON_2:
        cli();
        buzzer.tone(NTD2, 300);
        sei();
        ChangeSpeed(factor * 2 + minSpeed);
        break;
      case IR_BUTTON_1:
        cli();
        buzzer.tone(NTD1, 300);
        sei();
        ChangeSpeed(factor * 1 + minSpeed);
        break;
    }
  }
  else if (millis() - time > 120)
  {
    motor_sta = STOP;
    time = millis();
  }
}
void Forward()
{
  MotorL.run(-moveSpeed);
  MotorR.run(moveSpeed);
}
void Backward()
{
  MotorL.run(moveSpeed); 
  MotorR.run(-moveSpeed);
}
void TurnLeft()
{
  MotorL.run(-moveSpeed/5);
  MotorR.run(moveSpeed);
}
void TurnRight()
{
  MotorL.run(-moveSpeed);
  MotorR.run(moveSpeed/5);
}
void BackwardAndTurnLeft()
{
  MotorL.run(moveSpeed/8 ); 
  MotorR.run(-moveSpeed);
}

void BackwardAndTurnRight()
{
  MotorL.run(moveSpeed); 
  MotorR.run(-moveSpeed/8);
}
void Stop()
{
  rgb.setColor(0,0,0);
  rgb.show();
  MotorL.run(0);
  MotorR.run(0);
}
uint8_t prevState = 0;
void ChangeSpeed(int spd)
{
//  buzzer.tone(NTD5, 300); 
  moveSpeed = spd;
}

void modeA()
{
  switch (motor_sta)
  {
    case RUN_F:
      Forward();
      prevState = motor_sta;
      break;
    case RUN_B:
      Backward();
      prevState = motor_sta;
      break;
    case RUN_L:
      TurnLeft();
      prevState = motor_sta;
      break;
    case RUN_R:
      TurnRight();
      prevState = motor_sta;
      break;
    case STOP:
      if(prevState!=motor_sta){
        prevState = motor_sta;
        Stop();
      }
      break;
  }

}

void modeB()
{
  uint8_t d = ultr.distanceCm(70);
  static long time = millis();
  randomSeed(analogRead(6));
  uint8_t randNumber = random(2);
  if (d > 40 || d == 0)
  {
    Forward();
  }
  else if ((d > 15) && (d < 40)) 
  {
    switch (randNumber)
    {
      case 0:
        TurnLeft();
        delay(300);
        break;
      case 1:
        TurnRight();
        delay(300);
        break;
    }
  }
  else
  {
    switch (randNumber)
    {
      case 0:
        BackwardAndTurnLeft();
        delay(800);
        break;
      case 1:
        BackwardAndTurnRight();
        delay(800);
        break;
    }
  }
  delay(100);
}

void modeC()
{
  uint8_t val;
  val = line.readSensors();
  if(moveSpeed >230)moveSpeed=230;
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
      if(LineFollowFlag<10) TurnLeft();
      if(LineFollowFlag>10) TurnRight();
      break;
  }
//  delay(50);
}
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
//1 byte 2 float 3 short 4 len+string 5 double
void sendFloat(float value){ 
     writeSerial(2);
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
     writeSerial(valShort.byteVal[2]);
     writeSerial(valShort.byteVal[3]);
}
void sendDouble(double value){
     writeSerial(5);
     valDouble.doubleVal = value;
     writeSerial(valDouble.byteVal[0]);
     writeSerial(valDouble.byteVal[1]);
     writeSerial(valDouble.byteVal[2]);
     writeSerial(valDouble.byteVal[3]);
     writeSerial(valDouble.byteVal[4]);
     writeSerial(valDouble.byteVal[5]);
     writeSerial(valDouble.byteVal[6]);
     writeSerial(valDouble.byteVal[7]);
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
char _receiveStr[20] = {};
uint8_t _receiveUint8[16] = {};
char* readString(int idx,int len){
  for(int i=0;i<len;i++){
    _receiveStr[i]=readBuffer(idx+i);
  }
  _receiveStr[len] = '\0';
  return _receiveStr;
}
uint8_t* readUint8(int idx,int len){
  for(int i=0;i<len;i++){
    if(i>15){
      break;
    }
    _receiveUint8[i] = readBuffer(idx+i);
  }
  return _receiveUint8;
}
void runModule(int device){
  //0xff 0x55 0x6 0x0 0x2 0x22 0x9 0x0 0x0 0xa 
  int port = readBuffer(6);
  int pin = port;
  switch(device){
   case MOTOR:{
     int speed = readShort(7);
     port==M1?MotorL.run(speed):MotorR.run(speed);
   } 
    break;
    case JOYSTICK:{
     int leftSpeed = readShort(6);
     MotorL.run(leftSpeed);
     int rightSpeed = readShort(8);
     MotorR.run(rightSpeed);
    }
    break;
   case RGBLED:{
     int slot = readBuffer(7);
     int idx = readBuffer(8);
     int r = readBuffer(9);
     int g = readBuffer(10);
     int b = readBuffer(11);
     rgb.reset(port,slot);
     if(idx>0){
       rgb.setColorAt(idx-1,r,g,b); 
     }else{
       rgb.setColor(r,g,b); 
     }
     rgb.show();
   }
   break;
   case SERVO:{
     int slot = readBuffer(7);
     pin = slot==1?mePort[port].s1:mePort[port].s2;
     int v = readBuffer(8);
     if(v>=0&&v<=180){
       servo.attach(pin);
       servo.write(v);
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
   case LEDMATRIX:{
     if(ledMx.getPort()!=port){
       ledMx.reset(port);
     }
     int action = readBuffer(7);
     if(action==1){
            int px = buffer[8];
            int py = buffer[9];
            int len = readBuffer(10);
            char *s = readString(11,len);
            ledMx.drawStr(px,py,s);
      }else if(action==2){
            int px = readBuffer(8);
            int py = readBuffer(9);
            uint8_t *ss = readUint8(10,16);
            ledMx.drawBitmap(px,py,16,ss);
      }else if(action==3){
            int point = readBuffer(8);
            int hours = readBuffer(9);
            int minutes = readBuffer(10);
            ledMx.showClock(hours,minutes,point);
     }else if(action == 4){
            ledMx.showNum(readFloat(8),3);
     }
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
   case IR:{
     String Str_data;
     int len = readBuffer(2)-3;
     for(int i=0;i<len;i++){
       Str_data+=(char)readBuffer(6+i);
     }
     ir.sendString(Str_data);
     Str_data = "";
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
     int hz = readShort(6);
     int tone_time = readShort(8);
     if(hz>0){
       buzzer.tone(hz,tone_time);
     }else{
       buzzer.noTone(); 
     }
   }
   break;
   case SERVO_PIN:{
     int v = readBuffer(7);
     if(v>=0&&v<=180){
       servo.attach(pin);
       servo.write(v);
     }
   }
   break;
   case TIMER:{
    lastTime = millis()/1000.0; 
   }
   break;
  }
}
void readSensor(int device){
  /**************************************************
      ff    55      len idx action device port slot data a
      0     1       2   3   4      5      6    7    8
      0xff  0x55   0x4 0x3 0x1    0x1    0x1  0xa 
  ***************************************************/
  float value=0.0;
  int port,slot,pin;
  port = readBuffer(6);
  pin = port;
  switch(device){
   case  ULTRASONIC_SENSOR:{
     if(ultr.getPort()!=port){
       ultr.reset(port);
     }
     value = (float)ultr.distanceCm();
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
     if(generalDevice.getPort()!=port){
       generalDevice.reset(port);
       pinMode(generalDevice.pin1(),INPUT);
       pinMode(generalDevice.pin2(),INPUT);
     }
     if(slot==1){
       value = generalDevice.aRead1();
       sendFloat(value);
     }else if(slot==2){
       value = generalDevice.aRead2();
       sendFloat(value);
     }
   }
   break;
   case  IR:{
//     if(ir.getPort()!=port){
//       ir.reset(port);
//     }
//      if(irReady){
//         sendString(irBuffer);
//         irReady = false;
//         irBuffer = "";
//      }
   }
   break;
   case IRREMOTE:{
//     unsigned char r = readBuffer(7);
//     if(millis()/1000.0-lastIRTime>0.2){
//       sendByte(0);
//     }else{
//       sendByte(irRead==r);
//     }
//     //irRead = 0;
//     irIndex = 0;
   }
   break;
   case IRREMOTECODE:{
//     sendByte(irRead);
//     irRead = 0;
//     irIndex = 0;
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
   case BUTTON_INNER:{
     pin = analogs[pin];
     char s = readBuffer(7);
     pinMode(pin,INPUT);
     boolean currentPressed = !(analogRead(pin)>10);
     sendByte(s^(currentPressed?1:0));
     buttonPressed = currentPressed;
   }
   break;
   case  GYRO:{
//       int axis = readBuffer(7);
//       gyro.update();
//       if(axis==1){
//         value = gyro.getAngleX();
//         sendFloat(value);
//       }else if(axis==2){
//         value = gyro.getAngleY();
//         sendFloat(value);
//       }else if(axis==3){
//         value = gyro.getAngleZ();
//         sendFloat(value);
//       }
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
   case TIMER:{
     sendFloat(currentTime);
   }
   break;
  }
}

void setup()
{
  delay(5);
  Stop();
  pinMode(13,OUTPUT);
  pinMode(7,INPUT);
  digitalWrite(13,HIGH);
  delay(300);
  digitalWrite(13,LOW);
  rgb.setpin(13);
  rgb.setColor(0,0,0);
  rgb.show();
  rgb.setColor(10, 0, 0);
  rgb.show();
  buzzer.tone(NTD1, 300); 
  delay(300);
  rgb.setColor(0, 10, 0);
  rgb.show();
  buzzer.tone(NTD2, 300);
  delay(300);
  rgb.setColor(0, 0, 10);
  rgb.show();
  buzzer.tone(NTD3, 300);
  delay(300);
  rgb.setColor(10,10,10);
  rgb.show();
  Serial.begin(115200);
  buzzer.noTone();
  ir.begin(); 
  Serial.print("Version: ");
  Serial.println(mVersion);
  ledMx.setBrightness(6);
  ledMx.setColorIndex(1);
}

void loop()
{
  while(1)
  {
    get_ir_command();
    serialHandle();
    currentPressed = !(analogRead(7) > 100);
    if(currentPressed != pre_buttonPressed)
    {
      pre_buttonPressed = currentPressed;
      if(currentPressed == true)
      {
        if(mode == MODE_A)
        {
          mode = MODE_B;
          moveSpeed = 200;
          Stop();
          cli();
          buzzer.tone(NTD2, 300);
          sei();
          buzzer.noTone();  
          rgb.setColor(0,0,0);
          rgb.setColor(0, 10, 0);
          rgb.show();
        }
        else if(mode == MODE_B)
        {
          mode = MODE_C;
          moveSpeed = 120;
          Stop();
          cli();
          buzzer.tone(NTD2, 300);
          sei();
          buzzer.noTone();  
          rgb.setColor(0,0,0);
          rgb.setColor(0, 0, 10);
          rgb.show();
        }
        else if(mode == MODE_C)
        {
          mode = MODE_A;
          moveSpeed = 220;
          Stop();
          cli();
          buzzer.tone(NTD1, 300);
          sei();
          buzzer.noTone();
          rgb.setColor(0,0,0);
          rgb.setColor(10, 10, 10);
          rgb.show();
        }
      }
    }
    switch (mode)
    {
      case MODE_A:
        modeA();
        break;
      case MODE_B:
        modeB();
        break;
      case MODE_C:
        modeC();
        break;
    }
  }
}
