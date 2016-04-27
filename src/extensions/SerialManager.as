package extensions
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	import cc.makeblock.util.UploadSizeInfo;
	
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
			
//		private var _isMacOs:Boolean = ApplicationManager.sharedManager().system==ApplicationManager.MAC_OS;
//		private var _avrdude:String = "";
//		private var _avrdudeConfig:String = "";
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
//			_avrdude = _isMacOs?"avrdude":"avrdude.exe";
//			_avrdudeConfig = _isMacOs?"avrdude_mac.conf":"avrdude.conf";
			
			_board = SharedObjectManager.sharedManager().getObject("board","uno");
			_device = SharedObjectManager.sharedManager().getObject("device","uno");
			var timer:Timer = new Timer(4000);
			timer.addEventListener(TimerEvent.TIMER,onTimerCheck);
			timer.start();
		}
		private function onTimerCheck(evt:TimerEvent):void{
			if(_serial.isConnected){
				if(this.list.indexOf(_selectPort)==-1){
					this.close();
				}
			}
		}
		public function setMBlock(mBlock:MBlock):void{
			_mBlock = mBlock;
		}
		public var asciiString:String = "";
		private function onChanged(evt:Event):void{
			var len:uint = _serial.getAvailable();
			if(len>0){
				ConnectionManager.sharedManager().onReceived(_serial.readBytes());
			}
			return;
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
			return _serial.isConnected;
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
			if(!_serial.isConnected){
				MBlock.app.topBarPart.setDisconnectedTitle();
				return;
			}else{
				MBlock.app.topBarPart.setConnectedTitle("Serial Port");
			}
		}
		
		public function sendBytes(bytes:ByteArray):void{
			if(_serial.isConnected){
				_serial.writeBytes(bytes);
			}
		}
		public function sendString(msg:String):int{
			return _serial.writeString(msg);
		}
		public function readBytes():ByteArray{
			var len:uint = _serial.getAvailable();
			if(len>0){
				return _serial.readBytes();
			}
			return new ByteArray;
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
		public function open(port:String,baud:uint=115200):Boolean{
			if(_serial.isConnected){
				_serial.close();
			}
			_serial.addEventListener(Event.CHANGE,onChanged);
			var r:uint = _serial.open(port,baud);
			_selectPort = port;
			ArduinoManager.sharedManager().isUploading = false;
			if(r==0){
				MBlock.app.topBarPart.setConnectedTitle("Serial Port");
			}
			return r == 0;
		}
		public function close():void{
			if(_serial.isConnected){
				_serial.removeEventListener(Event.CHANGE,onChanged);
				_serial.close();
				ConnectionManager.sharedManager().onClose(_selectPort);
			}
		}
		public function connect(port:String):int{
			if(SerialDevice.sharedDevice().ports.indexOf(port)>-1&&_serial.isConnected){
				close();
			}else{
				if(_serial.isConnected){
					close();
				}
				setTimeout(ConnectionManager.sharedManager().onOpen,100,port);
			}
			return 0;
		}
		public function upgrade(hexFile:String=""):void{
			if(!isConnected){
				return;
			}
			MBlock.app.track("/OpenSerial/Upgrade");
			executeUpgrade();
			_hexToDownload = hexFile;
			MBlock.app.topBarPart.setDisconnectedTitle();
			ArduinoManager.sharedManager().isUploading = false;
			if(DeviceManager.sharedManager().currentDevice.indexOf("leonardo")>-1){
				_serial.close();
				setTimeout(function():void{
					_serial.open(SerialDevice.sharedDevice().port,1200);
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
					},500);
				},100);
				if(ApplicationManager.sharedManager().system==ApplicationManager.MAC_OS){
					setTimeout(upgradeFirmware,2000);
				}
			}else{
				_serial.close();
				upgradeFirmware();
				currentPort = "";
			}
		}
		public function openSource():void{
			MBlock.app.track("/OpenSerial/ViewSource");
			var file:File = ApplicationManager.sharedManager().documents.resolvePath("mBlock/firmware/" + getFirmwareName());
			if(file.exists && file.isDirectory){
				file.openWithDefaultApplication();
			}
		}
		static private function getFirmwareName():String
		{
			var boardName:String = DeviceManager.sharedManager().currentBoard;
			if(boardName == "mbot_uno"){
				return "mbot_firmware";
			}
			if(boardName.indexOf("me/orion_uno")>-1){
				return "orion_firmware";
			}
			if(boardName.indexOf("me/baseboard")>-1){
				return "baseboard_firmware";
			}
			if(boardName.indexOf("me/uno_shield")>-1){
				return "shield_firmware";
			}
			if(boardName.indexOf("me/auriga") >= 0){
				return "Firmware_for_Auriga";
			}
			return "orion_firmware";
		}
		public function disconnect():void{
			currentPort = "";
			MBlock.app.topBarPart.setDisconnectedTitle();
//			MBlock.app.topBarPart.setBluetoothTitle(false);
			ArduinoManager.sharedManager().isUploading = false;
			_serial.close();
			_serial.removeEventListener(Event.CHANGE,onChanged);
		}
		public function reconnectSerial():void{
			if(_serial.isConnected){
				_serial.close();
				setTimeout(function():void{connect(currentPort);},50);
				//setTimeout(function():void{_serial.close();},1000);
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
				var temp:String = SerialDevice.sharedDevice().port;
				SerialDevice.sharedDevice().port = lastList[0];
				upgradeFirmware();
				SerialDevice.sharedDevice().port = temp;
			}
			
			
		}
		
		static private function getAvrDude():File
		{
			if(ApplicationManager.sharedManager().system == ApplicationManager.MAC_OS){
				return File.applicationDirectory.resolvePath("Arduino/Arduino.app/Contents/Java/hardware/tools/avr/bin/avrdude");
			}
			return File.applicationDirectory.resolvePath("Arduino/hardware/tools/avr/bin/avrdude.exe");
		}
		
		static private function getAvrDudeConfig():File
		{
			if(ApplicationManager.sharedManager().system == ApplicationManager.MAC_OS){
				return File.applicationDirectory.resolvePath("Arduino/Arduino.app/Contents/Java/hardware/tools/avr/etc/avrdude.conf");
			}
			return File.applicationDirectory.resolvePath("Arduino/hardware/tools/avr/etc/avrdude.conf");
		}
		
		public function upgradeFirmware(hexfile:String=""):void{
			MBlock.app.topBarPart.setDisconnectedTitle();
			var file:File = getAvrDude();//外部程序名
			if(!file.exists){
				trace("upgrade fail!");
				return;
			}
			var tf:File;
			var currentDevice:String = DeviceManager.sharedManager().currentDevice;
			currentPort = SerialDevice.sharedDevice().port;
//			if(NativeProcess.isSupported) {
				var nativeProcessStartupInfo:NativeProcessStartupInfo =new NativeProcessStartupInfo();
				nativeProcessStartupInfo.executable = file;
				var v:Vector.<String> = new Vector.<String>();//外部应用程序需要的参数
				v.push("-C");
				v.push(getAvrDudeConfig().nativePath)
				v.push("-v");
				v.push("-v");
				v.push("-v");
				v.push("-v");
				if(currentDevice=="leonardo"){
					v.push("-patmega32u4");
					v.push("-cavr109");
					v.push("-P"+currentPort);
					v.push("-b57600");
					v.push("-D");
					v.push("-U");
					if(_hexToDownload.length==0){
						var hexFile_baseboard:String = getHexFilePath();
						tf = new File(hexFile_baseboard);
						v.push("flash:w:"+hexFile_baseboard+":i");
					}else{
						tf = new File(_hexToDownload);
						v.push("flash:w:"+_hexToDownload+":i");
					}
				}else if(currentDevice=="uno"){
					v.push("-patmega328p");
					v.push("-carduino"); 
					v.push("-P"+currentPort);
					v.push("-b115200");
					v.push("-D");
					v.push("-V");
					v.push("-U");
					if(_hexToDownload.length==0){
						var hexFile_uno:String = getHexFilePath();
						v.push("flash:w:"+hexFile_uno+":i");
						tf = new File(hexFile_uno);
					}else{
						v.push("flash:w:"+_hexToDownload+":i");
						tf = new File(_hexToDownload);
					}
				}else if(currentDevice=="mega1280"){
					v.push("-patmega1280");
					v.push("-cwiring");
					v.push("-P"+currentPort);
					v.push("-b57600");
					v.push("-D");
					v.push("-U");
					if(_hexToDownload.length==0){
						var hexFile_mega1280:String = (ApplicationManager.sharedManager().documents.nativePath+"/mBlock/tools/hex/mega1280.hex");//.split("\\").join("/");
						tf = new File(hexFile_mega1280);
						v.push("flash:w:"+hexFile_mega1280+":i");
					}else{
						tf = new File(_hexToDownload);
						v.push("flash:w:"+_hexToDownload+":i");
					}
				}else if(currentDevice=="mega2560"){
					v.push("-patmega2560");
					v.push("-cwiring");
					v.push("-P"+currentPort);
					v.push("-b115200");
					v.push("-D");
					v.push("-U");
					if(_hexToDownload.length==0){
						var hexFile_mega2560:String = getHexFilePath();//.split("\\").join("/");
						tf = new File(hexFile_mega2560);
						v.push("flash:w:"+hexFile_mega2560+":i");
					}else{
						tf = new File(_hexToDownload);
						v.push("flash:w:"+_hexToDownload+":i");
					}
				}else if(currentDevice=="nano328"){
					v.push("-patmega328p");
					v.push("-carduino");
					v.push("-P"+currentPort);
					v.push("-b57600");
					v.push("-D");
					v.push("-U");
					if(_hexToDownload.length==0){
						var hexFile_nano328:String = (ApplicationManager.sharedManager().documents.nativePath+"/mBlock/tools/hex/nano328.hex");//.split("\\").join("/");
						tf = new File(hexFile_nano328);
						v.push("flash:w:"+hexFile_nano328+":i");
					}else{
						tf = new File(_hexToDownload);
						v.push("flash:w:"+_hexToDownload+":i");
					}
				}else if(currentDevice=="nano168"){
					v.push("-patmega168");
					v.push("-carduino");
					v.push("-P"+currentPort);
					v.push("-b19200");
					v.push("-D");
					v.push("-U");
					if(_hexToDownload.length==0){
						var hexFile_nano168:String = (ApplicationManager.sharedManager().documents.nativePath+"/mBlock/tools/hex/nano168.hex");//.split("\\").join("/");
						tf = new File(hexFile_nano168);
						v.push("flash:w:"+hexFile_nano168+":i");
					}else{
						tf = new File(_hexToDownload);
						v.push("flash:w:"+_hexToDownload+":i");
					}
				}
				if(tf!=null && tf.exists){
					_upgradeBytesTotal = tf.size;
					trace("total:",_upgradeBytesTotal);
				}else{
					_upgradeBytesTotal = 0;
				}
				nativeProcessStartupInfo.arguments = v;
				process = new NativeProcess();
				process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA,onStandardOutputData);
				process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
				process.addEventListener(NativeProcessExitEvent.EXIT, onExit);
//				process.addEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, onIOError);
//				process.addEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, onIOError);
				process.start(nativeProcessStartupInfo);
				sizeInfo.reset();
				ArduinoManager.sharedManager().isUploading = true;
//			}else{
//				trace("no support");
//			}
			
		}
		
		private function getHexFilePath():String
		{
			var board:String = DeviceManager.sharedManager().currentBoard;
			var fileName:String;
			if(board.indexOf("_uno") > 0){
				if(board.indexOf("mbot") >= 0){
					fileName = "mbot";
				}else if(board.indexOf("shield") >= 0){
					fileName = "shield";
				}else{
					fileName = "uno";
				}
			}else if(board.indexOf("_leonardo") > 0){
				if(board.indexOf("baseboard") >= 0){
					fileName = "baseboard";
				}else{
					fileName = "leonardo";
				}
			}else if(board.indexOf("_mega2560") > 0){
				if(board.indexOf("auriga") >= 0){
					fileName = "auriga";
				}else{
					fileName = "mega2560";
				}
			}else{
				throw new Error(board);
			}
			return ApplicationManager.sharedManager().documents.nativePath + "/mBlock/tools/hex/" + fileName + ".hex";
		}
		/*
		private function onStandardOutputData(event:ProgressEvent):void {
//			_upgradeBytesLoaded+=process.standardOutput.bytesAvailable;
			
//			_dialog.setText(Translator.map('Executing')+" ... "+_upgradeBytesLoaded+"%");
			LogManager.sharedManager().log(process.standardOutput.readUTFBytes(process.standardOutput.bytesAvailable ));
		}
		*/
		private var errorText:String;
		private var sizeInfo:UploadSizeInfo = new UploadSizeInfo();
		private function onStandardOutputData(event:ProgressEvent):void
		{
			var msg:String = process.standardError.readUTFBytes(process.standardError.bytesAvailable);
			MBlock.app.scriptsPart.appendRawMessage(msg);
		}
		private function onErrorData(event:ProgressEvent):void
		{
			var msg:String = process.standardError.readUTFBytes(process.standardError.bytesAvailable);
			if(null == errorText){
				errorText = msg;
			}else{
				errorText += msg;
			}
			MBlock.app.scriptsPart.appendRawMessage(msg);
			_dialog.setText(Translator.map('Uploading') + " ... " + sizeInfo.update(msg) + "%");
		}
		
		private function onExit(event:NativeProcessExitEvent):void
		{
			ArduinoManager.sharedManager().isUploading = false;
			LogManager.sharedManager().log("Process exited with "+event.exitCode);
			if(event.exitCode > 0){
				_dialog.setText(Translator.map('Upload Failed'));
				LogManager.sharedManager().log(errorText);
				MBlock.app.scriptsPart.appendMsgWithTimestamp(errorText, true);
			}else{
				_dialog.setText(Translator.map('Upload Finish'));
			}
			setTimeout(open,2000,_selectPort);
			errorText = null;
			//setTimeout(_dialog.cancel,2000);
		}
		/*
		public function onIOError(event:IOErrorEvent):void
		{
			LogManager.sharedManager().log(event.toString());
		}
		*/
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
			_dialog.setText(Translator.map('Executing'));
			_dialog.showOnStage(_mBlock.stage);
		}
		
		public function reopen():void
		{
			open(_selectPort);
		}
	}
}