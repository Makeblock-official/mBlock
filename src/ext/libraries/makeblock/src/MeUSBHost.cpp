#include "MeUSBHost.h"

#define p_dev_descr ((PUSB_DEV_DESCR)RECV_BUFFER)
#define p_cfg_descr ((PUSB_CFG_DESCR_LONG)RECV_BUFFER)

uint8_t endp_out_addr;
uint8_t endp_out_size;
uint8_t endp_in_addr;
uint8_t endp6_mode, endp7_mode;

uint8_t *cmd_buf;
uint8_t *ret_buf;
PUSB_ENDP_DESCR tmpEp;
// softserial delays too much, only hardware serial now
//#if defined(__AVR_ATmega32U4__)
//  #define TSerial Serial1
//#else
//  #define TSerial Serial
//#endif

//#define CH375_DBG
MeUSBHost::MeUSBHost() : MePort(0)
{

}

/*MeUSBHost::MeUSBHost(uint8_t s1, uint8_t s2)
{
  HSerial = new SoftwareSerial(s1,s2);
}*/

MeUSBHost::MeUSBHost(uint8_t port) : MePort(port)
{

}

uint8_t MeUSBHost::CH375_RD()
{
  delay(2); // stupid delay, the chip don't got any buffer
  if(HSerial->available()){
    uint8_t c = HSerial->read();
#ifdef CH375_DBG
    Serial.printf("<<%x\r\n",c);
#endif
    return c;
  }
  return 0;
}

void MeUSBHost::CH375_WR(uint8_t c)
{
  HSerial->write(c);
  delay(2);
#ifdef CH375_DBG
  Serial.printf(">>%x\r\n",c);
#endif
}

int16_t MeUSBHost::set_usb_mode(int16_t mode)
{
  CH375_WR(CMD_SET_USB_MODE);
  CH375_WR(mode);
  endp6_mode=endp7_mode=0x80;
  return CH375_RD();
}

uint8_t MeUSBHost::getIrq()
{
  CH375_WR(CMD_GET_STATUS);
  delay(20);
  return CH375_RD();
}

void MeUSBHost::toggle_send()
{
#ifdef CH375_DBG
  Serial.printf("toggle send %x\r\n",endp7_mode);
#endif
  CH375_WR(CMD_SET_ENDP7);
  CH375_WR( endp7_mode );
  endp7_mode^=0x40;
}

void MeUSBHost::toggle_recv()
{
  CH375_WR( CMD_SET_ENDP6 );
  CH375_WR( endp6_mode );
#ifdef CH375_DBG
  Serial.printf("toggle recv:%x\r\n", endp6_mode);
#endif
  endp6_mode^=0x40;
}


uint8_t MeUSBHost::issue_token( uint8_t endp_and_pid )
{
  CH375_WR( CMD_ISSUE_TOKEN );
  CH375_WR( endp_and_pid );  /* Bit7~4 for EndPoint No, Bit3~0 for Token PID */
#ifdef CH375_DBG
  Serial.printf("issue token %x\r\n",endp_and_pid);
#endif
  delay(2);
  return getIrq();
}

void MeUSBHost::wr_usb_data( uint8_t len, uint8_t *buf )
{
#ifdef CH375_DBG
  Serial.printf("usb wr %d\r\n",len);
#endif
  CH375_WR( CMD_WR_USB_DATA7 );
  CH375_WR( len );
  while( len-- ){
    CH375_WR( *buf++ );
  }
}

uint8_t MeUSBHost::rd_usb_data( uint8_t *buf )
{
  uint8_t i, len;
  CH375_WR( CMD_RD_USB_DATA );
  len=CH375_RD();
#ifdef CH375_DBG
  Serial.printf("usb rd %d\r\n",len);
#endif
  for ( i=0; i!=len; i++ ) *buf++=CH375_RD();
  return( len );
}

int16_t MeUSBHost::get_version(){
  CH375_WR(CMD_GET_IC_VER);
  return CH375_RD();
}

void MeUSBHost::set_freq(void)
{
  CH375_WR(0x0b);
  CH375_WR(0x17);
  CH375_WR(0xd8);
}

uint8_t MeUSBHost::set_addr( uint8_t addr )
{
  uint8_t irq;
  CH375_WR(CMD_SET_ADDRESS);
  CH375_WR(addr);
  irq = getIrq();
  if(irq==USB_INT_SUCCESS){
    CH375_WR(CMD_SET_USB_ADDR);
    CH375_WR(addr);
  }
  return irq;
}

uint8_t MeUSBHost::set_config(uint8_t cfg){
  endp6_mode=endp7_mode=0x80; // reset the sync flags
  CH375_WR(CMD_SET_CONFIG);
  CH375_WR(cfg);
  return getIrq();
}

uint8_t MeUSBHost::clr_stall6(void)
{
  CH375_WR( CMD_CLR_STALL );
  CH375_WR( endp_out_addr | 0x80 );
  endp6_mode=0x80;
  return getIrq();
}

uint8_t MeUSBHost::get_desr(uint8_t type)
{
  CH375_WR( CMD_GET_DESCR );
  CH375_WR( type );   /* description type, only 1(device) or 2(config) */
  return getIrq();
}

uint8_t MeUSBHost::host_recv()
{
  uint8_t irq;
  toggle_recv();
  irq = issue_token( ( endp_in_addr << 4 ) | DEF_USB_PID_IN );
  if(irq==USB_INT_SUCCESS){
    int16_t len = rd_usb_data(RECV_BUFFER);
#ifdef CH375_DBG
    for(int16_t i=0;i<len;i++){
      // point hid device
      Serial.printf(" 0x%x",(int16_t)RECV_BUFFER[i]);
    }
    Serial.println();
#endif
    stallCount = 0;
    return len;
  }else if(irq==USB_INT_DISCONNECT){
    device_online = false;
    device_ready = false;
#ifdef CH375_DBG
    Serial.println("##### disconn #####");
#endif
    return 0;
  }else{
    clr_stall6();
#ifdef CH375_DBG
    Serial.println("##### stall #####");
#endif
    delay(10);
    /*
    stallCount++;
    if(stallCount>10){
      device_online = false;
      device_ready = false;
      resetBus();
    }
    */
    return 0;
  }
}

void MeUSBHost::resetBus()
{
  int16_t c;
  c = set_usb_mode(7);
#ifdef CH375_DBG
  Serial.printf("set mode 7: %x\n",c);
#endif
  delay(10);
  c = set_usb_mode(6);
#ifdef CH375_DBG
  Serial.printf("set mode 6: %x\n",c);
#endif
  delay(10);
}

void MeUSBHost::init(int8_t type)
{
  ch375_online = false;
  device_online = false;
  device_ready = false;
  usbtype = type;
  HSerial = new SoftwareSerial(s2, s1);
  HSerial->begin(9600);
}

int16_t MeUSBHost::initHIDDevice()
{
  int16_t irq, len, address;
  if(usbtype==USB1_0) set_freq(); //work on a lower freq, necessary for ch375
  irq = get_desr(1);
#ifdef CH375_DBG
  Serial.printf("get des irq:%x\n",irq);
#endif
  if(irq==USB_INT_SUCCESS){
      len = rd_usb_data( RECV_BUFFER );
#ifdef CH375_DBG
      Serial.printf("descr1 len %d type %x\r\n",len,p_dev_descr->bDescriptorType);
#endif
      irq = set_addr(2);
      if(irq==USB_INT_SUCCESS){
        irq = get_desr(2); // max buf 64byte, todo:config descr overflow
        if(irq==USB_INT_SUCCESS){
          len = rd_usb_data( RECV_BUFFER );
#ifdef CH375_DBG
          Serial.printf("descr2 len %d class %x subclass %x\r\n",len,p_cfg_descr->itf_descr.bInterfaceClass, p_cfg_descr->itf_descr.bInterfaceSubClass); // interface class should be 0x03 for HID
          Serial.printf("num of ep %d\r\n",p_cfg_descr->itf_descr.bNumEndpoints);
          Serial.printf("ep0 %x %x\r\n",p_cfg_descr->endp_descr[0].bLength, p_cfg_descr->endp_descr[0].bDescriptorType);
#endif
          if(p_cfg_descr->endp_descr[0].bDescriptorType==0x21){ // skip hid des
            tmpEp = (PUSB_ENDP_DESCR)((int8_t*)(&(p_cfg_descr->endp_descr[0]))+p_cfg_descr->endp_descr[0].bLength); // get the real ep position
          }
#ifdef CH375_DBG
          Serial.printf("endpoint %x %x\r\n",tmpEp->bEndpointAddress,tmpEp->bDescriptorType);
#endif
          endp_out_addr=endp_in_addr=0;
          address =tmpEp->bEndpointAddress;  /* Address of First EndPoint */
          // actually we only care about the input end points
          if( address&0x80 ){
            endp_in_addr = address&0x0f;  /* Address of IN EndPoint */
          }else{  /* OUT EndPoint */
            endp_out_addr = address&0x0f;
            endp_out_size = p_cfg_descr->endp_descr[0].wMaxPacketSize;
			/* Length of Package for Received Data EndPoint */
            if( endp_out_size == 0 || endp_out_size > 64 )
              endp_out_size = 64;
          }
          // todo: some joystick with more than 2 node
          // just assume every thing is fine, bring the device up
          irq = set_config(p_cfg_descr->cfg_descr.bConfigurationvalue);
          if(irq==USB_INT_SUCCESS){
            CH375_WR( CMD_SET_RETRY );  // set the retry times
            CH375_WR( 0x25 );
            CH375_WR( 0x85 );
            device_ready = true;
            return 1;
          }
        }

      }
  }
  return 0;
}

int16_t MeUSBHost::probeDevice()
{
  int16_t c;
  if(!ch375_online){
    CH375_WR( CMD_CHECK_EXIST );
    CH375_WR( 0x5A);
    c = CH375_RD(); // should return 0xA5
    if(c!=0xA5) return 0;
    ch375_online = true;
    resetBus();
  }

  c = getIrq();
  if(c!=USB_INT_CONNECT) return 0;
  resetBus(); // reset bus and wait the device online again
  c=0;
  while(c!=USB_INT_CONNECT){
    delay(500); // some device may need long time to get ready
    c = getIrq();
#ifdef CH375_DBG
    Serial.print("waiting:");
    Serial.println(c,HEX);
#endif
  }
  if( initHIDDevice()==1)
    device_online=true;
}


