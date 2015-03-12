/*************************************************************************
* File Name          : Firmware.ino
* Author             : Ander
* Updated            : Ander
* Version            : V1.1.0
* Date               : 03/06/2014
* Description        : Firmware for Makeblock Electronic modules with Scratch.  
* License            : CC-BY-SA 3.0
* Copyright (C) 2013 - 2014 Maker Works Technology Co., Ltd. All right reserved.
* http://www.makeblock.cc/
**************************************************************************/
#include <Servo.h>
#include <Wire.h>
#include "MePort.h"
#include "MeServo.h" 
#include "MeDCMotor.h" 
#include "MeUltrasonic.h" 
#include "MeGyro.h"
#include "Me7SegmentDisplay.h"
#include "MeTemperature.h"
#include "MeRGBLed.h"
#include "MeInfraredReceiver.h"

MeServo servo;  
MeDCMotor dc;
MeTemperature ts;
MeRGBLed led;
MeUltrasonic us;
Me7SegmentDisplay seg;
MePort generalDevice;
MeInfraredReceiver ir;
MeGyro gyro;
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

MeModule modules[12];
#if defined(__AVR_ATmega32U4__) 
int analogs[12]={A0,A1,A2,A3,A4,A5,A6,A7,A8,A9,A10,A11};
#else
int analogs[8]={A0,A1,A2,A3,A4,A5,A6,A7};
#endif
float mVersion = 1.0805;
boolean isAvailable = false;
boolean isBluetooth = false;
void setup(){
  pinMode(13,OUTPUT);
  digitalWrite(13,HIGH);
  delay(300);
  digitalWrite(13,LOW);
#if defined(__AVR_ATmega32U4__) 
  Serial1.begin(115200); 
  gyro.begin();
#endif
  Serial.begin(115200);
  delay(1000);
  buzzerOn();
  delay(100);
  buzzerOff();
}
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
#define PIRMOTION 15
#define INFRARED 16
#define LINEFOLLOWER 17
#define SHUTTER 20
#define LIMITSWITCH 21
#define DIGITAL 30
#define ANALOG 31
#define PWM 32
#define ANGLE 33
#define TONE 34

float angleServo = 90.0;

unsigned char prevc=0;

void loop(){
  if(ir.buttonState()==1){ 
    if(ir.available()>0){
      irRead = ir.read();
    }
  }else{
    irRead = 0;
  }
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
        if(index==3){
         dataLen = c; 
        }else if(index>3){
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
void writeEnd(){
  
#if defined(__AVR_ATmega32U4__) 
 isBluetooth?Serial1.println():Serial.println(); 
#else
 Serial.println(); 
#endif
}
void writeSerial(unsigned char c){
  #if defined(__AVR_ATmega32U4__) 
 isBluetooth?Serial1.write(c):Serial.write(c); 
 #else
 Serial.write(c);
 #endif
}
void readSerial(){
  isAvailable = false;
  if(Serial.available()>0){
    isAvailable = true;
    isBluetooth = false;
    serialRead = Serial.read();
  }
    #if defined(__AVR_ATmega32U4__) 
  else if(Serial1.available()>0){
    isAvailable = true;
    isBluetooth = true;
    serialRead = Serial1.read();
  }
  #endif
}
void parseData(){
  isStart = false;
  switch(readBuffer(2)){
    case 0x1:{
      int pin = readBuffer(5);
        writeSerial(0xff);
        writeSerial(0x55);
        writeSerial(readBuffer(6));
        
        readSensor(readBuffer(4),(pin&0xf0)>>4,pin&0xf,pin);
        writeEnd();
     }
     break;
     case 0x2:{
        int l = readBuffer(3);
        int dataIndex = 4;
        while(l>dataIndex-4){
          int device = readBuffer(dataIndex);
          dataIndex++;
          int pin = readBuffer(dataIndex);
          int port = (pin&0xf0)>>4;
          int slot = pin&0xf;
          dataIndex++;
          MeModule module;
          module.device = device;
          module.port = port;
          module.slot = slot;
          module.pin = pin;
          
          if(device==RGBLED){
            module.index = readBuffer(dataIndex++);
            module.values[0]=readBuffer(dataIndex++);
            module.values[1]=readBuffer(dataIndex++);
            module.values[2]=readBuffer(dataIndex++);
            if(led.getPort()!=port||led.getSlot()!=slot){
              led.reset(port,slot);
            }
            if(module.index>0){
              led.setColorAt(module.index-1,module.values[0],module.values[1],module.values[2]);
            }else{
              for(int t=0;t<led.getNumber();t++){
                led.setColorAt(t,module.values[0],module.values[1],module.values[2]);
              }
            }
            led.show();
            callOK();
          }else if(device==MOTOR){
            val.byteVal[0]=readBuffer(dataIndex++);
            val.byteVal[1]=readBuffer(dataIndex++);
            val.byteVal[2]=readBuffer(dataIndex++);
            val.byteVal[3]=readBuffer(dataIndex++);
            module.values[0]=val.floatVal;
            dc.reset(module.port);
            dc.run(module.values[0]);
            callOK();
          }else if(device==SEVSEG){
            val.byteVal[0]=readBuffer(dataIndex++);
            val.byteVal[1]=readBuffer(dataIndex++);
            val.byteVal[2]=readBuffer(dataIndex++);
            val.byteVal[3]=readBuffer(dataIndex++);
            module.values[0]=val.floatVal;
            if(seg.getPort()!=port){
               seg.reset(port);
            }
            seg.display(module.values[0]);
            callOK();
          }else if(device==SERVO){
            val.byteVal[0]=readBuffer(dataIndex++);
            val.byteVal[1]=readBuffer(dataIndex++);
            val.byteVal[2]=readBuffer(dataIndex++);
            val.byteVal[3]=readBuffer(dataIndex++);
              //module.values[0]=val.floatVal;
              //angleServo=module.values[0];
            //module.pin = servo.pin(port,slot);
           
           // if(servo.pin()!=module.pin){
              servo.attach(servo.pin(port,slot));
            //}
            servo.write(servo.pin(port,slot),(int)(val.floatVal));
            callOK();
          }else if(device==LIGHT_SENSOR||device==SHUTTER){
            val.byteVal[0]=readBuffer(dataIndex++);
            val.byteVal[1]=readBuffer(dataIndex++);
            val.byteVal[2]=readBuffer(dataIndex++);
            val.byteVal[3]=readBuffer(dataIndex++);
            module.values[0]=val.floatVal;
            if(generalDevice.getPort()!=port){
              generalDevice.reset(module.port);
            }
            generalDevice.dWrite1(val.floatVal>=1?HIGH:LOW);
            callOK();
          }else if(device==DIGITAL){
              val.byteVal[0]=readBuffer(dataIndex++);
              val.byteVal[1]=readBuffer(dataIndex++);
              val.byteVal[2]=readBuffer(dataIndex++);
              val.byteVal[3]=readBuffer(dataIndex++);
              pinMode(module.pin,OUTPUT);
              digitalWrite(module.pin,val.floatVal>=1?HIGH:LOW);         
          }else if(device==ANALOG||device==PWM){
              val.byteVal[0]=readBuffer(dataIndex++);
              val.byteVal[1]=readBuffer(dataIndex++);
              val.byteVal[2]=readBuffer(dataIndex++);
              val.byteVal[3]=readBuffer(dataIndex++);
              if(device==ANALOG){
                pin = analogs[pin];
              }
              pinMode(module.pin,OUTPUT);
              analogWrite(module.pin,val.floatVal);
              callOK();
          }else if(device==ANGLE){
              val.byteVal[0]=readBuffer(dataIndex++);
              val.byteVal[1]=readBuffer(dataIndex++);
              val.byteVal[2]=readBuffer(dataIndex++);
              val.byteVal[3]=readBuffer(dataIndex++);
              module.values[0]=val.floatVal;
              angleServo=module.values[0];
              //if(servo.pin()!=module.pin){
                servo.attach(module.pin);
              //}
              servo.write(module.pin,abs(angleServo));
              callOK();
          }else if(device==TONE){
              val.byteVal[0]=readBuffer(dataIndex++);
              val.byteVal[1]=readBuffer(dataIndex++);
              val.byteVal[2]=readBuffer(dataIndex++);
              val.byteVal[3]=readBuffer(dataIndex++);
              int toneHz = val.byteVal[1]*256+val.byteVal[0];
              int timeMs = val.byteVal[3]*255+val.byteVal[2];
              if(timeMs!=0){
                tone(module.pin,toneHz ,timeMs); 
              }else{
                noTone(module.pin); 
              }
          }
        }
      }
      break;
      case 0x4:{
        //reset
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
     case 0x5:{
        //start
        #if defined(__AVR_ATmega32U4__) 
          buzzerOn();
          delay(100);
          buzzerOff();
        #endif
        callOK();
      }
     break;
  }
}
void callOK(){
//    writeSerial(0xff);
//    writeSerial(0x55);
//    writeEnd();
}
void readModules(){
    
    writeSerial(0xff);
    writeSerial(0x55);
    writeSerial(0x1);
    if(modulesLen>0){
      for(int i=0;i<modulesLen;i++){
        MeModule module = modules[i];
        readSensor(module.device,module.port,module.slot,module.pin);
      }
    }
    writeEnd();
}
void sendValue(float value){ 
     val.floatVal = value;
     writeSerial(val.byteVal[0]);
     writeSerial(val.byteVal[1]);
     writeSerial(val.byteVal[2]);
     writeSerial(val.byteVal[3]);
}
void readSensor(int device,int port,int slot,int pin){
  float value=0.0;
  
  switch(device){
   case  ULTRASONIC_SENSOR:{
     if(us.getPort()!=port){
       us.reset(port);
     }
     value = us.distanceCm();
     sendValue(value);
   }
   break;
   case  TEMPERATURE_SENSOR:{
     if(ts.getPort()!=port||ts.getSlot()!=slot){
       ts.reset(port,slot);
     }
     value = ts.temperature();
     sendValue(value);
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
     
//            Serial.print("device:");
//            Serial.print((pin&0xf0)>>4);
//            Serial.print(" - ");
//            Serial.print(pin&0xf);
//            Serial.print(" - ");
//            Serial.println(value);
//            return;
     sendValue(value);
   }
   break;
   case  JOYSTICK:{
     if(generalDevice.getPort()!=port){
       generalDevice.reset(port);
       pinMode(generalDevice.pin1(),INPUT);
       pinMode(generalDevice.pin2(),INPUT);
     }
     if(slot==1){
       value = generalDevice.aRead1();
       sendValue(value);
     }else if(slot==2){
       value = generalDevice.aRead2();
       sendValue(value);
     }
   }
   break;
   case  INFRARED:{
     if(ir.getPort()!=port){
       ir.reset(port);
     }
     sendValue(irRead);
   }
   break;
   case  PIRMOTION:{
     if(generalDevice.getPort()!=port){
       generalDevice.reset(port);
       pinMode(generalDevice.pin2(),INPUT);
     }
     value = generalDevice.dRead2();
     sendValue(value);
   }
   break;
   case  LINEFOLLOWER:{
     if(generalDevice.getPort()!=port){
       generalDevice.reset(port);
         pinMode(generalDevice.pin1(),INPUT);
         pinMode(generalDevice.pin2(),INPUT);
     }
     value = generalDevice.dRead1()*2+generalDevice.dRead2();
     sendValue(value);
   }
   break;
   case LIMITSWITCH:{
     if(generalDevice.getPort()!=port||generalDevice.getSlot()!=slot){
       generalDevice.reset(port,slot);
     }
     if(slot==1){
       pinMode(generalDevice.pin1(),INPUT_PULLUP);
       value = generalDevice.dRead1();
     }else{
       pinMode(generalDevice.pin2(),INPUT_PULLUP);
       value = generalDevice.dRead2();
     }
     sendValue(value);  
   }
   break;
   case  GYRO:{
       gyro.update();
       if(slot==1){
         value = gyro.getAngleX();
         sendValue(value);
       }else if(slot==2){
         value = gyro.getAngleY();
         sendValue(value);
       }else if(slot==3){
         value = gyro.getAngleZ();
         sendValue(value);
       }
   }
   break;
   case  VERSION:{
     sendValue(mVersion);
   }
   break;
   case  DIGITAL:{
     pinMode(pin,INPUT);
     sendValue(digitalRead(pin));
   }
   break;
   case  ANALOG:{
     pin = analogs[pin];
     pinMode(pin,INPUT);
     sendValue(analogRead(pin));
   }
   break;
  }
}
