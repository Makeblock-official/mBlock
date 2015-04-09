package util
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;

	public class LogManager
	{
		private static var _instance:LogManager;
		private var file:File;
		private var stream:FileStream = new FileStream();
		public function LogManager()
		{
			file = new File(File.desktopDirectory.nativePath+"\\log.txt");
			stream.openAsync(file,FileMode.APPEND);
		}
		public static function sharedManager():LogManager{
			if(_instance==null){
				_instance = new LogManager;
			}
			return _instance;
		}
		public function log(msg:String):void{
			trace(msg);
			stream.writeUTFBytes(msg+"\r\n");
		}
		public function save():void{
			stream.close();
		}
	}
}