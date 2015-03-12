#include "Me7SegmentDisplay.h"
static int8_t TubeTab[] = {0x3f,0x06,0x5b,0x4f,
							0x66,0x6d,0x7d,0x07,
							0x7f,0x6f,0x77,0x7c,
							0x39,0x5e,0x79,0x71,
							0xbf,0x86,0xdb,0xcf,
							0xe6,0xed,0xfd,0x87,
							0xff,0xef,0xf7,0xfc,
							0xb9,0xde,0xf9,0xf1,0x40};//0~9,A,b,C,d,E,F,-
Me7SegmentDisplay::Me7SegmentDisplay():MePort()
{
}
Me7SegmentDisplay::Me7SegmentDisplay(uint8_t port):MePort(port)
{
	Clkpin = s2;
	Datapin = s1;
	pinMode(Clkpin,OUTPUT);
	pinMode(Datapin,OUTPUT);
	set();
	clearDisplay();
}
void Me7SegmentDisplay::reset(uint8_t port){
        _port = port;
	s2 = mePort[port].s2;
	s1 = mePort[port].s1;
	Clkpin = s2;
	Datapin = s1;
	pinMode(Clkpin,OUTPUT);
	pinMode(Datapin,OUTPUT);
	set();
	clearDisplay();
}
void Me7SegmentDisplay::init(void)
{
	clearDisplay();
}
void Me7SegmentDisplay::writeByte(int8_t wr_data)
{
	uint8_t i,count1;
	for(i=0;i<8;i++) //sent 8bit data
	{
		digitalWrite(Clkpin,LOW);
		if(wr_data & 0x01)digitalWrite(Datapin,HIGH);//LSB first
		else digitalWrite(Datapin,LOW);
		wr_data >>= 1;
		digitalWrite(Clkpin,HIGH);
	}
	digitalWrite(Clkpin,LOW); //wait for the ACK
	digitalWrite(Datapin,HIGH);
	digitalWrite(Clkpin,HIGH);
	pinMode(Datapin,INPUT);
	while(digitalRead(Datapin))
	{
		count1 +=1;
		if(count1 == 200)//
		{
			pinMode(Datapin,OUTPUT);
			digitalWrite(Datapin,LOW);
			count1 =0;
		}
	}
	pinMode(Datapin,OUTPUT);
}
//send start signal to TM1637
void Me7SegmentDisplay::start(void)
{
	digitalWrite(Clkpin,HIGH);//send start signal to TM1637
	digitalWrite(Datapin,HIGH);
	digitalWrite(Datapin,LOW);
	digitalWrite(Clkpin,LOW);
}
//End of transmission
void Me7SegmentDisplay::stop(void)
{
	digitalWrite(Clkpin,LOW);
	digitalWrite(Datapin,LOW);
	digitalWrite(Clkpin,HIGH);
	digitalWrite(Datapin,HIGH);
}
void Me7SegmentDisplay::display(float value){
	int i=0;
	bool isStart = false;
	int index = 0;
	int8_t disp[]={0,0,0,0};
	bool isNeg = false;
	if(value<0){
		isNeg = true;
		value = -value;
		disp[0] = 0x20;
		index++;
	}
	for(i=0;i<7;i++){
		int n = checkNum(value,3-i);
		if(n>=1||i==3){
			isStart=true;
		}
		if(isStart){
			if(i==3){
				disp[index]=n+0x10;
			}else{
				disp[index]=n;
			}
			index++;
		}
		if(index>3){
			break;
		}
	}
	display(disp);
}
int Me7SegmentDisplay::checkNum(float v,int b){
	if(b>=0){
		return floor((v-floor(v/pow(10,b+1))*(pow(10,b+1)))/pow(10,b));
	}else{
		b=-b;
		int i=0;
		for(i=0;i<b;i++){
			v = v*10;
		}
		return ((int)(v)%10);
	}
}
void Me7SegmentDisplay::display(int8_t DispData[])
{
	int8_t SegData[4];
	uint8_t i;
	for(i = 0;i < 4;i ++)
	{
		SegData[i] = DispData[i];
	}
	coding(SegData);
	start(); //start signal sent to TM1637 from MCU
	writeByte(ADDR_AUTO);//
	stop(); //
	start(); //
	writeByte(Cmd_SetAddr);//
	for(i=0;i < 4;i ++)
	{
		writeByte(SegData[i]); //
	}
	stop(); //
	start(); //
	writeByte(Cmd_DispCtrl);//
	stop(); //
}
//******************************************
void Me7SegmentDisplay::display(uint8_t BitAddr,int8_t DispData)
{
	int8_t SegData;
	SegData = coding(DispData);
	start(); //start signal sent to TM1637 from MCU
	writeByte(ADDR_FIXED);//
	stop(); //
	start(); //
	writeByte(BitAddr|0xc0);//
	writeByte(SegData);//
	stop(); //
	start(); //
	writeByte(Cmd_DispCtrl);//
	stop(); //
}
void Me7SegmentDisplay::clearDisplay(void)
{
	display(0x00,0x7f);
	display(0x01,0x7f);
	display(0x02,0x7f);
	display(0x03,0x7f);
}
//To take effect the next time it displays.
void Me7SegmentDisplay::set(uint8_t brightness,uint8_t SetData,uint8_t SetAddr)
{
	Cmd_SetData = SetData;
	Cmd_SetAddr = SetAddr;
	Cmd_DispCtrl = 0x88 + brightness;//Set the brightness and it takes effect the next time it displays.
}
void Me7SegmentDisplay::coding(int8_t DispData[])
{
	uint8_t PointData = 0;
	for(uint8_t i = 0;i < 4;i ++)
	{
		if(DispData[i] == 0x7f)DispData[i] = 0x00;
		else DispData[i] = TubeTab[DispData[i]];
	}
}
int8_t Me7SegmentDisplay::coding(int8_t DispData)
{
	uint8_t PointData = 0;
	if(DispData == 0x7f) DispData = 0x00 + PointData;//The bit digital tube off
	else DispData = TubeTab[DispData] + PointData;
	return DispData;
} 
