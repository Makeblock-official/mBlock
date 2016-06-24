package extensions
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.utils.ByteArray;
	
	import cc.makeblock.interpreter.BlockInterpreter;
	
	import util.ApplicationManager;
	import util.LogManager;

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
				case "clear_bt":{
					BluetoothManager.sharedManager().clearHistory();
					break;
				}
				case "netframework":{
					navigateToURL(new URLRequest("http://www.microsoft.com/en-us/download/details.aspx?id=30653"));
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
				case "reset_program":{
					SerialManager.sharedManager().upgrade(ApplicationManager.sharedManager().documents.resolvePath("mBlock/tools/hex/mbot_reset.hex").nativePath);
					break;
				}
				case "connect_network":{
					SocketManager.sharedManager().probe("custom");
					break;
				}
				case "driver":{
					MBlock.app.track("/OpenSerial/InstallDriver");
					var fileDriver:File;
					if(ApplicationManager.sharedManager().system==ApplicationManager.MAC_OS){
//						navigateToURL(new URLRequest("https://github.com/Makeblock-official/Makeblock-USB-Driver"));
						fileDriver = new File(File.applicationDirectory.nativePath+"/drivers/Arduino Driver.pkg");
						fileDriver.openWithDefaultApplication();
					}else{
						fileDriver = new File(File.applicationDirectory.nativePath+"/drivers/Driver_for_Windows.exe");
						fileDriver.openWithDefaultApplication();
					}
					break;
				}
				case "connect_hid":{
					BlockInterpreter.Instance.stopAllThreads();
					if(!HIDManager.sharedManager().isConnected){
						HIDManager.sharedManager().onOpen();
					}else{
						HIDManager.sharedManager().onClose();
					}
					break;
				}
				default:{
					BlockInterpreter.Instance.stopAllThreads();
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
			LogManager.sharedManager().log("connection:"+port);
			if(port){
				if(port.indexOf("COM")>-1||port.indexOf("/dev/tty.")>-1){
					return SerialManager.sharedManager().open(port,baud);
				}else if(port.indexOf(" (")>-1){
					return BluetoothManager.sharedManager().open(port);
				}else if(port.indexOf("HID")>-1){
					return HIDManager.sharedManager().open();
				}else{
					return SocketManager.sharedManager().open(port);
				}
			}
			return false;
		}
		public function onClose(port:String):void{
			SerialDevice.sharedDevice().clear(port);
			if(!SerialDevice.sharedDevice().connected){
				MBlock.app.topBarPart.setDisconnectedTitle();
			}else{
				if(SerialManager.sharedManager().isConnected||HIDManager.sharedManager().isConnected||BluetoothManager.sharedManager().isConnected){
					MBlock.app.topBarPart.setConnectedTitle("Serial Port");
				}else{
					MBlock.app.topBarPart.setConnectedTitle("Network");
				}
			}
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
			MBlock.app.scriptsPart.onSerialDataReceived(bytes);
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
			bytes.clear();
		}
		public function readBytes():ByteArray{
			if(_bytes){
				return _bytes;
			}
			return new ByteArray;
		}
	}
}