#ifndef _ME_LED_MATRIX_H_
#define _ME_LED_MATRIX_H_

#include "MePort.h"
#define PointOn   1
#define PointOff  0


#define LED_BUFFER_SIZE   16
#define STRING_DISPLAY_BUFFER_SIZE 20


//Define Data Command Parameters
#define Mode_Address_Auto_Add_1  0x40     //0100 0000 B
#define Mode_Permanent_Address   0x44     //0100 0100 B


//Define Address Command Parameters
#define ADDRESS(addr)  (0xC0 | addr)


typedef enum
{
	Brightness_0 = 0,
	Brightness_1,
	Brightness_2,
	Brightness_3,
	Brightness_4,
	Brightness_5,
	Brightness_6,
	Brightness_7,
	Brightness_8
}LED_Matrix_Brightness_TypeDef;



/*           Me LED Matrix 8X16            */

class MeLEDMatrix:public MePort
{
public:
	MeLEDMatrix();
	MeLEDMatrix(uint8_t port);
	MeLEDMatrix(uint8_t SCK_Pin, uint8_t DIN_Pin);

	void clearScreen();
	void setBrightness(uint8_t Bright);
	void setColorIndex(bool Color_Number);
	void drawBitmap(int8_t x, int8_t y, uint8_t Bitmap_Width, uint8_t *Bitmap);
	void drawStr(int16_t X_position, int8_t Y_position, const char *str);
	void showClock(uint8_t hour, uint8_t minute, bool = PointOn);

private:

	bool b_Color_Index;
	bool b_Draw_Str_Flag;

	uint8_t u8_Display_Buffer[LED_BUFFER_SIZE];

	int16_t i16_Str_Display_X_Position;
	int8_t i8_Str_Display_Y_Position;
	int16_t i16_Number_of_Character_of_Str;
	char i8_Str_Display_Buffer[STRING_DISPLAY_BUFFER_SIZE];

	void writeByte(uint8_t data);
	void writeBytesToAddress(uint8_t Address, const uint8_t *P_data, uint8_t count_of_data);
	void showStr();

};

#endif
