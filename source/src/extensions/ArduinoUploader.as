package extensions
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.Timer;
	import flash.utils.setTimeout;
	
	import translation.Translator;
	
	import uiwidgets.DialogBox;

	public class ArduinoUploader
	{
		private const IDLE:uint = 0;
		private const ST_PROBING:uint = 1;
		private const ST_FOUND:uint = 2;
		private const ST_DOWNLOADING:uint = 3;
		private const ST_READ:uint = 4;
		
		private const STK_OK:uint = 0x10;
		private const STK_INSYNC:uint = 0x14;
		private const STK_NOSYNC:uint = 0x15;
		private const STK_GET_SYNC:uint = 0x30;
		private const CRC_EOP:uint = 0x20;
		private const STK_GET_SIGN_ON:uint = 0x31;
		private const STK_SET_PARAMETER:uint = 0x40;
		private const STK_GET_PARAMETER:uint = 0x41;
		private const STK_SET_DEVICE:uint = 0x42;
		private const STK_SET_DEVICE_EXT:uint = 0x45;
		private const ARDUINO_PAGE_SIZE:uint = 128;
		private const DOWNLOAD_SENDADDR:uint = 0xE0;
		private const DOWNLOAD_SENDCODE:uint = 0xE1;
		private const STK_ENTER_PROGMODE:uint =   0x50  // 'P'
		private const STK_LEAVE_PROGMODE:uint =   0x51  // 'Q'
		private const STK_CHIP_ERASE:uint =       0x52  // 'R'
		private const STK_CHECK_AUTOINC:uint =    0x53  // 'S'
		private const STK_LOAD_ADDRESS:uint =     0x55  // 'U'
		private const STK_UNIVERSAL:uint =        0x56  // 'V'
		private const STK_PROG_FLASH:uint =       0x60  // '`'
		private const STK_PROG_DATA:uint =        0x61  // 'a'
		private const STK_PROG_FUSE:uint =        0x62  // 'b'
		private const STK_PROG_LOCK:uint =        0x63  // 'c'
		private const STK_PROG_PAGE:uint =        0x64  // 'd'
		private const STK_PROG_FUSE_EXT:uint =    0x65  // 'e'
		private const STK_READ_FLASH:uint =       0x70  // 'p'
		private const STK_READ_DATA:uint =        0x71  // 'q'
		private const STK_READ_FUSE:uint =        0x72  // 'r'
		private const STK_READ_LOCK:uint =        0x73  // 's'
		private const STK_READ_PAGE:uint =        0x74  // 't'
		private const STK_READ_SIGN:uint =        0x75  // 'u'
		private const STK_READ_OSCCAL:uint =      0x76  // 'v'
		private const STK_READ_FUSE_EXT:uint =    0x77  // 'w'
		private const STK_READ_OSCCAL_EXT:uint =  0x78  // 'x'
		private const QUERY_HW_VER:uint = 0x80;
		private const QUERY_SW_MAJOR:uint = 0x81;
		private const QUERY_SW_MINOR:uint = 0x82;
		private const PROTOCOL_UNKNOW:uint = 0;
		private const PROTOCOL_UNO:uint = 1;
		private const PROTOCOL_LEONARDO:uint = 2;
		private var prevCmd:uint;
		private var prevCmdSub:uint;
		private var downloadProtocol:uint;
		private static var _instance:ArduinoUploader;
		private var mState:uint = IDLE;
		private var probeTimer:Timer = new Timer(500,0);
		private var pagebuff:ByteArray = new ByteArray;
		private var hex:Array = [];
		private var code:String;
		private var hexptr:uint = 0;
		private var pageptr:uint = 0;
		private var pagelen:uint = 0;
		private var hwVersion:uint = 0;
		private var swVersion:uint = 0;
		private var swVerMin:uint = 0;
		private var swVerMaj:uint = 0;
		private var dialogbox:DialogBox = new DialogBox();
		public function ArduinoUploader()
		{
			dialogbox.addTitle("Start Uploading");
			dialogbox.addText("Start");
			dialogbox.addButton("Hide",function():void{dialogbox.cancel();});
		}
		public static function sharedManager():ArduinoUploader{
			if(_instance==null){
				_instance = new ArduinoUploader;
			}
			return _instance;
		}
		public function start(url:String):void{
			
				SerialManager.sharedManager().reconnectSerial();
				setTimeout(loadHex,150,url);
				dialogbox.setText("Waiting Reset Board");
				dialogbox.showOnStage(MBlock.app.stage);
		}
		public function get state():uint{
			return mState;
		}
		private function probeCheck():void{
			dialogbox.setText("Waiting Reset Board");
			probeTimer.addEventListener(TimerEvent.TIMER,onProbeHandle);
			probeTimer.start();
			mState = ST_PROBING;
		}
		private function onProbeHandle(evt:TimerEvent):void{
			var bytes:ByteArray = new ByteArray;
			bytes.endian = Endian.LITTLE_ENDIAN;
			bytes[0]=STK_GET_SYNC;
			bytes[1]=CRC_EOP;
			ParseManager.sharedManager().sendBytes(bytes);
			prevCmd = STK_GET_SYNC;
		}
		private var buffer:ByteArray = new ByteArray;
		public function parseCmd(bytes:ByteArray):Boolean{		
			if(mState==IDLE){
				return false;
			}
			var s:String = "";
			for(var i:uint=0;i<bytes.length;i++){
				buffer.writeByte(bytes[i]);
				s += bytes[i].toString(16)+" ";
			}
//			trace(s);
			if(prevCmd == STK_GET_SYNC && mState == ST_PROBING){
				if(buffer[0]==0x14&&buffer[1]==0x10){
					mState = ST_FOUND;
					probeTimer.stop();
					sendQuery(QUERY_HW_VER);
					downloadProtocol = PROTOCOL_UNO;
					buffer.clear();
					trace("st found");
					return true;
					//for uno
				}else if(bytes[0]=='C' && bytes[1]=='A'){
					//for leonardo
					return true;
				}else{
					return true;
				}
			}
			if(prevCmd == STK_GET_PARAMETER && downloadProtocol == PROTOCOL_UNO && buffer[buffer.length-1]==0x10){
				if(prevCmdSub == QUERY_HW_VER){
					sendQuery(QUERY_SW_MINOR);
					hwVersion = buffer[1];
					buffer.clear();
					trace("check hwVersion");
				}else if(prevCmdSub == QUERY_SW_MINOR){
					sendQuery(QUERY_SW_MAJOR);
					swVerMin = buffer[1];
					buffer.clear();
					trace("check swVerMin");
				}else if(prevCmdSub == QUERY_SW_MAJOR){
					swVerMaj = buffer[1];
					buffer.clear();
					pageptr = 0;
					trace("start uploading");
					uploadHex();
					//start uploading
				}
				return true;
			}
			if(mState == ST_DOWNLOADING && downloadProtocol == PROTOCOL_UNO){
				if(bytes[bytes.length-1]==0x10){
					if(prevCmd == STK_LOAD_ADDRESS){
						sendPage(pagelen);
						dialogbox.setText(Translator.map("Uploading")+" "+Math.floor(hexptr*100/hex.length)+"%");
						if(Math.floor(hexptr*100/hex.length)>=100){
							ArduinoManager.sharedManager().isUploading = false;
							dialogbox.setText("Upload Finish");
							setTimeout(function():void{dialogbox.cancel();},2000);
						}
//						buffer.clear();
						return true;
					}else if(prevCmd == STK_PROG_PAGE){
						uploadHex();
//						buffer.clear();
						return true;
					}
				}
				
			}
			return true;
		}
		private function loadHex(url:String):void{
			var urlloader:URLLoader = new URLLoader();
			var req:URLRequest = new URLRequest();
			req.url = url;
			urlloader.load(req);
			urlloader.addEventListener(Event.COMPLETE,onHexLoaded);
			urlloader.addEventListener(IOErrorEvent.IO_ERROR,function(e:IOErrorEvent):void{trace(e);});
		}
		private function onHexLoaded(evt:Event):void{
			code = evt.target.data;
			hex = code.split("\n");
			probeCheck();
		}
		private function sendPage(len:int):void{
			var bytes:ByteArray = new ByteArray;
			bytes.endian = Endian.BIG_ENDIAN;
			bytes.writeByte(STK_PROG_PAGE);
			bytes.writeByte((len>>8)&0xff);
			bytes.writeByte(len&0xff);
			bytes.writeByte("F".charCodeAt(0));
			bytes.writeBytes(pagebuff,0,pagebuff.length);
			bytes.writeByte(" ".charCodeAt(0));
			ParseManager.sharedManager().sendBytes(bytes);
			prevCmd = STK_PROG_PAGE;
		}
		private function sendQuery(query:int):void{
			var bytes:ByteArray = new ByteArray;
			bytes.endian = Endian.BIG_ENDIAN;
			bytes[0]=STK_GET_PARAMETER;
			bytes[1]=query;
			bytes[2]=CRC_EOP;
			function queryHandle():void{
				ParseManager.sharedManager().sendBytes(bytes);
				prevCmd = STK_GET_PARAMETER;
				prevCmdSub = query;
			}
			setTimeout(queryHandle,20);
		}
		private function sendAddr(addr:int):void{
			var addrl:int = addr&0xff;
			var addrh:int = (addr>>8) & 0xff;
			var bytes:ByteArray = new ByteArray;
			bytes.endian = Endian.BIG_ENDIAN;
			bytes.writeByte(STK_LOAD_ADDRESS);
			bytes.writeByte(addrl);
			bytes.writeByte(addrh);
			bytes.writeByte(CRC_EOP);
			ParseManager.sharedManager().sendBytes(bytes);
			prevCmd = STK_LOAD_ADDRESS;
		}
		private function sendQuit():void{
			var bytes:ByteArray = new ByteArray;
			bytes.endian = Endian.BIG_ENDIAN;
			bytes.writeByte(STK_LEAVE_PROGMODE);
			bytes.writeByte(CRC_EOP);
			ParseManager.sharedManager().sendBytes(bytes);
			prevCmd = STK_LOAD_ADDRESS;
		}
		private function uploadHex():void{
			var len:uint = 0;
			var addr:ByteArray = new ByteArray;
			if(mState != ST_DOWNLOADING){
				if(mState != ST_FOUND) return;
				hexptr = 0;
				pageptr = 0;
			}
			if(hexptr>=hex.length){
				//finished
				trace("finished");
				dialogbox.setText("Upload Finish");
				setTimeout(function():void{dialogbox.cancel();},2000);
				buffer.clear();
				sendQuit();
				mState = IDLE;
				return;
			}
			mState = ST_DOWNLOADING;
			pagebuff.clear();
			
			while(len<ARDUINO_PAGE_SIZE){
				var b:ByteArray = new ByteArray;
				b.endian = Endian.BIG_ENDIAN;
				b.writeMultiByte(hex[hexptr],"ascii");
				if(b[8]=="1".charCodeAt(0)){
					hexptr = hex.length;
					break;
				}
				len+=parseHexLine(addr,pagebuff,b);
				hexptr++;
			}
			sendAddr(pageptr/2);
			pageptr += len;
			pagelen = len;
			prevCmdSub = DOWNLOAD_SENDADDR;
			dialogbox.setText(Translator.map("Uploading")+" "+Math.floor(hexptr*100/hex.length)+"%");
		}
		private function atoh(h:int,l:int):int{
			var ret:int = 0;
			if(h>="0".charCodeAt(0) && h<="9".charCodeAt(0))h-=48;
			else if (h>="A".charCodeAt(0) && h<="Z".charCodeAt(0)) h-= 55;
			else return -1;
			
			if(l>="0".charCodeAt(0) && l<="9".charCodeAt(0))l-=48;
			else if (l>="A".charCodeAt(0) && l<="Z".charCodeAt(0)) l-= 55;
			else return -1;
			ret = (h<<4)+l;
			return ret;
		}
		private function parseHexLine(addr:ByteArray,code:ByteArray,input:ByteArray):int{
			var tmp:int;
			var i:int,len:int,type:int;
			var tmpInput:ByteArray = new ByteArray;
			input.position = 0;
			input.readBytes(tmpInput,0,input.length);
			var t:int = 0;
			if(tmpInput[0]!=":".charCodeAt(0))return -1;
			t++;
			len = atoh(tmpInput[1],tmpInput[2]);
			addr[0] = atoh(tmpInput[3],tmpInput[4]);
			addr[0] += atoh(tmpInput[5],tmpInput[6])*256;
			type = atoh(tmpInput[7],tmpInput[8]);
			for(i=0;i<len;i++){
				tmp = atoh(tmpInput[9+i*2],tmpInput[10+i*2]);
				code.writeByte(tmp);
			}
			return len;
		}
	}
}