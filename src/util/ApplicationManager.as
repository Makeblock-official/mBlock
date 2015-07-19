package util{
	import flash.filesystem.File;
	import flash.system.Capabilities;

	public class ApplicationManager{
		public function ApplicationManager():void{

		}
		public static const WINDOWS:uint = 1;
		public static const MAC_OS:uint = 2;
		private static var _instance:ApplicationManager;
		public var launchTime:uint = 0;
		public var contractedOffsetX:int = -480;
		public var contractedOffsetY:int = 0;
		public var isCatVersion:Boolean = false;
		public static function sharedManager():ApplicationManager{
			if(_instance==null){
				_instance = new ApplicationManager;
			}
			return _instance;
		}
		private var _file:File;
		public function get documents():File{
			if(_file==null){
				
				_file = File.applicationStorageDirectory;
				//不再放入文档目录下
//				try{
//					_file = File.documentsDirectory;
//				}catch(err:Error){
//					_file = File.applicationStorageDirectory;
//				}
			}
			return _file;
		}
		public function get system():uint{
			if(Capabilities.os.indexOf("Window")>-1){
				return 1;
			}
			return 2;
		}
	}
}