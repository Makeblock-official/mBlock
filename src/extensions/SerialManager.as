package extensions
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.utils.setTimeout;
	
	import translation.Translator;
	
	import uiwidgets.DialogBox;
	
	import util.ApplicationManager;
	import util.LogManager;
	import util.SharedObjectManager;

	public class SerialManager extends EventDispatcher
	{
		private var moduleList:Array = [];
		private var _currentList:Array = [];
		private static var _instance:SerialManager;
		public var currentPort:String = "";
		private var _selectPort:String = "";
		public var _mBlock:MBlock;
		private var _board:String = "uno";
		private var _device:String = "uno";
		private var _upgradeBytesLoaded:Number = 0;
		private var _upgradeBytesTotal:Number = 0;
		private var _isInitUpgrade:Boolean = false;
		private var _dialog:DialogBox = new DialogBox();
		private var _hexToDownload:String = ""
		private var _bluetooth:BluetoothExt;
		private var _isMacOs:Boolean = ApplicationManager.sharedManager().system==ApplicationManager.MAC_OS;
		private var _avrdude:String = "";
		private var _avrdudeConfig:String = "";
		public static function sharedManager():SerialManager{
			if(_instance==null){
				_instance = new SerialManager;
			}
			return _instance;
		}
		private var _serial:AIRSerial;
		
		public function SerialManager()
		{
			_serial = new AIRSerial();
			_avrdude = _isMacOs?"avrdude":"avrdude.exe";
			_avrdudeConfig = _isMacOs?"avrdude_mac.conf":"avrdude.conf";
			if(ApplicationManager.sharedManager().system==ApplicationManager.WINDOWS){
				for each(var fs:File in File.getRootDirectories()){
					var file:File =  new File(fs.url+"Windows/Microsoft.NET/Framework");
					if(file.exists){
						for each(var f:File in file.getDirectoryListing()){
							if(f.name.substr(0,1)=="v"){
								if(Number(f.name.substr(1,3))>=4.0){
//									_bluetooth = new BluetoothExtEmpty();
									_bluetooth = new BluetoothExt();
									break;
								}
							}
						}
					}
					if(_bluetooth!=null){
						break;
					}
				}
			}
			if(_bluetooth!=null){
				_bluetooth.addEventListener(Event.CHANGE,onDiscoverChanged);
				_bluetooth.addEventListener("RECEIVED_DATA",onDataReceived);
			}
			_board = SharedObjectManager.sharedManager().getObject("board","uno");
			_device = SharedObjectManager.sharedManager().getObject("device","uno");
		}
		public function setMBlock(mBlock:MBlock):void{
			_mBlock = mBlock;
		}
		public var asciiString:String = "";
		private function onChanged(evt:Event):void{
			var len:uint = _serial.getAvailable();
			if(len>0){
				var bytes:ByteArray = _serial.readBytes();
				bytes.position = 0;
				asciiString = "";
				var hasNonChar:Boolean = false;
				var c:uint;
				for(var i:uint=0;i<bytes.length;i++){
					c = bytes.readByte();
					asciiString += String.fromCharCode();
					if(c<30){
						hasNonChar = true;
					}
				}
				if(!hasNonChar)dispatchEvent(new Event(Event.CHANGE));
				bytes.position = 0;
				ParseManager.sharedManager().parseBuffer(bytes);
			}
		}
		public function get isConnected():Boolean{
			if(_bluetooth==null){
				return _serial.isConnected;
			}
			return _serial.isConnected||_bluetooth.connected;
		}
		public function get isSerialConnected():Boolean{
			return _serial.isConnected;
		}
		public function get isBluetoothSupported():Boolean{
			if(_bluetooth!=null)
			return _bluetooth.supported;
			return false;
		}
		public function get list():Array{
			try{
				_currentList = formatArray(_serial.list().split(",").sort());
				var emptyIndex:int = _currentList.indexOf("");
				if(emptyIndex>-1){
					_currentList.splice(emptyIndex,emptyIndex+1);
				}
			}catch(e:*){
				
			}
			return _currentList;
		}
		private function formatArray(arr:Array):Array {
			var obj:Object={};
			return arr.filter(function(item:*, index:int, array:Array):Boolean{
				return !obj[item]?obj[item]=true:false
			});
		}
		public function update():void{
			if(_bluetooth!=null){
				if(_bluetooth.connected){
					MBlock.app.topBarPart.setBluetoothTitle(true);
					MBlock.app.topBarPart.setConnectedTitle(_bluetooth.connectName+" "+Translator.map("Connected"));
				}else{
					MBlock.app.topBarPart.setBluetoothTitle(false);
					if(!_serial.isConnected){
						MBlock.app.topBarPart.setDisconnectedTitle();
						return;
					}else{
						MBlock.app.topBarPart.setConnectedTitle(this.currentPort+" "+Translator.map("Connected"));
					}
				}
			}else{
				if(!_serial.isConnected){
					MBlock.app.topBarPart.setDisconnectedTitle();
					return;
				}else{
					MBlock.app.topBarPart.setConnectedTitle(this.currentPort+" "+Translator.map("Connected"));
				}
			}
		}
		public function sendBytes(bytes:ByteArray):int{
			if(_bluetooth!=null){
				if(_bluetooth.connected){
					return _bluetooth.writeBuffer(bytes);
				}else{
					if(_serial.isConnected){
						return _serial.writeBytes(bytes);
					}
				}
			}else{
				if(_serial.isConnected){
					return _serial.writeBytes(bytes);
				}
			}
			return 0;
		}
		public function sendString(msg:String):int{
			if(_bluetooth!=null){
				if(_bluetooth.connected){
					return _bluetooth.writeString(msg);
				}else{
					return _serial.writeString(msg);
				}
			}else{
				return _serial.writeString(msg);
			}
		}
		public function get board():String{
			return _board;
		}
		public function set board(s:String):void{
			_board = s;
		}
		public function set device(s:String):void{
			_device = s;
		}
		public function get device():String{
			return _device;
		}
		public function connect(port:String,baudrate:uint=115200,hexFile:String=""):int{
			var tempPort:String = port;
			if(port=="orion"||port=="mbot"){
				if(port=="orion"){
					MBlock.app.openOrion();
				}
				_device = port;
				port = "uno";
			}else if(port=="baseboard"){
				_device = port;
				port = "leonardo";
			}else{
				if(port.indexOf("uno")>-1||port.indexOf("leonardo")>-1){
					_device = port;
				}
			}
			if(port.indexOf("uno")>-1||port.indexOf("leonardo")>-1){
				_board = port;
				SharedObjectManager.sharedManager().setObject("board",(tempPort!=port)?tempPort:port);
				SharedObjectManager.sharedManager().setObject("device",_device);
//				MBlock.app.getPaletteBuilder().showBlocksForCategory(Specs.myBlocksCategory,true);
				MBlock.app.scriptsPart.selector.select(Specs.myBlocksCategory,true);
				LogManager.sharedManager().log("port:"+port+"\r\n");
				LogManager.sharedManager().log("board:"+_board+"\r\n");
				LogManager.sharedManager().log("state:"+_serial.isConnected+"\r\n");
				
				return 0;
			}
			if(port.indexOf("source")>-1){
				
				MBlock.app.track("/OpenSerial/ViewSource");
				var file:File = new File(File.documentsDirectory.nativePath+"/mBlock/firmware/"+(_device=="mbot"?"mbot_firmware":"mblock_firmware"));
				file.openWithDefaultApplication();
				return 0;
			}
			var result:int;
			
			if(_serial.isConnected){
				if(port.indexOf("upgrade")>-1){
					MBlock.app.track("/OpenSerial/Upgrade");
					executeUpgrade();
					_hexToDownload = hexFile;
					MBlock.app.topBarPart.setDisconnectedTitle();
					ArduinoManager.sharedManager().isUploading = false;
					if(_device=="leonardo"||_device=="baseboard"){
						_serial.close();
						setTimeout(function():void{
							_serial.open(currentPort,1200);
							setTimeout(function():void{
								_serial.close();	
								if(ApplicationManager.sharedManager().system==ApplicationManager.WINDOWS){
									var timer:Timer = new Timer(500,20);
									timer.addEventListener(TimerEvent.TIMER,checkAvailablePort);
									function onCLoseDialog(e:TimerEvent):void{
										_dialog.cancel();
									}
									timer.addEventListener(TimerEvent.TIMER_COMPLETE,onCLoseDialog);
									timer.start();
								}
							},100);
						},100);
						if(ApplicationManager.sharedManager().system==ApplicationManager.MAC_OS){
							setTimeout(upgradeFirmware,2000);
						}
						
					}else{
						_serial.close();
						upgradeFirmware();
						currentPort = "";
					}
				}else{
					if(port==currentPort){
						disconnect();
					}else{
						if(port.indexOf("COM")>-1|| port.indexOf("/dev/tty.")>-1){
							_serial.close();
							closeBluetooth();
							MBlock.app.track("/OpenSerial/OpenConnect");
							_selectPort = port;
							result = _serial.open(port,baudrate,true);
							if(result==0){
								currentPort = port;
								_serial.addEventListener(Event.CHANGE,onChanged);
								MBlock.app.topBarPart.setConnectedTitle(port+" "+Translator.map("Connected"));
								ParseManager.sharedManager().queryVersion();
							}else{
								currentPort = "";
							}
							return result;
						}
					}
				}
			}else{
				if(port.indexOf("COM")>-1 || port.indexOf("/dev/tty.")>-1){
					_serial.close();
					
					closeBluetooth();
					MBlock.app.track("/OpenSerial/OpenConnect");
					result = _serial.open(port,baudrate,true);
					_selectPort = port;
					if(result==0){
						currentPort = port;
						_serial.addEventListener(Event.CHANGE,onChanged);
						MBlock.app.topBarPart.setConnectedTitle(port+" "+Translator.map("Connected"));
						ParseManager.sharedManager().queryVersion();
					}else{
						currentPort = "";
					}
					return result;
				}
			}
			
			return 0;
		}
		public function disconnect():void{
			currentPort = "";
			MBlock.app.topBarPart.setDisconnectedTitle();
			MBlock.app.topBarPart.setBluetoothTitle(false);
			ArduinoManager.sharedManager().isUploading = false;
			_serial.close();
			_serial.removeEventListener(Event.CHANGE,onChanged);
			if(_bluetooth!=null){
				if(_bluetooth.connected){
					_bluetooth.disconnect();
				}
			}
		}
		public function reconnectSerial():void{
			if(_serial.isConnected){
				_serial.close();
				setTimeout(function():void{connect(currentPort,115200);},50);
				//setTimeout(function():void{_serial.close();},1000);
			}
		}
		public function beginDiscover():void{
			if(!SerialManager.sharedManager().isBluetoothSupported){
				return;
			}
			if(_bluetooth.connected){
				closeBluetooth();
			}else{
				if(!_bluetooth.isDiscovering){
					
					MBlock.app.track("/OpenBluetooth");
					function cancel():void{
						SerialManager.sharedManager().removeDiscoverDialogbox(d);
						d.cancel();
					}
					var d:DialogBox = new DialogBox();
					d.addTitle(Translator.map('Discovering Bluetooth') + '...');
					d.addButton('Cancel', cancel);
					d.showOnStage(MBlock.app.stage);
					SerialManager.sharedManager().addDiscoverDialogbox(d);
					_bluetooth.beginDiscover();
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
		public function openConnect(index:uint):void{
			_bluetooth.connect(index);
			var i:uint = 0;
			function checkName():void{
				if(_bluetooth.connected){
					currentPort = _bluetooth.connectName;
					MBlock.app.topBarPart.setBluetoothTitle(true);
					MBlock.app.topBarPart.setConnectedTitle(_bluetooth.connectName+" "+Translator.map("Connected"));
				}else{
					if(i<10){
						setTimeout(checkName,500);
					}
					i++;
				}
			}
			setTimeout(checkName,1000);
		}
		public function get isBluetoothConnected():Boolean{
			if(_bluetooth!=null){
				return _bluetooth.connected;
			}
			return false;
		}
		public function closeBluetooth():void{
			if(_bluetooth!=null){
				if(_bluetooth.connected){
					MBlock.app.topBarPart.setBluetoothTitle(false);
					MBlock.app.topBarPart.setDisconnectedTitle();
					_bluetooth.disconnect();
				}
			}
		}
		private function onDiscoverChanged(evt:Event):void{
			
			var str:String = _bluetooth.discoverResult();
			if(str.length<3){
				return;
			}
			var list:Array = str.split(",");
			trace("device list:",list);
			for(var i:uint=0;i<list.length;i++){
				for(var j:* in _dialogboxDiscover){
					var d:DialogBox = _dialogboxDiscover[j];
					
					if(i==0){
						d.clearButtons();
					}
					d.addButtonExt(list[i],""+i,onClickConnect);
					if(i==list.length-1){
						function onClose():void{
							d.cancel();
						}
						d.addButton("Cancel",onClose);
						d.fixLayout();
					}
				}
			}
			
			function onClickConnect(data:String):void{
				openConnect(Number(data));
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
			var bytes:ByteArray = _bluetooth.receivedBuffer();
			if(bytes.length>0){
//				trace("data length:",bytes.length);
				ParseManager.sharedManager().parseBuffer(bytes);
			}else{
				trace("no data");
			}
		}
		private var process:NativeProcess;
		private function checkAvailablePort(evt:TimerEvent):void{
			
			var lastList:Array = _serial.list().split(",");
			for(var i:* in _currentList){
				var index:int = lastList.indexOf(_currentList[i]);
				if(index>-1){
					lastList.splice(index,1);
				}
			}
			if(lastList.length>0&&lastList[0].indexOf("COM")>-1){
				Timer(evt.target).stop();
				currentPort = lastList[0];
				upgradeFirmware();
				currentPort = "";
			}
			
			
		}
		public function upgradeFirmware(hexfile:String=""):void{
			MBlock.app.topBarPart.setDisconnectedTitle();
			var file:File = File.applicationDirectory;
			var path:File = file.resolvePath("tools");
			var filePath:String = path.nativePath;//.split("\\").join("/")+"/";
			file = path.resolvePath(_avrdude);//外部程序名
			trace("avrdude:",file.nativePath,filePath+"/"+_avrdudeConfig,"\n");
			var tf:File;
			if(NativeProcess.isSupported) {
				var nativeProcessStartupInfo:NativeProcessStartupInfo =new NativeProcessStartupInfo();
				nativeProcessStartupInfo.executable = file;
				var v:Vector.<String> = new Vector.<String>();//外部应用程序需要的参数
				v.push("-C");
				v.push(filePath+"/"+_avrdudeConfig)
				v.push("-v");
				v.push("-v");
				v.push("-v");
				v.push("-v");
				if(_device=="leonardo"||_device=="baseboard"){
					v.push("-patmega32u4");
					v.push("-cavr109");
					v.push("-P"+currentPort);
					v.push("-b57600");
					v.push("-D");
					v.push("-U");
					if(_hexToDownload.length==0){
						var hexFile:String = (File.documentsDirectory.nativePath+"/mBlock/tools/hex/leonardo.hex");//.split("\\").join("/");
						tf = new File(hexFile);
						v.push("flash:w:"+hexFile+":i");
					}else{
						tf = new File(_hexToDownload);
						v.push("flash:w:"+_hexToDownload+":i");
					}
				}else{
					v.push("-patmega328p");
					v.push("-carduino"); 
					v.push("-P"+currentPort);
					v.push("-b115200");
					v.push("-D");
					v.push("-V");
					v.push("-U");
					if(_hexToDownload.length==0){
						if(_device=="mbot"){
							var hexFile_mbot:String = (File.documentsDirectory.nativePath+"/mBlock/tools/hex/mbot.hex");//.split("\\").join("/");
							v.push("flash:w:"+hexFile_mbot+":i");
							tf = new File(hexFile_mbot);
						}else{
							var hexFile_uno:String = (File.documentsDirectory.nativePath+"/mBlock/tools/hex/uno.hex");//.split("\\").join("/");
							v.push("flash:w:"+hexFile_uno+":i");
							tf = new File(hexFile_uno);
						}
					}else{
						v.push("flash:w:"+_hexToDownload+":i");
						tf = new File(_hexToDownload);
					}
				}
				if(tf!=null){
					if(tf.exists){
						_upgradeBytesTotal = tf.size;
						trace("total:",_upgradeBytesTotal);
					}
				}
				nativeProcessStartupInfo.arguments = v;
				process = new NativeProcess();
				process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA,onStandardOutputData);
				process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
				process.addEventListener(NativeProcessExitEvent.EXIT, onExit);
				process.addEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, onIOError);
				process.addEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, onIOError);
				process.start(nativeProcessStartupInfo);
				ArduinoManager.sharedManager().isUploading = true;
			}else{
				trace("no support");
			}
			
		}
		private function onStandardOutputData(event:ProgressEvent):void {
//			_upgradeBytesLoaded+=process.standardOutput.bytesAvailable;
			
//			_dialog.setText(Translator.map('Executing')+" ... "+_upgradeBytesLoaded+"%");
			LogManager.sharedManager().log(process.standardOutput.readUTFBytes(process.standardOutput.bytesAvailable ));
		}
		public function onErrorData(event:ProgressEvent):void
		{
			var msg:String = process.standardError.readUTFBytes(process.standardError.bytesAvailable);
			var arr:Array = msg.split(_board=="leonardo"?"Send: B [42] . [00] . [":"Send: d [64] . [00] . [");
			if(msg.indexOf("writing flash (")>0){
				_upgradeBytesTotal = Math.max(3000,Number(msg.split("writing flash (")[1].split(" bytes)")[0]));
				
			}
//			trace("total:",_upgradeBytesLoaded,_upgradeBytesTotal);
			_upgradeBytesLoaded+=arr.length>1?Number("0x"+arr[1].split("]")[0]):0;
			var progress:Number = Math.min(100,Math.floor(_upgradeBytesLoaded/_upgradeBytesTotal*105));
			if(progress>=100){
//				setTimeout(_dialog.cancel,2000); 
				_dialog.setText(Translator.map('Upload Finish')+" ... "+100+"%");
//				setTimeout(connect,2000,_selectPort);
			}else{
				_dialog.setText(Translator.map('Uploading')+" ... "+Math.min(100,isNaN(progress)?100:progress)+"%");
			}
			LogManager.sharedManager().log(msg); 
		}
		
		public function onExit(event:NativeProcessExitEvent):void
		{
			ArduinoManager.sharedManager().isUploading = false;
			LogManager.sharedManager().log("Process exited with "+event.exitCode);
			_dialog.setText(Translator.map('Upload Finish')+" ... "+100+"%");
			setTimeout(connect,2000,_selectPort);
			//setTimeout(_dialog.cancel,2000);
		}
		
		public function onIOError(event:IOErrorEvent):void
		{
			LogManager.sharedManager().log(event.toString());
		}
		public function executeUpgrade():void {
			if(!_isInitUpgrade){
				_isInitUpgrade = true;
				function cancel():void { _dialog.cancel(); }
				_dialog.addTitle(Translator.map('Start Uploading'));
				_dialog.addButton(Translator.map('Close'), cancel);
			}else{
				_dialog.setTitle(('Start Uploading'));
				_dialog.setButton(('Close'));
			}
			_upgradeBytesLoaded = 0;
			_dialog.setText(Translator.map('Executing')+" ... 0%");
			_dialog.showOnStage(_mBlock.stage);
		}
	}
}