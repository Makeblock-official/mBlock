package extensions
{
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;
	
	import translation.Translator;
	
	import uiwidgets.DialogBox;
	
	import util.ApplicationManager;

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
			return _hasNetFramework;
		}
		public function discover():void{
			if(_bt){
				if(_bt.connected){
					close();
				}else{
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
			if(SerialDevice.sharedDevice().port==port&&isConnected){
				ConnectionManager.sharedManager().onClose();
				close();
			}else{
				ConnectionManager.sharedManager().onOpen(port);
			}
		}
		private var _isBusy:Boolean = false;
		public function open(port:String):Boolean{
			trace("open:",port);
			var status:Boolean = false;
			if(_isBusy){
				return true;
			}
			_isBusy = true;
			if(_bt.connected){
				close();
				if(_currentBluetooth==port){
					return false;
				}
			}
			if(_list.indexOf(port)>-1){
				_bt.connect(_list.indexOf(port));
				_currentBluetooth = port;
				var i:uint = 0;
				function checkName():void{
					if(_bt.connected){
						_isBusy = false;
						//					MBlock.app.topBarPart.setBluetoothTitle(true);
						MBlock.app.topBarPart.setConnectedTitle(_bt.connectName+" "+Translator.map("Connected"));
					}else{
						if(i<10){
							setTimeout(checkName,500);
						}else{
							ConnectionManager.sharedManager().onClose();
						}
						i++;
					}
				}
				setTimeout(checkName,1000);
				status = true;
			}
			return status;
		}
		public function get isConnected():Boolean{
			if(_bt!=null){
				return _bt.connected;
			}
			return false;
		}
		public function close():void{
			if(_bt!=null){
				if(_bt.connected){
					//					MBlock.app.topBarPart.setBluetoothTitle(false);
					ConnectionManager.sharedManager().onClose();
					_bt.disconnect();
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
			trace("device list:",_list);
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
		public function sendBytes(bytes:ByteArray):void{
			_bt.writeBuffer(bytes);
		}
	}
}