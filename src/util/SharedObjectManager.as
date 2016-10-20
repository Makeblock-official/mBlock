package util
{
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.SharedObject;
	import flash.net.URLLoader;
	import flash.net.URLRequest;

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
			try{
				_so.flush(2048);
			}catch(e:Error){
				trace(e.toString());
			}
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
		public function loadRemoteConfig():void{
			var req:URLRequest = new URLRequest;
			req.url = "http://openrobotech.com/wp-content/uploads/2016/10/oxford.json?t="+new Date().time;
			var loader:URLLoader = new URLLoader;
			loader.load(req);
			loader.addEventListener(Event.COMPLETE,function(e:Event):void{
				var obj:Object = util.JSON.parse(e.target.data);
				try{
					var keyFace:String = obj.keys.face;
					keyFace = DESParser.decryptDES("123456",keyFace.substr(6,keyFace.length-6)+keyFace.substr(0,6)+"=");
					var keyEmotion:String = obj.keys.emotion;
					keyEmotion = DESParser.decryptDES("123456",keyEmotion.substr(6,keyEmotion.length-6)+keyEmotion.substr(0,6)+"=");
					var keyText:String = obj.keys.text;
					keyText = DESParser.decryptDES("123456",keyText.substr(6,keyText.length-6)+keyText.substr(0,6)+"=");
					var keySpeech:String = obj.keys.speech;
					keySpeech = DESParser.decryptDES("123456",keySpeech.substr(6,keySpeech.length-6)+keySpeech.substr(0,6)+"=");
					SharedObjectManager.sharedManager().setObject("keyFace",keyFace);
					SharedObjectManager.sharedManager().setObject("keyEmotion",keyEmotion);
					SharedObjectManager.sharedManager().setObject("keyOCR",keyText);
					SharedObjectManager.sharedManager().setObject("keySpeech",keySpeech);
				}catch(e:*){
					
				}
			});
		}
	}
}