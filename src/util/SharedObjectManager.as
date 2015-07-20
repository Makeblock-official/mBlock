package util
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.SharedObject;

	public class SharedObjectManager
	{
		private static var _instance:SharedObjectManager;
		private var _so:SharedObject;
		public function SharedObjectManager()
		{
			_so = SharedObject.getLocal("makeblock","/");
		}
		public static function sharedManager():SharedObjectManager{
			if(_instance==null){
				_instance = new SharedObjectManager;
			}
			return _instance;
		}
		public function getObject(key:String,def:*=""):*{
			if(available(key)){
				return _so.data[key];
			}
			return def;
		}
		public function setObject(key:String,value:*):void{
			_so.data[key] = value;
			_so.flush(2048);
		}
		public function available(key:String):Boolean{
			if(_so.data[key]==undefined){
				return false;
			}
			return true;
		}
		public function setLocalFile(key:String,value:*):void{
			var file:File = ApplicationManager.sharedManager().documents.resolvePath("mBlock/store/"+key+".txt");
			var stream:FileStream = new FileStream();
			stream.open(file,FileMode.WRITE);
			stream.writeObject(value);
			stream.close();
		}
		public function getLocalFile(key:String,def:*=""):*{
			var file:File = ApplicationManager.sharedManager().documents.resolvePath("mBlock/store/"+key+".txt");
			if(file.exists){
				var stream:FileStream = new FileStream();
				stream.open(file,FileMode.READ);
				return stream.readObject();
			}
			return def;
		}
		public function clear():void{
			_so.clear();
		}
	}
}