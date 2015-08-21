#include "MeIR.h"

// Provides ISR
#include <avr/interrupt.h>

volatile irparams_t irparams;
bool MATCH(uint8_t measured_ticks, uint8_t desired_us)
{
	// Serial.print(measured_ticks);Serial.print(",");Serial.println(desired_us);
	return(measured_ticks >= desired_us - (desired_us>>2)-1 && measured_ticks <= desired_us + (desired_us>>2)+1);//判断前后25%的误差
}

ISR(TIMER_INTR_NAME)
{
  uint8_t irdata = (uint8_t)digitalRead(2);
  // uint32_t new_time = micros();
  // uint8_t timer = (new_time - irparams.lastTime)>>6;
  irparams.timer++; // One more 50us tick
  if (irparams.rawlen >= RAWBUF) {
    // Buffer overflow
    irparams.rcvstate = STATE_STOP;
  }
  switch(irparams.rcvstate) {
  case STATE_IDLE: // In the middle of a gap
    if (irdata == MARK) {
        irparams.rawlen = 0;
        irparams.timer = 0;
        irparams.rcvstate = STATE_MARK; 
    }
    break;
  case STATE_MARK: // timing MARK
    if (irdata == SPACE) {   // MARK ended, record time
      irparams.rawbuf[irparams.rawlen++] = irparams.timer;
      irparams.timer = 0;
      irparams.rcvstate = STATE_SPACE;
    }
    break;
  case STATE_SPACE: // timing SPACE
    if (irdata == MARK) { // SPACE just ended, record it
      irparams.rawbuf[irparams.rawlen++] = irparams.timer;
      irparams.timer = 0;
      irparams.rcvstate = STATE_MARK;
    }
    else { // SPACE
      if (irparams.timer > GAP_TICKS) {
        // big SPACE, indicates gap between codes
        // Mark current code as ready for processing
        // Switch to STOP
        // Don't reset timer; keep counting space width
        irparams.rcvstate = STATE_STOP;
      } 
    }
    break;
  case STATE_STOP: // waiting, measuring gap
    if (irdata == MARK) { // reset gap timer
      irparams.timer = 0;
    }
    break;
  }
  // irparams.lastTime = new_time;
}

MeIR::MeIR()
{
  pinMode(2,INPUT);
  // attachInterrupt(INT0, irISR, CHANGE);
  
  lastIRTime = 0.0;
  irDelay = 0;
  irIndex = 0;
  irRead = 0;
  irReady = false;
  irBuffer = "";
  irPressed = false;
  begin();
  pinMode(3, OUTPUT);
  digitalWrite(3, LOW); // When not sending PWM, we want it low
}

void MeIR::begin()
{
  cli();
  // setup pulse clock timer interrupt
  //Prescale /8 (16M/8 = 0.5 microseconds per tick)
  // Therefore, the timer interval can range from 0.5 to 128 microseconds
  // depending on the reset value (255 to 0)
  TIMER_CONFIG_NORMAL();

  //Timer2 Overflow Interrupt Enable
  TIMER_ENABLE_INTR;

  // TIMER_RESET;

  sei();  // enable interrupts

  // initialize state machine variables
  irparams.rcvstate = STATE_IDLE;
  irparams.rawlen = 0;

  // set pin modes
  // pinMode(2, INPUT);
  // pinMode(irparams.recvpin, INPUT);
}

void MeIR::end() {
	EIMSK &= ~(1 << INT0);
}




// Decodes the received IR message
// Returns 0 if no data ready, 1 if data ready.
// Results of decoding are stored in results
ErrorStatus MeIR::decode() {
  rawbuf = irparams.rawbuf;
  rawlen = irparams.rawlen;
  // if(irparams.rcvstate == STATE_SPACE)
  // 	{
  // 		uint32_t time = micros() -irparams.lastTime;
  // 		if(time> _GAP && time < _GAP+1000)
  // 		{
	 //  		irparams.rcvstate = STATE_STOP;
  // 		}
  // 	}
  if (irparams.rcvstate != STATE_STOP) {
    return ERROR;
  }

  if (decodeNEC()) {
  	begin();
    return SUCCESS;
  }
  begin();
  return ERROR;
}

// NECs have a repeat only 4 items long
ErrorStatus MeIR::decodeNEC() {
  uint32_t data = 0;
  int offset = 0; // Skip first space
  // Initial mark
  if (!MATCH(rawbuf[offset], NEC_HDR_MARK/50)) {
    return ERROR;
  }
  offset++;
  // Check for repeat
  if (rawlen == 3 &&
    MATCH(rawbuf[offset], NEC_RPT_SPACE/50) &&
    MATCH(rawbuf[offset+1], NEC_BIT_MARK/50)) {
    bits = 0;
    // results->value = REPEAT;
	// Serial.println("REPEAT");
	decode_type = NEC;
    return SUCCESS;
  }
  if (rawlen < 2 * NEC_BITS + 3) {
    return ERROR;
  }
  // Initial space  
  if (!MATCH(rawbuf[offset], NEC_HDR_SPACE/50)) {
    return ERROR;
  }
  offset++;
  for (int i = 0; i < NEC_BITS; i++) {
    if (!MATCH(rawbuf[offset], NEC_BIT_MARK/50)) {
      return ERROR;
    }
    offset++;
    if (MATCH(rawbuf[offset], NEC_ONE_SPACE/50)) {
      //data = (data << 1) | 1;
      data = (data >> 1) | 0x80000000;
    } 
    else if (MATCH(rawbuf[offset], NEC_ZERO_SPACE/50)) {
      //data <<= 1;
      data >>= 1;
    } 
    else {
      return ERROR;
      
    }
    offset++;
  }
  // Success
  bits = NEC_BITS;
  value = data;
  decode_type = NEC;
  return SUCCESS;
}

void MeIR::mark(uint16_t us) {
  // Sends an IR mark for the specified number of microseconds.
  // The mark output is modulated at the PWM frequency.
    TIMER_ENABLE_PWM; // Enable pin 3 PWM output
    delayMicroseconds(us);
}

/* Leave pin off for time (given in microseconds) */
void MeIR::space(uint16_t us) {
  // Sends an IR space for the specified number of microseconds.
  // A space is no output, so the PWM output is disabled.
  TIMER_DISABLE_PWM; // Disable pin 3 PWM output
  delayMicroseconds(us);
}

void MeIR::enableIROut(uint8_t khz) {
  TIMER_DISABLE_INTR; //Timer2 disable Interrupt
  TIMER_CONFIG_KHZ(khz);
}

void MeIR::sendRaw(unsigned int buf[], int len, uint8_t hz)
{
  enableIROut(hz);
  for (int i = 0; i < len; i++) {
    if (i & 1) {
      space(buf[i]);
    } 
    else {
      mark(buf[i]);
    }
  }
  space(0); // Just to be sure
}
String MeIR::getString(){
  if(decode())
  {
    irRead = ((value>>8)>>8)&0xff;
    if(irRead==0xa||irRead==0xd){
      irIndex = 0;
      irReady = true;
    }else{
      irBuffer+=irRead; 
      irIndex++;
    }
    irDelay = 0;
  }else{
    irDelay++;
    if(irRead>0){
     if(irDelay>5000){
      irRead = 0;
      irDelay = 0;
     }
   }
  }
  if(irReady){
    irReady = false;
    String s = String(irBuffer);
    irBuffer = "";
    return s;
  }
  return "";
}
unsigned char MeIR::getCode(){
  if(decode())
  {
    irRead = ((value>>8)>>8)&0xff;
  }
  return irRead;
}
void MeIR::sendString(String s){
  unsigned long l;
  for(int i=0;i<s.length();i++){
    l = 0xff000000+s.charAt(i);
    sendNEC(((l<<8)<<8),32);
    delay(6);
  }
  l = 0xff000000+'\n';
  sendNEC((l<<8)<<8,32);
  delay(6);
}

void MeIR::sendString(float v){
  dtostrf(v,5, 2, floatString);
  sendString(floatString);
}
void MeIR::sendNEC(unsigned long data, int nbits)
{
  enableIROut(38);
  mark(NEC_HDR_MARK);
  space(NEC_HDR_SPACE);
  for (int i = 0; i < nbits; i++) {
    if (data & 1) {
      mark(NEC_BIT_MARK);
      space(NEC_ONE_SPACE);
    } 
    else {
      mark(NEC_BIT_MARK);
      space(NEC_ZERO_SPACE);
    }
    data >>= 1;
  }
  mark(NEC_BIT_MARK);
  space(0);
}
void MeIR::loop(){
  if(decode())
  {
    irRead = ((value>>8)>>8)&0xff;
    lastIRTime = millis()/1000.0;
    irPressed = true;
    if(irRead==0xa||irRead==0xd){
      irIndex = 0;
      irReady = true;
    }else{
      irBuffer+=irRead; 
      irIndex++;
      if(irIndex>64){
        irIndex = 0;
        irBuffer = "";
      }
    }
    irDelay = 0;
  }else{
    irDelay++;
    if(irRead>0){
     if(irDelay>5000){
      irRead = 0;
      irDelay = 0;
     }
   }
  }
}
boolean MeIR::keyPressed(unsigned char r){
	irIndex = 0;
     if(millis()/1000.0-lastIRTime>0.2){
		MeIR::loop();
        return false;
     }
	 return irRead==r;
}
