package util
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
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
			trace(new Date().toString()+" : "+msg);
			if(_isDebug){
				stream.writeUTFBytes(new Date().toString()+" : "+msg+"\r\n");
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