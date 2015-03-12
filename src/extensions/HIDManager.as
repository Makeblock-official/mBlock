package extensions
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;

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
			init();
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
				var bytes:ByteArray = _hid.ReadHID()
				for(var i:uint=0;i<bytes.length;i++){
					t += String.fromCharCode(bytes.readByte());
				}
	//			trace("hid rx"+bytes.length+" : "+t)
				ParseManager.sharedManager().parseBuffer(bytes);
			}catch(e:*){
				trace(e);
			}
		}
		private function init():void{
			// test of hid
			_hid = new AirHID();
			var res:int = _hid.OpenHID();
			if(res==0){
				ParseManager.sharedManager().queryVersion();
				_hid.addEventListener(AirHID.EVENT_RXDATA,hidRx);   
//				var bytes:ByteArray = new ByteArray;
//				bytes.writeUTF("hello world\n")
//				res = _hid.WriteHID(bytes)
//				trace("write hid:"+res);
			}
		}
	}
}