#ifndef MeHostParser_h
#define MeHostParser_h
#include <Arduino.h>
#define BUF_SIZE            256
#define MASK                255

class MeHostParser
{
public:
    MeHostParser();
    ~MeHostParser();

    //  push data to buffer
    uint8_t pushStr(uint8_t * str, uint32_t length);
    uint8_t pushByte(uint8_t ch);
    //  run state machine
    uint8_t run();
    //  get the package ready state
    uint8_t getPackageReady();
    //  copy data to user's buffer
    uint8_t getData(uint8_t *buf, uint32_t size);

    void print(char *str, uint32_t * cnt);
private:
    int state;
    uint8_t buffer[BUF_SIZE];
    uint32_t in;
    uint32_t out;
    uint8_t packageReady;

    uint8_t module;
    uint32_t length;
    uint8_t *data;
    uint8_t check;

    uint32_t lengthRead;
    uint32_t currentDataPos;

    uint8_t getByte(uint8_t * ch);
};


#endif 
