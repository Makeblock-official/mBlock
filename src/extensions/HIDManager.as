package extensions
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;
	
	import translation.Translator;
	
	public class HIDManager extends EventDispatcher
	{
		private static var _instance:HIDManager;
		private var _mBlock:MBlock;
		public static function sharedManager():HIDManager{
			if(_instance==null){
				_instance = new HIDManager;
			}
			return _instance;
		}
		private var _isConnected:Boolean = false;
		public function HIDManager()
		{
			_hid = new AirHID();
			setTimeout(init,500);
		}
		
		public function setMBlock(mBlock:MBlock):void{
			_mBlock = mBlock;
		}
		public function get isConnected():Boolean{
			_isConnected = _hid.isConnected;
			return _isConnected;
		}
		public function sendBytes(bytes:ByteArray):int{
			if(_hid.isConnected){
				var len:int = _hid.WriteHID(bytes);
				if(len==-1){
					//_hid.CloseHID();
				}
				return len;
			}
			return 0;
		}
		public function sendString(msg:String):int{
			if(_hid.isConnected){
				var bytes:ByteArray = new ByteArray();
				bytes.writeUTFBytes(msg);
				return _hid.WriteHID(bytes);
			}
			return 0;
		}
		public function disconnect():void{
			if(_isConnected){
				_hid.removeEventListener(AirHID.EVENT_RXDATA,hidRx); 
				_isConnected = false;
			}
		}
		private var _hid:AirHID;
		private function hidRx(evt:Event):void{
			var t:String = "";
			try{
				var bytes:ByteArray = _hid.ReadHID();
				//				for(var i:uint=0;i<bytes.length;i++){
				//					t += String.fromCharCode(bytes.readByte());
				//				}
				//				trace("hid rx"+bytes.length+" : "+t);
				if(bytes.length>0){
					ConnectionManager.sharedManager().onReceived(bytes);
				}
			}catch(e:*){
				trace(e);
			}
		}
		private function onError(evt:Event):void{
			
			//setTimeout(init,5000);
		}
		private function init():void{
			// test of hid
			
		}
		public function open():Boolean{
			try{
				var res:int = _hid.OpenHID();
				if(res==0){
					trace("hid opened")
					MBlock.app.topBarPart.setConnectedTitle(Translator.map("2.4G Serial")+" "+Translator.map("Connected"));
					//				ParseManager.sharedManager().queryVersion();
					_hid.removeEventListener(AirHID.EVENT_RXDATA,hidRx);  
					_hid.removeEventListener(AirHID.EVENT_RXERROR,onError);
					_hid.addEventListener(AirHID.EVENT_RXDATA,hidRx);  
					_hid.addEventListener(AirHID.EVENT_RXERROR,onError);
					//				var bytes:ByteArray = new ByteArray;
					//				bytes.writeUTF("hello world\n")
					//				res = _hid.WriteHID(bytes)
					//				trace("write hid:"+res);
					return true;
				}
			}catch(err:*){
				trace(err);
			}
			trace("hid fail")
			return false;
		}
		public function onOpen():void{
			if(SerialDevice.sharedDevice().port=="HID"&&isConnected){
				SerialDevice.sharedDevice().port = "";
				onClose();
			}else{
				ConnectionManager.sharedManager().onOpen("HID");
			}
		}
		public function onClose():void{
			if(isConnected){
				_hid.removeEventListener(AirHID.EVENT_RXDATA,hidRx);  
				_hid.removeEventListener(AirHID.EVENT_RXERROR,onError);
				ConnectionManager.sharedManager().onClose();
				close();
			}
		}
		public function close():void{
			if(_hid){
				_hid.CloseHID();
			}
		}
	}
}