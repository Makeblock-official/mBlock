package util
{
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import translation.Translator;
	
	import uiwidgets.DialogBox;

	public class LogManager
	{
		private static var _instance:LogManager;
		private var _isDebug:Boolean = false;
		private var file:File;
		private var stream:FileStream = new FileStream();
		public function LogManager()
		{
			if(_isDebug){
				file = new File(File.desktopDirectory.nativePath+"\\log.txt");
				stream.openAsync(file,FileMode.APPEND);
			}
		}
		public static function sharedManager():LogManager{
			if(_instance==null){
				_instance = new LogManager;
			}
			return _instance;
		}
		public function log(msg:String):void{
			trace(msg);
			if(_isDebug){
				stream.writeUTFBytes(msg+"\r\n");
			}
		}
		public function save():void{
			if(_isDebug){
				stream.close();
			}
		}
		public function alert(msg:String):void{
			var dialog:DialogBox = new DialogBox();
			dialog.addTitle("Message");
			dialog.addText(msg);
			function onCancel():void{
				dialog.cancel();
			}
			
			dialog.addButton("OK",onCancel);
			dialog.showOnStage(MBlock.app.stage);
		}
	}
}