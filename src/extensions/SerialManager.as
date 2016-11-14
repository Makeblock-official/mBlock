package extensions
{
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	
	import translation.Translator;
	
	import uiwidgets.DialogBox;
	
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
		
		public function SerialManager()
		{
			
			_board = SharedObjectManager.sharedManager().getObject("board","uno");
			_device = SharedObjectManager.sharedManager().getObject("device","uno");
		}
		public function setMBlock(mBlock:MBlock):void{
			_mBlock = mBlock;
		}
		public function get isConnected():Boolean{
			return false;
		}
		public function get list():Array{
			return _currentList;
		}
		private function formatArray(arr:Array):Array {
			var obj:Object={};
			return arr.filter(function(item:*, index:int, array:Array):Boolean{
				return !obj[item]?obj[item]=true:false
			});
		}
		
		public function sendBytes(bytes:ByteArray):void{
		}
		public function sendString(msg:String):int{
			return 0;
		}
		public function readBytes():ByteArray{
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
			return false;
		}
		public function close():void{
		}
		public function connect(port:String):int{
			return 0;
		}
		public function upgrade(hexFile:String=""):void{
			if(!isConnected){
				return;
			}
			MBlock.app.track("/OpenSerial/Upgrade");
		}
		public function openSource():void{
			MBlock.app.track("/OpenSerial/ViewSource");
		}
		/*
		private function onStandardOutputData(event:ProgressEvent):void {
//			_upgradeBytesLoaded+=process.standardOutput.bytesAvailable;
			
//			_dialog.setText(Translator.map('Executing')+" ... "+_upgradeBytesLoaded+"%");
			LogManager.sharedManager().log(process.standardOutput.readUTFBytes(process.standardOutput.bytesAvailable ));
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