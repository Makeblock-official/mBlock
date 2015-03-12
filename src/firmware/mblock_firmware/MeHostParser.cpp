// MeHostParser.cpp

#include "MeHostParser.h"

#define HEAD    0xA5
#define TAIL    0x5A

//  states
#define ST_WAIT_4_START     0x01
#define ST_HEAD_READ        0x02
#define ST_MODULE_READ      0x03
#define ST_LENGTH_READ      0x04
#define ST_DATA_READ        0x05
#define ST_CHECK_READ       0x06

MeHostParser::MeHostParser()
{
    state = ST_WAIT_4_START;
    in = 0;
    out = 0;
    packageReady = 0;

    module = 0;
    length = 0;
    data = NULL;
    check = 0;

    lengthRead = 0;
    currentDataPos = 0;
}

MeHostParser::~MeHostParser()
{
    ;
}

uint8_t MeHostParser::getPackageReady()
{
    return (1 == packageReady);
}

uint8_t MeHostParser::pushStr(uint8_t * str, uint32_t length)
{
    if (length > ((in + BUF_SIZE - out - 1) & MASK))
    {
        return 0;
    }
    else
    {
        for (int i = 0; i < length; ++i)
        {
            pushByte(str[i]);
        }
    }
}

uint8_t MeHostParser::pushByte(uint8_t ch)
{
    if (((in + 1) & MASK) != out)
    {
        buffer[in] = ch;
        ++in;
        in &= MASK;
        return 1;
    }
    else
    {
        return 0;
    }
}

uint8_t MeHostParser::getByte(uint8_t * ch)
{
    if (in != out)
    {
        *ch = buffer[out];
        ++out;
        out &= MASK;
        return 1;
    }
    else
    {
        // Serial.println("GET error!");
        return 0;
    }
}

uint8_t calculateLRC(uint8_t *data, uint32_t length)
{
    uint8_t LRC = 0;
    for (uint32_t i = 0; i < length; ++i)
    {
        LRC ^= data[i];
    }
    return LRC;
}

uint8_t MeHostParser::run(void)
{
    uint8_t ch = 0;
    while (getByte(&ch))
    {
        switch (state)
        {
        case ST_WAIT_4_START:
            if (HEAD == ch)
            {
                state = ST_HEAD_READ;
            }
            break;
        case ST_HEAD_READ:
            module = ch;
            state = ST_MODULE_READ;
            break;
        case ST_MODULE_READ:
            //  read 4 bytes as "length"
            *(((uint8_t *)&length) + lengthRead) = ch;
            ++lengthRead;
            if (4 == lengthRead)
            {
                lengthRead = 0;
                state = ST_LENGTH_READ;
            }
            break;
        case ST_LENGTH_READ:
            //  alloc space for data
            if (0 == currentDataPos)
            {
                if (length > 255)
                {
                    state = ST_WAIT_4_START;
                    currentDataPos = 0;
                    lengthRead = 0;
                    length = 0;
                    module = 0;
                    check = 0;
                    break;
                }
                data = (uint8_t *)malloc(length + 1);
                if (NULL == data)
                {
                    state = ST_WAIT_4_START;
                    currentDataPos = 0;
                    lengthRead = 0;
                    length = 0;
                    module = 0;
                    check = 0;
                    break;
                }
            }
            //  read data
            data[currentDataPos] = ch;
            ++currentDataPos;
            if (currentDataPos == length)
            {
                currentDataPos = 0;
                state = ST_DATA_READ;
            }
            break;
        case ST_DATA_READ:
            check = ch;
            if (check != calculateLRC(data, length))
            {
                state = ST_WAIT_4_START;
                if (NULL != data)
                {
                    free(data);
                    data = NULL;
                }
                currentDataPos = 0;
                lengthRead = 0;
                length = 0;
                module = 0;
                check = 0;
            }
            else
            {
                state = ST_CHECK_READ;
            }
            break;
        case ST_CHECK_READ:
            if (TAIL != ch)
            {
                if (NULL != data)
                {
                    free(data);
                    data = NULL;
                }
                length = 0;
            }
            else
            {
                packageReady = 1;
            }
            state = ST_WAIT_4_START;
            currentDataPos = 0;
            lengthRead = 0;
            module = 0;
            check = 0;
            break;
        default:
            break;
        }
    }
    return state;
}



uint8_t MeHostParser::getData(uint8_t *buf, uint32_t size)
{
    int copySize = (size > length) ? length : size;
    if ((NULL != data) && (NULL != buf))
    {
        memcpy(buf, data, copySize);
        free(data);
        data = NULL;
        length = 0;
        packageReady = 0;

        return copySize;
    }
    else
    {
        return 0;
    }
}
