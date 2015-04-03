package extensions
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.utils.ByteArray;
	
	import util.ApplicationManager;

	public class ConnectionManager extends EventDispatcher
	{
		private static var _instance:ConnectionManager;
		public var extensionName:String = "";
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
				case "driver":{
					MBlock.app.track("/OpenSerial/InstallDriver");
					if(ApplicationManager.sharedManager().system==ApplicationManager.MAC_OS){
						navigateToURL(new URLRequest("https://github.com/Makeblock-official/Makeblock-USB-Driver"));
					}else{
						var fileDriver:File = new File(File.applicationDirectory.nativePath+"/drivers/Driver_for_Windows.exe");
						fileDriver.openWithDefaultApplication();
					}
					break;
				}
				case "connect_hid":{
					if(!HIDManager.sharedManager().isConnected){
						HIDManager.sharedManager().onOpen();
					}else{
						HIDManager.sharedManager().onClose();
					}
					break;
				}
				default:{
					if(name.indexOf("serial_")>-1){
						SerialManager.sharedManager().connect(name.split("serial_").join(""));
					}
					if(name.indexOf("bt_")>-1){
						BluetoothManager.sharedManager().connect(name.split("bt_").join(""));
					}
					if(name.indexOf("net_")>-1){
						SocketManager.sharedManager().probe(name.split("net_")[1]);
					}
				}
			}
		}
		public function open(port:String,baud:uint=115200):Boolean{
			if(port){
				if(port.indexOf("COM")>-1||port.indexOf("/dev/tty.")>-1){
					return SerialManager.sharedManager().open(port,baud);
				}else if(port.indexOf(" (")>-1){
					return BluetoothManager.sharedManager().open(port);
				}else if(port.indexOf("HID")>-1){
					return HIDManager.sharedManager().open();
				}
			}
			return false;
		}
		public function onClose():void{
			SerialDevice.sharedDevice().port = "";
			SerialDevice.sharedDevice().clear();
			MBlock.app.topBarPart.setDisconnectedTitle();
			this.dispatchEvent(new Event(Event.CLOSE));
		}
		public function onRemoved(extName:String = ""):void{
			extensionName = extName;
			this.dispatchEvent(new Event(Event.REMOVED));
		}
		public function onOpen(port:String):void{
			SerialDevice.sharedDevice().port = port;
			this.dispatchEvent(new Event(Event.CONNECT));
		}
		public function onReOpen():void{
			if(SerialDevice.sharedDevice().port!=""){
				this.dispatchEvent(new Event(Event.CONNECT));
			}
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
			}else if(HIDManager.sharedManager().isConnected){
				HIDManager.sharedManager().sendBytes(bytes);
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