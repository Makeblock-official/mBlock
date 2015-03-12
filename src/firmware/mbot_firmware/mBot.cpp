#include "mBot.h"
#include "MePort.h"

#include "wiring_private.h"
#include "pins_arduino.h"

// MePort_Sig mePort[11] = {{NC, NC}, {11, 12}, {9, 10}, {A2, A3}, {A0, A1}, {NC, NC}, {NC, NC}, {NC, NC}, {NC, NC}, {6, 7}, {5, 4}};

MeBoard::MeBoard(uint8_t boards)
{
    MePort_Sig *port = &mePort[1];
     if(boards == mBot)//MePort_Sig mePort[] = {{NC, NC}, {11, 12}, {9, 10}, {A2, A3}, {A0, A1}};

    {
        port -> s1 = 11;//port1
        port -> s2 = 12;

        port++;
        port -> s1 = 9; //port2
        port -> s2 = 10;

        port++;
        port -> s1 = A2;//port3
        port -> s2 = A3;

        port++;
        port -> s1 = A0;//port4
        port -> s2 = A1;
        port++;
        port -> s1 = 6;//M1
        port -> s2 = 7;
        port++;
        port -> s1 = 5;//M2
        port -> s2 = 4;
		
        port++;
        port -> s1 = A7;//port7
        port -> s2 = 13;
		
        port++;
        port -> s1 = 8;//port8
        port -> s2 = A6;
        port++;
        port -> s1 = 6;//M1
        port -> s2 = 7;
        port++;
        port -> s1 = 5;//M2
        port -> s2 = 4;
    }
}

