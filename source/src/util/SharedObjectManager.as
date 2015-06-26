package util
{
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
		public function clear():void{
			_so.clear();
		}
	}
}