package extensions
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	
	import util.LogManager;
	
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
		}
		
		public function setMBlock(mBlock:MBlock):void{
			_mBlock = mBlock;
		}
		public function get isConnected():Boolean{
			_isConnected = _hid.isConnected;
			return _isConnected;
		}
		
		//hid包最好低于28字节
		static private const max_packet_size:int = 29;
		public function sendBytes(bytes:ByteArray):void{
			if(!_hid.isConnected){
				return;
			}
			
			if(bytes.length > max_packet_size){
				throw new Error("msg is too long!");
			}
			_hid.WriteHID(bytes);
		}
		
		public function disconnect():void{
			if(_hid.isConnected){
				_hid.CloseHID(); 	
			}
			_isConnected = false;
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
			MBlock.app.topBarPart.setDisconnectedTitle();
			_hid.removeEventListener(AirHID.EVENT_RXDATA,hidRx);  
			_hid.removeEventListener(AirHID.EVENT_RXERROR,onError);
			ConnectionManager.sharedManager().onClose("HID");
			close();
		}
		public function open():Boolean{
			if(_isConnected){
				return true;
			}
			if(this.isConnected){
				LogManager.sharedManager().log("hid reclosed");
				_hid.CloseHID();
			}
			try{
				var res:int = _hid.OpenHID();
				LogManager.sharedManager().log("hid connecting");
				if(res==0){
					_isConnected = true;
					MBlock.app.topBarPart.setConnectedTitle("2.4G Serial");
					_hid.removeEventListener(AirHID.EVENT_RXDATA,hidRx);  
					_hid.removeEventListener(AirHID.EVENT_RXERROR,onError);
					_hid.addEventListener(AirHID.EVENT_RXDATA,hidRx);  
					_hid.addEventListener(AirHID.EVENT_RXERROR,onError);
					return true;
				}
			}catch(err:*){
				LogManager.sharedManager().log(err);
			}
			LogManager.sharedManager().log("hid fail");
			_isConnected = false;
			return false;
		}
		public function onOpen():void{
			if(SerialDevice.sharedDevice().port=="HID"&&isConnected){
				SerialDevice.sharedDevice().port = "";
				onClose();
			}else{
				setTimeout(ConnectionManager.sharedManager().onOpen,1000,"HID");
			}
		}
		public function onClose():void{
			if(isConnected){
				LogManager.sharedManager().log("hid closed!");
				_hid.removeEventListener(AirHID.EVENT_RXDATA,hidRx);  
				_hid.removeEventListener(AirHID.EVENT_RXERROR,onError);
				_hid.CloseHID();
				ConnectionManager.sharedManager().onClose("HID");
			}
		}
		public function close():void{
			if(_hid){
				_hid.CloseHID();
			}
		}
	}
}