package extensions
{
	import flash.events.Event;
	import flash.system.System;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;

	public class SerialDevice
	{
		private static var _instance:SerialDevice;
		private var _port:String;
		public function SerialDevice()
		{
		}
		public static function sharedDevice():SerialDevice{
			if(_instance==null){
				_instance = new SerialDevice;
			}
			return _instance;
		}
		public function set port(v:String):void{
			_port = v;
		}
		public function get port():String{
			return _port;
		}
		public function onConnect(port:String):void{
			_port = port;
		}
		public function open(param:Object,openedHandle:Function):void{
			var stopBits:uint = param.stopBits
			var bitRate:uint = param.bitRate;
			var ctsFlowControl:uint = param.ctsFlowControl;
			if(ConnectionManager.sharedManager().open(_port,bitRate)){
				openedHandle(this);
				ConnectionManager.sharedManager().removeEventListener(Event.CHANGE,onReceived);
				ConnectionManager.sharedManager().addEventListener(Event.CHANGE,onReceived);
			}else{
				ConnectionManager.sharedManager().onClose();
			}
		}
		private var _receiveHandlers:Array=[];
		public function clear():void{
			_receiveHandlers = [];
		}
		public function set_receive_handler(name:String,receiveHandler:Function):void{
			if(receiveHandler!=null){
				for(var i:uint = 0;i<_receiveHandlers.length;i++){
					if(name==_receiveHandlers[i].name){
						_receiveHandlers.splice(i);
						break;
					}
				}
				_receiveHandlers.push({name:name,handler:receiveHandler});
			}
		}
		public function send(bytes:Array):void{
			var buffer:ByteArray = new ByteArray();
			for(var i:uint=0;i<bytes.length;i++){
				buffer.writeByte(bytes[i]);
			}
			ConnectionManager.sharedManager().sendBytes(buffer);
			buffer.clear();
		}
		private var l:uint = 0;
		private var _receivedBuffer:ByteArray;
		private var _receivedBytes:Array;
		private function onReceived(evt:Event):void{
			if(_receiveHandlers.length>0){
				_receivedBuffer = ConnectionManager.sharedManager().readBytes();
				_receivedBytes = [];
				while(_receivedBuffer.bytesAvailable){
					_receivedBytes.push(_receivedBuffer.readUnsignedByte());
				}
//				trace(bytes)
				if(_receivedBytes.length>0){
//					l+=receivedBytes.length;
//					trace("time:",getTimer()-l,_receivedBuffer.length);
//					l = getTimer();
					for(var i:uint=0;i<_receiveHandlers.length;i++){
						var receiveHandler:Function = _receiveHandlers[i].handler;
						if(receiveHandler!=null){
							try{
								receiveHandler(_receivedBytes);
							}catch(err:*){
								trace(err);
							}
						}
					}
				}
				_receivedBuffer.clear();
			}
		}
		public function get connected():Boolean{
			return SerialManager.sharedManager().isConnected||HIDManager.sharedManager().isConnected||BluetoothManager.sharedManager().isConnected||SocketManager.sharedManager().isConnected;
		}
		public function close():void{
//			ConnectionManager.sharedManager().close();
		}
	}
}