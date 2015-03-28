package extensions
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;

	public class ConnectionManager extends EventDispatcher
	{
		private static var _instance:ConnectionManager;
		public function ConnectionManager()
		{
		}
		public static function sharedManager():ConnectionManager{
			if(_instance==null){
				_instance = new ConnectionManager;
			}
			return _instance;
		}
		public function onConnect(name:String):void{
			switch(name){
				case "discover_bt":{
					BluetoothManager.sharedManager().discover();
					break;
				}
				case "view_source":{
					SerialManager.sharedManager().openSource();
					break;
				}
				case "upgrade_firmware":{
					SerialManager.sharedManager().upgrade();
					break;
				}
				case "connect_network":{
					SocketManager.sharedManager().probe("custom");
					break;
				}
				case "connect_hid":{
					
					break;
				}
				default:{
					if(name.indexOf("serial_")>-1){
						SerialManager.sharedManager().connect(name.split("serial_").join(""));
					}
					if(name.indexOf("bt_")>-1){
						BluetoothManager.sharedManager().connect(name.split("bt_").join(""));
					}
				}
			}
		}
		public function open(port:String,baud:uint=115200):Boolean{
			if(port.indexOf("COM")>-1){
				return SerialManager.sharedManager().open(port,baud);
			}else if(port.indexOf(" (")>-1){
				return BluetoothManager.sharedManager().open(port);
			}
			return false;
		}
		public function onClose():void{
			SerialDevice.sharedDevice().port = "";
			MBlock.app.topBarPart.setDisconnectedTitle();
			this.dispatchEvent(new Event(Event.CLOSE));
		}
		public function onRemoved():void{
			this.dispatchEvent(new Event(Event.REMOVED));
		}
		public function onOpen(port:String):void{
			SerialDevice.sharedDevice().port = port;
			this.dispatchEvent(new Event(Event.CONNECT));
		}
		private var _bytes:ByteArray;
		public function onReceived(bytes:ByteArray):void{
			_bytes = bytes;
			this.dispatchEvent(new Event(Event.CHANGE));
		}
		public function sendBytes(bytes:ByteArray):void{
			if(SerialManager.sharedManager().isConnected){
				SerialManager.sharedManager().sendBytes(bytes);
			}else if(BluetoothManager.sharedManager().isConnected){
				BluetoothManager.sharedManager().sendBytes(bytes);
			}
		}
		public function readBytes():ByteArray{
			if(_bytes){
				return _bytes;
			}
			return new ByteArray;
		}
	}
}