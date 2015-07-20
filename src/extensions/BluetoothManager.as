package extensions
{
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	import translation.Translator;
	
	import uiwidgets.DialogBox;
	
	import util.ApplicationManager;
	import util.LogManager;
	import util.SharedObjectManager;

	public class BluetoothManager
	{
		private static var _instance:BluetoothManager;
		private var _bt:BluetoothExt;
		private var _list:Array = [];
		private var _currentBluetooth:String;
		private var _hasNetFramework:Boolean = false;
		public function BluetoothManager()
		{
			if(ApplicationManager.sharedManager().system==ApplicationManager.WINDOWS){
				for each(var fs:File in File.getRootDirectories()){
					var file:File =  new File(fs.url+"Windows/Microsoft.NET/Framework");
					if(file.exists){
						_hasNetFramework = false;
						for each(var f:File in file.getDirectoryListing()){
							if(f.name.substr(0,1)=="v"){
								if(Number(f.name.substr(1,3))>=4.0){
									//									_bluetooth = new BluetoothExtEmpty();
									var buildFile:File = new File(f.url+"/MSBuild");
									if(buildFile.exists){
										_bt = new BluetoothExt();
										_hasNetFramework = true;
										break;
									}
								}
							}
						}
					}
					if(_bt!=null){
						break;
					}
				}
			}
			if(_bt!=null){
				_bt.addEventListener(Event.CHANGE,onDiscoverChanged);
				_bt.addEventListener("RECEIVED_DATA",onDataReceived);
			}
		}
		public static function sharedManager():BluetoothManager{
			if(_instance==null){
				_instance = new BluetoothManager;
			}
			return _instance;
		}
		public function get isSupported():Boolean{
			if(_bt){
				return _bt.supported;
			}
			return false;
		}
		public function get hasNetFramework():Boolean{
			if(_bt!=null){
				return _hasNetFramework;
			}
			if(ApplicationManager.sharedManager().system==ApplicationManager.WINDOWS){
				for each(var fs:File in File.getRootDirectories()){
					var file:File =  new File(fs.url+"Windows/Microsoft.NET/Framework");
					if(file.exists){
						_hasNetFramework = false;
						for each(var f:File in file.getDirectoryListing()){
							if(f.name.substr(0,1)=="v"){
								if(Number(f.name.substr(1,3))>=4.0){
									//									_bluetooth = new BluetoothExtEmpty();
									var buildFile:File = new File(f.url+"/MSBuild");
									if(buildFile.exists){
										_bt = new BluetoothExt();
										_hasNetFramework = true;
										break;
									}
								}
							}
						}
					}
					if(_bt!=null){
						break;
					}
				}
			}
			if(_bt!=null){
				_bt.addEventListener(Event.CHANGE,onDiscoverChanged);
				_bt.addEventListener("RECEIVED_DATA",onDataReceived);
			}
			return _hasNetFramework;
		}
		public function discover():void{
			if(_bt){
				if(_bt.connected){
					close();
				}
				if(!_bt.isDiscovering){
					MBlock.app.track("/OpenBluetooth");
					function cancel():void{
						removeDiscoverDialogbox(d);
						d.cancel();
					}
					var d:DialogBox = new DialogBox();
					d.addTitle(Translator.map('Discovering Bluetooth') + '...');
					d.addButton('Cancel', cancel);
					d.showOnStage(MBlock.app.stage);
					addDiscoverDialogbox(d);
					_bt.beginDiscover();
				}
			}
		}
		private var _dialogboxDiscover:Array = [];
		public function addDiscoverDialogbox(d:DialogBox):void{
			_dialogboxDiscover.push(d);
		}
		public function removeDiscoverDialogbox(d:DialogBox):void{
			for(var i:* in _dialogboxDiscover){
				if(d==_dialogboxDiscover[i]){
					delete _dialogboxDiscover[i];
				}
			}
		}
		public function connect(port:String):void{
			LogManager.sharedManager().log("connecting bt:"+port);
			_currentBluetooth = port;
			if(SerialDevice.sharedDevice().port==port&&isConnected){
				LogManager.sharedManager().log("close bt:"+port);
				close();
			}else{
				if(isConnected){
					close();
				}
				trace("bt onOpen");
				setTimeout(ConnectionManager.sharedManager().onOpen,200,port);
			}
		}
		private var _isBusy:Boolean = false;
		private var _history:Array = [];
		private function addBluetoothHistory():void{
			var devAddr:String = _currentBluetooth.split("(")[1].split(")")[0];
			var devName:String = _currentBluetooth.split("(")[0];
			devAddr = devAddr.split(" ").join("");
			devName = devName.split(" ").join("");
			for(var i:uint=0;i<_history.length;i++){
				var dev:Object = _history[i];
				if(dev.addr == devAddr){
					dev.name = devName;
					dev.label = _currentBluetooth;
					return;
				}
			}
			dev = {};
			dev.name = devName;
			dev.addr = devAddr;
			dev.label = _currentBluetooth;
			_history.push(dev);
			SharedObjectManager.sharedManager().setLocalFile("btHistory",_history);
		}
		private function getBluetoothName(address:String):Object{
			for(var i:uint=0;i<_history.length;i++){
				var dev:Object = _history[i];
				if(dev.addr == address){
					dev.label = _currentBluetooth;
					return dev;
				}
			}
			return {};
		}
		public function get history():Array{
			_history = SharedObjectManager.sharedManager().getLocalFile("btHistory",[]);
			var temp:Array = [];
			for(var i:uint=0;i<_history.length;i++){
				var dev:Object = _history[i];
				if(temp.indexOf(dev.addr)==-1){
					temp.push(dev.label);
				}
			}
			return temp;
		}
		public function clearHistory():void{
			SharedObjectManager.sharedManager().setLocalFile("btHistory",[]);
		}
		public function open(port:String):Boolean{
			LogManager.sharedManager().log("bt open:"+port);
			var status:Boolean = false;
			if(_isBusy){
				setTimeout(function():void{_isBusy=false;},2000);
				return true;
			}
			_isBusy = true;
			if(_bt.connected){
				if(_currentBluetooth==port){
					return true;
				}else{
					close();
				}
			}
			//if(_list.indexOf(port)>-1){
			var btAddr:String = port.split("( ")[1].split(" )")[0];
			LogManager.sharedManager().log("bt opening:"+btAddr);
			_bt.connectByAddress(btAddr);
			_currentBluetooth = port;
			var i:uint = 0;
			function cancel():void{
				removeDiscoverDialogbox(d);
				d.cancel();
			}
			var d:DialogBox = new DialogBox();
			d.addTitle(Translator.map('Connecting Bluetooth') + '...');
			d.addButton('Close', cancel);
			d.showOnStage(MBlock.app.stage);
			addDiscoverDialogbox(d);
			function checkName():void{
				if(_bt.connected){
					LogManager.sharedManager().log("bt opened:"+btAddr);
					_isBusy = false;
					addBluetoothHistory();
					MBlock.app.topBarPart.setConnectedTitle("Serial Port");
					d.setTitle(Translator.map("Bluetooth Connected"));
				}else{
					LogManager.sharedManager().log("bt checking:"+btAddr);
					if(i<40){
						setTimeout(checkName,3000);
					}else{
						_isBusy = false;
						d.setTitle(Translator.map("Connecting Timeout"));
						ConnectionManager.sharedManager().onClose(_currentBluetooth);
					}
					i++;
				}
			}
			setTimeout(checkName,1000);
			status = true;
			//}
			return status;
		}
		public function get isConnected():Boolean{
			if(_bt!=null){
				return _bt.connected;
			}
			return false;
		}
		public function close():void{
			LogManager.sharedManager().log("bt closed")
			if(_bt!=null){
				if(_bt.connected){
					_bt.disconnect();
					ConnectionManager.sharedManager().onClose(_currentBluetooth);
				}
			}
		}
		public function get list():Array{
			return _list;
		}
		public function get currentBluetooth():String{
			return _currentBluetooth;
		}
		private function onDiscoverChanged(evt:Event):void{
			
			var str:String = _bt.discoverResult();
			if(str.length<3){
				return;
			}
			_list = str.split(",");
			LogManager.sharedManager().log("device list:"+_list);
			for(var i:uint=0;i<_list.length;i++){
				for(var j:* in _dialogboxDiscover){
					var d:DialogBox = _dialogboxDiscover[j];
					
					if(i==0){
						d.clearButtons();
					}
					d.addButtonExt(_list[i],_list[i],onClickConnect);
					if(i==_list.length-1){
						function onClose():void{
							d.cancel();
						}
						d.addButton("Cancel",onClose);
						d.fixLayout();
					}
				}
			}
			
			function onClickConnect(data:String):void{
				connect(data);
				d.cancel();
			}
			
			if(list.length>0){
				if(d!=null)
					d.setTitle(Translator.map("Click The Device From List To Connect"));
			}else{
				if(d!=null)
					d.setTitle(Translator.map("Device Not Found"));
			}
			_dialogboxDiscover = [];
		}
		private function onDataReceived(evt:Event):void{
			var bytes:ByteArray = _bt.receivedBuffer();
			if(bytes.length>0){
				//				trace("data length:",bytes.length);
//				ParseManager.sharedManager().parseBuffer(bytes);
				ConnectionManager.sharedManager().onReceived(bytes);
			}else{
				trace("no data");
			}
		}
		private var _prevTime:Number = 0;
		public function sendBytes(bytes:ByteArray):void{
			
			//var cTime:Number = getTimer();
			//if(cTime-_prevTime>20){
				//_prevTime = cTime; 
				_bt.writeBuffer(bytes);
			//}
		}
	}
}