// MeEncoderMotor.cpp

#include "MeEncoderMotor.h"
#include "MeHostParser.h"
//  frame type
#define ENCODER_MOTOR_GET_PARAM     0x01
#define ENCODER_MOTOR_SAVE_PARAM    0x02
#define ENCODER_MOTOR_TEST_PARAM    0x03
#define ENCODER_MOTOR_SHOW_PARAM    0x04
#define ENCODER_MOTOR_RUN_STOP      0x05
#define ENCODER_MOTOR_GET_DIFF_POS  0x06
#define ENCODER_MOTOR_RESET         0x07
#define ENCODER_MOTOR_SPEED_TIME    0x08
#define ENCODER_MOTOR_GET_SPEED     0x09
#define ENCODER_MOTOR_GET_POS       0x10
#define ENCODER_MOTOR_MOVE          0x11
#define ENCODER_MOTOR_MOVE_TO       0x12
#define ENCODER_MOTOR_DEBUG_STR     0xCC
#define ENCODER_MOTOR_ACKNOWLEDGE   0xFF

MeHostParser encoderParser = MeHostParser();

//  function:       pack data into a package to send
//  param:  buf     buffer to save package
//          bufSize size of buf
//          module  the associated module of package
//          data    the data to pack
//          length  the length(size) of data
//  return: 0       error
//          other   package size
uint32_t MeHost_Pack(uint8_t * buf,
                     uint32_t bufSize, 
                     uint8_t module, 
                     uint8_t * data, 
                     uint32_t length)
{
    uint32_t i = 0;

    //  head: 0xA5
    buf[i++] = 0xA5;
    buf[i++] = module;
    //  pack length
    buf[i++] = *((uint8_t *)&length + 0);
    buf[i++] = *((uint8_t *)&length + 1);
    buf[i++] = *((uint8_t *)&length + 2);
    buf[i++] = *((uint8_t *)&length + 3);
    //  pack data
    for(uint32_t j = 0; j < length; ++j)
    {
        buf[i++] = data[j];
    }

    //  calculate the LRC
    uint8_t check = 0x00;
    for(uint32_t j = 0; j < length; ++j)
    {
        check ^= data[j];
    }
    buf[i++] = check;

    //  tail: 0x5A
    buf[i++] = 0x5A;

    if (i > bufSize)
    {
        return 0;
    }
    else
    {
        return i;
    }
}

/*          EncoderMotor        */
MeEncoderMotor::MeEncoderMotor(uint8_t addr,uint8_t slot):MeWire(addr - 1)
{
    _slot = slot - 1;
}
MeEncoderMotor::MeEncoderMotor(uint8_t slot):MeWire(0x8)
{
    _slot = slot - 1;
}
MeEncoderMotor::MeEncoderMotor():MeWire(0x8){
  _slot = 0;
}
void MeEncoderMotor::begin()
{
    MeWire::begin();
    reset();
}

boolean MeEncoderMotor::reset()
{
    uint8_t w[10] = {0};
    uint8_t r[10] = {0};

    uint8_t data[2] = {0};
    data[0] = _slot;
    data[1] = ENCODER_MOTOR_RESET;

    MeHost_Pack(w, 10, 0x01, data, 2);
    request(w, r, 10, 10);
    encoderParser.pushStr(r, 10);

    uint8_t ack[2] = {0};
    encoderParser.getData(ack, 2);
    return ack[1];
}

boolean MeEncoderMotor::moveTo(float angle, float speed)
{
    uint8_t w[18] = {0};
    uint8_t r[10] = {0};

    uint8_t data[10] = {0};
    data[0] = _slot;
    data[1] = ENCODER_MOTOR_MOVE_TO;
    *((float *)(data + 2)) = angle;
    *((float *)(data + 6)) = speed;

    MeHost_Pack(w, 18, 0x01, data, 10);
    request(w, r, 18, 10);
    encoderParser.pushStr(r, 10);
    encoderParser.run();

    uint8_t ack[2] = {0};
    encoderParser.getData(ack, 2);
    return ack[1];
}

boolean MeEncoderMotor::move(float angle, float speed)
{
	if(angle==0){
		return runSpeed(speed);
	}
    uint8_t w[18] = {0};
    uint8_t r[10] = {0};

    uint8_t data[10] = {0};
    data[0] = _slot;
    data[1] = ENCODER_MOTOR_MOVE;
    *((float *)(data + 2)) = angle;
    *((float *)(data + 6)) = speed;

    MeHost_Pack(w, 18, 0x01, data, 10);
    request(w, r, 18, 10);
    encoderParser.pushStr(r, 10);
    encoderParser.run();

    uint8_t ack[2] = {0};
    encoderParser.getData(ack, 2);
    return ack[1];
}

boolean MeEncoderMotor::runTurns(float turns, float speed)
{
    return move(turns * 360, speed);
}

boolean MeEncoderMotor::runSpeed(float speed)
{
    uint8_t w[14] = {0};
    uint8_t r[10] = {0};

    uint8_t data[6] = {0};
    data[0] = _slot;
    data[1] = ENCODER_MOTOR_RUN_STOP;
    *((float *)(data + 2)) = speed;

    MeHost_Pack(w, 14, 0x01, data, 6);
    request(w, r, 14, 10);
    encoderParser.pushStr(r, 10);
    encoderParser.run();

    // uint8_t ack[2] = {0};
    // encoderParser.GetData(ack, 2);
    // return ack[1];
    return 0;
}

boolean MeEncoderMotor::runSpeedAndTime(float speed, float time)
{
    uint8_t w[18] = {0};
    uint8_t r[10] = {0};

    uint8_t data[10] = {0};
    data[0] = _slot;
    data[1] = ENCODER_MOTOR_SPEED_TIME;
    *((float *)(data + 2)) = speed;
    *((float *)(data + 6)) = time;

    MeHost_Pack(w, 18, 0x01, data, 10);
    request(w, r, 18, 10);
    encoderParser.pushStr(r, 10);
    encoderParser.run();

    // uint8_t ack[2] = {0};
    // encoderParser.GetData(ack, 2);
    // return ack[1];
    return 0;
}

float MeEncoderMotor::getCurrentSpeed()
{
    uint8_t w[10] = {0};
    uint8_t r[14] = {0};

    uint8_t data[2] = {0};
    data[0] = _slot;
    data[1] = ENCODER_MOTOR_GET_SPEED;

    MeHost_Pack(w, 10, 0x01, data, 2);
    request(w, r, 10, 14);
    encoderParser.pushStr(r, 14);
    encoderParser.run();

    uint8_t temp[6] = {0};
    encoderParser.getData(temp, 6);
    float speed = *((float *)(temp + 2));
    return speed;
}

float MeEncoderMotor::getCurrentPosition()
{
    uint8_t w[10] = {0};
    uint8_t r[14] = {0};

    uint8_t data[2] = {0};
    data[0] = _slot;
    data[1] = ENCODER_MOTOR_GET_POS;

    MeHost_Pack(w, 10, 0x01, data, 2);
    request(w, r, 10, 14);
    encoderParser.pushStr(r, 14);

    encoderParser.run();

    uint8_t temp[6] = {0};
    uint8_t size = encoderParser.getData(temp, 6);
    float pos = *((float *)(temp + 2));
    return pos;
}
