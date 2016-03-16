package util
{
	import uiwidgets.DialogBox;

	public class LogManager
	{
		private static var _instance:LogManager;
		private var _isDebug:Boolean = false;
		public function LogManager()
		{
		}
		public static function sharedManager():LogManager{
			if(_instance==null){
				_instance = new LogManager;
			}
			return _instance;
		}
		public function log(msg:String):void{
			trace(new Date().toString()+" : "+msg);
		}
		public function save():void{
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