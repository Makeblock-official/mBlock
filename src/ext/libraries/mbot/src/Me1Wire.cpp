#include "Me1Wire.h"

Me1Wire::Me1Wire(){
}
Me1Wire::Me1Wire(uint8_t pin)
{
	bitmask = MePIN_TO_BITMASK(pin);
	baseReg = MePIN_TO_BASEREG(pin);
	// reset_search();
}
void Me1Wire::reset(uint8_t pin)
{
	bitmask = MePIN_TO_BITMASK(pin);
	baseReg = MePIN_TO_BASEREG(pin);
	// reset_search();
}
bool Me1Wire::readIO(void)
{
	MeIO_REG_TYPE mask = bitmask;
	volatile MeIO_REG_TYPE *reg MeIO_REG_ASM = baseReg;
	uint8_t r;
	MeDIRECT_MODE_INPUT(reg, mask);	// allow it to float
	delayMicroseconds(10);
	r = MeDIRECT_READ(reg, mask);
	return r;
}
// Perform the Me1Wire reset function. We will wait up to 250uS for
// the bus to come high, if it doesn't then it is broken or shorted
// and we return a 0;
//
// Returns 1 if a device asserted a presence pulse, 0 otherwise.
//
uint8_t Me1Wire::reset(void)
{
	MeIO_REG_TYPE mask = bitmask;
	volatile MeIO_REG_TYPE *reg MeIO_REG_ASM = baseReg;
	uint8_t r;
	uint8_t retries = 125;
	noInterrupts();
	MeDIRECT_MODE_INPUT(reg, mask);
	interrupts();
	// wait until the wire is high... just in case
	do {
		if (--retries == 0) return 0;
		delayMicroseconds(2);
	} while ( !MeDIRECT_READ(reg, mask));
	noInterrupts();
	MeDIRECT_WRITE_LOW(reg, mask);
	MeDIRECT_MODE_OUTPUT(reg, mask);	// drive output low
	interrupts();
	delayMicroseconds(480);
	noInterrupts();
	MeDIRECT_MODE_INPUT(reg, mask);	// allow it to float
	delayMicroseconds(70);
	r = !MeDIRECT_READ(reg, mask);
	interrupts();
	delayMicroseconds(410);
	return r;
}
//
// Write a bit. Port and bit is used to cut lookup time and provide
// more certain timing.
//
void Me1Wire::write_bit(uint8_t v)
{
	MeIO_REG_TYPE mask=bitmask;
	volatile MeIO_REG_TYPE *reg MeIO_REG_ASM = baseReg;
	if (v & 1) {
		noInterrupts();
		MeDIRECT_WRITE_LOW(reg, mask);
		MeDIRECT_MODE_OUTPUT(reg, mask);	// drive output low
		delayMicroseconds(10);
		MeDIRECT_WRITE_HIGH(reg, mask);	// drive output high
		interrupts();
		delayMicroseconds(55);
	} else {
		noInterrupts();
		MeDIRECT_WRITE_LOW(reg, mask);
		MeDIRECT_MODE_OUTPUT(reg, mask);	// drive output low
		delayMicroseconds(65);
		MeDIRECT_WRITE_HIGH(reg, mask);	// drive output high
		interrupts();
		delayMicroseconds(5);
	}
}
//
// Read a bit. Port and bit is used to cut lookup time and provide
// more certain timing.
//
uint8_t Me1Wire::read_bit(void)
{
	MeIO_REG_TYPE mask=bitmask;
	volatile MeIO_REG_TYPE *reg MeIO_REG_ASM = baseReg;
	uint8_t r;
	noInterrupts();
	MeDIRECT_MODE_OUTPUT(reg, mask);
	MeDIRECT_WRITE_LOW(reg, mask);
	delayMicroseconds(3);
	MeDIRECT_MODE_INPUT(reg, mask);	// let pin float, pull up will raise
	delayMicroseconds(10);
	r = MeDIRECT_READ(reg, mask);
	interrupts();
	delayMicroseconds(53);
	return r;
}
//
// Write a byte. The writing code uses the active drivers to raise the
// pin high, if you need power after the write (e.g. DS18S20 in
// parasite power mode) then set 'power' to 1, otherwise the pin will
// go tri-state at the end of the write to avoid heating in a short or
// other mishap.
//
void Me1Wire::write(uint8_t v, uint8_t power /* = 0 */) {
	uint8_t bitMask;
	for (bitMask = 0x01; bitMask; bitMask <<= 1) {
		Me1Wire::write_bit( (bitMask & v)?1:0);
	}
	if ( !power) {
		noInterrupts();
		MeDIRECT_MODE_INPUT(baseReg, bitmask);
		MeDIRECT_WRITE_LOW(baseReg, bitmask);
		interrupts();
	}
}
void Me1Wire::write_bytes(const uint8_t *buf, uint16_t count, bool power /* = 0 */) {
	for (uint16_t i = 0 ; i < count ; i++)
		write(buf[i]);
	if (!power) {
		noInterrupts();
		MeDIRECT_MODE_INPUT(baseReg, bitmask);
		MeDIRECT_WRITE_LOW(baseReg, bitmask);
		interrupts();
	}
}
//
// Read a byte
//
uint8_t Me1Wire::read() {
	uint8_t bitMask;
	uint8_t r = 0;
	for (bitMask = 0x01; bitMask; bitMask <<= 1) {
		if ( Me1Wire::read_bit()) r |= bitMask;
	}
	return r;
}
void Me1Wire::read_bytes(uint8_t *buf, uint16_t count) {
	for (uint16_t i = 0 ; i < count ; i++)
		buf[i] = read();
}
//
// Do a ROM select
//
void Me1Wire::select(const uint8_t rom[8])
{
	uint8_t i;
	write(0x55); // Choose ROM
	for (i = 0; i < 8; i++) write(rom[i]);
}
//
// Do a ROM skip
//
void Me1Wire::skip()
{
	write(0xCC); // Skip ROM
}
void Me1Wire::depower()
{
	noInterrupts();
	MeDIRECT_MODE_INPUT(baseReg, bitmask);
	interrupts();
}
void Me1Wire::reset_search()
{
	// reset the search state
	LastDiscrepancy = 0;
	LastDeviceFlag = false;
	LastFamilyDiscrepancy = 0;
	for(int i = 7; ; i--) {
		ROM_NO[i] = 0;
		if ( i == 0) break;
	}
}
// Setup the search to find the device type 'family_code' on the next call
// to search(*newAddr) if it is present.
//
void Me1Wire::target_search(uint8_t family_code)
{
	// set the search state to find SearchFamily type devices
	ROM_NO[0] = family_code;
	for (uint8_t i = 1; i < 8; i++)
		ROM_NO[i] = 0;
	LastDiscrepancy = 64;
	LastFamilyDiscrepancy = 0;
	LastDeviceFlag = false;
}
//
// Perform a search. If this function returns a '1' then it has
// enumerated the next device and you may retrieve the ROM from the
// Me1Wire::address variable. If there are no devices, no further
// devices, or something horrible happens in the middle of the
// enumeration then a 0 is returned. If a new device is found then
// its address is copied to newAddr. Use Me1Wire::reset_search() to
// start over.
//
// --- Replaced by the one from the Dallas Semiconductor web site ---
//--------------------------------------------------------------------------
// Perform the 1-Wire Search Algorithm on the 1-Wire bus using the existing
// search state.
// Return true : device found, ROM number in ROM_NO buffer
// false : device not found, end of search

uint8_t Me1Wire::search(uint8_t *newAddr)
{
	uint8_t id_bit_number;
	uint8_t last_zero, rom_byte_number, search_result;
	uint8_t id_bit, cmp_id_bit;
	unsigned char rom_byte_mask, search_direction;
	// initialize for search
	id_bit_number = 1;
	last_zero = 0;
	rom_byte_number = 0;
	rom_byte_mask = 1;
	search_result = 0;
	// if the last call was not the last one
	if (!LastDeviceFlag)
	{
	// 1-Wire reset
		if (!reset())
		{
		// reset the search
			LastDiscrepancy = 0;
			LastDeviceFlag = false;
			LastFamilyDiscrepancy = 0;
			return false;
		}
		// issue the search command
		write(0xF0);
		// loop to do the search
		do
		{
			// read a bit and its complement
			id_bit = read_bit();
			cmp_id_bit = read_bit();
			// check for no devices on 1-wire
			if ((id_bit == 1) && (cmp_id_bit == 1))
				break;
			else
			{
				// all devices coupled have 0 or 1
				if (id_bit != cmp_id_bit)
				search_direction = id_bit; // bit write value for search
				else
				{
					// if this discrepancy if before the Last Discrepancy
					// on a previous next then pick the same as last time
					if (id_bit_number < LastDiscrepancy)
					search_direction = ((ROM_NO[rom_byte_number] & rom_byte_mask) > 0);
					else
					// if equal to last pick 1, if not then pick 0
					search_direction = (id_bit_number == LastDiscrepancy);
					// if 0 was picked then record its position in LastZero
					if (search_direction == 0)
					{
						last_zero = id_bit_number;
						// check for Last discrepancy in family
						if (last_zero < 9)
							LastFamilyDiscrepancy = last_zero;
					}
				}
				// set or clear the bit in the ROM byte rom_byte_number
				// with mask rom_byte_mask
				if (search_direction == 1)
					ROM_NO[rom_byte_number] |= rom_byte_mask;
				else
					ROM_NO[rom_byte_number] &= ~rom_byte_mask;
				// serial number search direction write bit
				write_bit(search_direction);
				// increment the byte counter id_bit_number
				// and shift the mask rom_byte_mask
				id_bit_number++;
				rom_byte_mask <<= 1;
				// if the mask is 0 then go to new SerialNum byte rom_byte_number and reset mask
				if (rom_byte_mask == 0)
				{
				rom_byte_number++;
				rom_byte_mask = 1;
				}
			}
		}
		while(rom_byte_number < 8); // loop until through all ROM bytes 0-7
		// if the search was successful then
		if (!(id_bit_number < 65))
		{
			// search successful so set LastDiscrepancy,LastDeviceFlag,search_result
			LastDiscrepancy = last_zero;
			// check for last device
			if (LastDiscrepancy == 0)
				LastDeviceFlag = true;
			search_result = true;
		}
	}
	// if no device found then reset counters so next 'search' will be like a first
	if (!search_result || !ROM_NO[0])
	{
		LastDiscrepancy = 0;
		LastDeviceFlag = false;
		LastFamilyDiscrepancy = 0;
		search_result = false;
	}
	for (int i = 0; i < 8; i++) newAddr[i] = ROM_NO[i];
	return search_result;
}
