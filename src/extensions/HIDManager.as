package extensions
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	
	import by.blooddy.crypto.MD5;
	
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
			setTimeout(init,500);
			setInterval(__SendPacket, 20);
		}
		
		public function setMBlock(mBlock:MBlock):void{
			_mBlock = mBlock;
		}
		public function get isConnected():Boolean{
			_isConnected = _hid.isConnected;
			return _isConnected;
		}
		
		private const packetSignQueue:Vector.<String> = new Vector.<String>();
		private const packetQueue:Vector.<ByteArray> = new Vector.<ByteArray>();
		private function __SendPacket():void
		{
			if(packetQueue.length <= 0){
				return;
			}
			packetSignQueue.shift();
			var packet:ByteArray = packetQueue.shift();
			if(_hid.isConnected){
				_hid.WriteHID(packet);
				packet.clear();
			}
		}
		//hid包最好低于28字节
		static private const max_packet_size:int = 28;
		public function sendBytes(bytes:ByteArray):void{
			if(!_hid.isConnected){
				bytes.clear();
				return;
			}
			var sign:String = MD5.hashBytes(bytes);
			if(packetSignQueue.indexOf(sign) >= 0){
				bytes.clear();
				return;
			}
			packetSignQueue.push(sign);
			if(bytes.length <= max_packet_size){
				packetQueue.push(bytes);
				return;
			}
			bytes.position = 0;
			var subBytes:ByteArray;
			while(bytes.bytesAvailable > max_packet_size){
				subBytes = new ByteArray();
				bytes.readBytes(subBytes, 0, max_packet_size);
				packetSignQueue.push(null);
				packetQueue.push(subBytes);
			}
			subBytes = new ByteArray();
			bytes.readBytes(subBytes);
			packetQueue.push(subBytes);
			bytes.clear();
		}
		/*
		public function sendString(msg:String):int{
			if(_hid.isConnected){
				var bytes:ByteArray = new ByteArray();
				bytes.writeUTFBytes(msg);
				return _hid.WriteHID(bytes);
			}
			return 0;
		}
		*/
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
			trace(evt);
			MBlock.app.topBarPart.setDisconnectedTitle();
			_hid.removeEventListener(AirHID.EVENT_RXDATA,hidRx);  
			_hid.removeEventListener(AirHID.EVENT_RXERROR,onError);
			ConnectionManager.sharedManager().onClose("HID");
			close();
			//setTimeout(init,5000);
		}
		private function init():void{
			// test of hid
			
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
					trace("hid opened");
					_isConnected = true;
					MBlock.app.topBarPart.setConnectedTitle("2.4G Serial");
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