package extensions
{
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.html.HTMLLoader;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.Timer;
	
	import util.LogManager;
	
	public class JavaScriptEngine
	{
//		private static var _instance:JavaScriptManager;
		private var _htmlLoader:HTMLLoader = new HTMLLoader;
		private var _ext:Object;
		private var _timer:Timer = new Timer(1000);
		private var _name:String = "";
		public var port:String = "";
		public function JavaScriptEngine(name:String="")
		{
			_name = name;
			_htmlLoader.placeLoadStringContentInApplicationSandbox = true;
			_timer.addEventListener(TimerEvent.TIMER,onTimer);
		}
		private function onTimer(evt:TimerEvent):void{
			if(_ext){
				LogManager.sharedManager().log("Status:"+_ext._getStatus().msg);
			}
		}
		public function register(name:String,descriptor:Object,ext:Object,param:Object):void{
			_ext = ext;
			
			LogManager.sharedManager().log("registed:"+_ext._getStatus().msg);
			//trace(SerialManager.sharedManager().list());
			//_timer.start();
		}
		public function get connected():Boolean{
			if(_ext){
				return _ext._getStatus().status==2;
			}
			return false;
		}
		public function get msg():String{
			if(_ext){
				return _ext._getStatus().msg;
			}else{
				return "Disconnected";
			}
		}
		public function call(method:String,param:Array,ext:ScratchExtension):void{
			if(!this.connected){
				return;
			}
			try{
				switch(param.length){
					case 0:{
						_ext[method]();
						break;
					}
					case 1:{
						_ext[method](param[0]);
						break;
					}
					case 2:{
						_ext[method](param[0],param[1]);
						break;
					}
					case 3:{
						_ext[method](param[0],param[1],param[2]);
						break;
					}
					case 4:{
						_ext[method](param[0],param[1],param[2],param[3]);
						break;
					}
					case 5:{
						_ext[method](param[0],param[1],param[2],param[3],param[4]);
						break;
					}
					case 6:{
						_ext[method](param[0],param[1],param[2],param[3],param[4],param[5]);
						break;
					}
				}
			}catch(e:Error){
				
			}
		}
		public function requestValue(method:String,param:Array,ext:ScratchExtension):Boolean{
			if(!this.connected){
				return false;
			}
			getValue(method,[ext.nextID].concat(param),ext);
			//MBlock.app.extensionManager.reporterCompleted(ext.name,ext.nextID,v);
			return true;
		}
		public function getValue(method:String,param:Array,ext:ScratchExtension):*{
			if(!this.connected){
				return false;
			}
			var v:*;
			for(var i:uint=0;i<param.length;i++){
				param[i] = ext.getValue(param[i]);
			}
			switch(param.length){
				case 0:{
					v = _ext[method]();
					break;
				}
				case 1:{
					v = _ext[method](param[0]);
					break;
				}
				case 2:{
					v = _ext[method](param[0],param[1]);
					break;
				}
				case 3:{
					v = _ext[method](param[0],param[1],param[2]);
					break;
				}
				case 4:{
					v = _ext[method](param[0],param[1],param[2],param[3]);
					break;
				}
				case 5:{
					v = _ext[method](param[0],param[1],param[2],param[3],param[4]);
					break;
				}
				case 6:{
					v = _ext[method](param[0],param[1],param[2],param[3],param[4],param[5]);
					break;
				}
			}
			return v;
		}
		public function closeDevice():void{
			if(_ext){
				_ext._shutdown();
			}
		}
		private function onConnected(evt:Event):void{
			if(_ext){
				var dev:SerialDevice = SerialDevice.sharedDevice();
				_ext._deviceConnected(dev);
				LogManager.sharedManager().log("register:"+_name);
			}
		}
		private function onClosed(evt:Event):void{
			if(_ext){
				var dev:SerialDevice = SerialDevice.sharedDevice();
				_ext._deviceRemoved(dev);
				LogManager.sharedManager().log("unregister:"+_name);
			}
		}
		private function onRemoved(evt:Event):void{
			if(_ext&&ConnectionManager.sharedManager().extensionName==_name){
				ConnectionManager.sharedManager().removeEventListener(Event.CONNECT,onConnected);
				ConnectionManager.sharedManager().removeEventListener(Event.REMOVED,onRemoved);
				ConnectionManager.sharedManager().removeEventListener(Event.CLOSE,onClosed);
				_htmlLoader.removeEventListener(Event.COMPLETE,onComplete);
				var dev:SerialDevice = SerialDevice.sharedDevice();
				_ext._deviceRemoved(dev);
				_ext = null;
			}
		}
		private function uncaughtScriptExceptionHandler(evt:Event):void{
			
		}
		public function loadJS(path:String=""):void{
			var urlloader:URLLoader = new URLLoader;
			urlloader.load(new URLRequest(path));
			urlloader.addEventListener(Event.COMPLETE,onLoadedJS);
		}
		private function onLoadedJS(evt:Event):void{
			var html:String = "<script>var ScratchExtensions = {};" +
				"ScratchExtensions.register = function(name,desc,ext,param){" +
				"	try{			" +
				"		callRegister(name,desc,ext,param);		" +
				"	}catch(err){			" +
				"		setTimeout(ScratchExtensions.register,10,name,desc,ext,param);	" +
				"	}	" +
				"}	" +
				"</script><script src=\""+File.applicationDirectory.resolvePath("js/AIRAliases.js").url+"\"></script><script>"+evt.target.data+"</script>";
			_htmlLoader.loadString(html);
			_htmlLoader.removeEventListener(Event.COMPLETE,onComplete);
			_htmlLoader.addEventListener(Event.COMPLETE,onComplete);
		}
		private function onComplete(evt:Event):void{
			_htmlLoader.window.callRegister = register;
			_htmlLoader.window.parseFloat = readFloat;
			_htmlLoader.window.parseShort = readShort;
			_htmlLoader.window.parseDouble = readDouble;
			_htmlLoader.window.float2array = float2array;
			_htmlLoader.window.short2array = short2array;
			_htmlLoader.window.string2array = string2array;
			_htmlLoader.window.responseValue = responseValue;
			ConnectionManager.sharedManager().removeEventListener(Event.CONNECT,onConnected);
			ConnectionManager.sharedManager().removeEventListener(Event.REMOVED,onRemoved);
			ConnectionManager.sharedManager().removeEventListener(Event.CLOSE,onClosed);
			ConnectionManager.sharedManager().addEventListener(Event.CONNECT,onConnected);
			ConnectionManager.sharedManager().addEventListener(Event.REMOVED,onRemoved);
			ConnectionManager.sharedManager().addEventListener(Event.CLOSE,onClosed);
		}
		public function responseValue(extId:uint,value:*):void{
			MBlock.app.extensionManager.reporterCompleted(_name,extId,value);
		}
		public function readFloat(bytes:Array):Number{
			var buffer:ByteArray = new ByteArray();
			buffer.endian = Endian.LITTLE_ENDIAN;
			for(var i:uint=0;i<bytes.length;i++){
				buffer.writeByte(bytes[i]);
			}
			if(buffer.length>=4){
				buffer.position = 0;
				var f:Number = buffer.readFloat();
				buffer.clear();
				return f;
			}
			return 0;
		}
		public function readDouble(bytes:Array):Number{
			return readFloat(bytes);
		}
		public function readShort(bytes:Array):Number{
			var buffer:ByteArray = new ByteArray();
			buffer.endian = Endian.LITTLE_ENDIAN;
			for(var i:uint=0;i<bytes.length;i++){
				buffer.writeByte(bytes[i]);
			}
			if(buffer.length>=2){
				buffer.position = 0;
				var v:Number = buffer.readUnsignedShort();
				buffer.clear();
				return v;
			}
			return 0;
		}
		public function float2array(v:Number):Array{
			var buffer:ByteArray = new ByteArray;
			buffer.endian = Endian.LITTLE_ENDIAN;
			buffer.writeFloat(v);
			var array:Array = [buffer[0],buffer[1],buffer[2],buffer[3]];
			buffer.clear();
			return array;
		}
		public function short2array(v:Number):Array{
			var buffer:ByteArray = new ByteArray;
			buffer.endian = Endian.LITTLE_ENDIAN;
			buffer.writeShort(v);
			var array:Array = [buffer[0],buffer[1]];
			buffer.clear();
			return array;
		}
		public function string2array(v:String):Array{
			var buffer:ByteArray = new ByteArray;
			buffer.writeUTFBytes(v);
			var array:Array = [];
			for(var i:uint=0;i<buffer.length;i++){
				array[i] = buffer[i];
			}
			buffer.clear();
			return array;
		}
//		public static function sharedManager():JavaScriptManager{
//			if(_instance==null){
//				_instance = new JavaScriptManager;
//			}
//			return _instance;
//		}
	}
}