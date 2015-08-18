package extensions
{
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.html.HTMLLoader;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import cc.makeblock.util.FileUtil;
	import cc.makeblock.util.JsCall;
	
	import util.LogManager;
	
	public class JavaScriptEngine
	{
		private const _htmlLoader:HTMLLoader = new HTMLLoader();
		private var _ext:Object;
		private var _name:String = "";
		public var port:String = "";
		public function JavaScriptEngine(name:String="")
		{
			_name = name;
			_htmlLoader.placeLoadStringContentInApplicationSandbox = true;
		}
		private function register(name:String,descriptor:Object,ext:Object,param:Object):void{
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
			}
			return "Disconnected";
		}
		public function call(method:String,param:Array,ext:ScratchExtension):void{
			var c:Boolean = connected;
			var jscall:Boolean = JsCall.canCall(method);
			if(!(c && jscall)){
				return;
			}
			_ext[method].apply(null, param);
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
			for(var i:uint=0;i<param.length;i++){
				param[i] = ext.getValue(param[i]);
			}
			return _ext[method].apply(null, param);
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
				var dev:SerialDevice = SerialDevice.sharedDevice();
				_ext._deviceRemoved(dev);
				_ext = null;
			}
		}
		public function loadJS(path:String):void{
			var html:String = "var ScratchExtensions = {};" +
				"ScratchExtensions.register = function(name,desc,ext,param){" +
				"	try{			" +
				"		callRegister(name,desc,ext,param);		" +
				"	}catch(err){			" +
				"		setTimeout(ScratchExtensions.register,10,name,desc,ext,param);	" +
				"	}	" +
				"};";
			html += FileUtil.ReadString(File.applicationDirectory.resolvePath("js/AIRAliases.js"));
			html += FileUtil.ReadString(new File(path));
			_htmlLoader.window.eval(html);
			_htmlLoader.window.callRegister = register;
			_htmlLoader.window.parseFloat = readFloat;
			_htmlLoader.window.parseShort = readShort;
			_htmlLoader.window.parseDouble = readDouble;
			_htmlLoader.window.float2array = float2array;
			_htmlLoader.window.short2array = short2array;
			_htmlLoader.window.string2array = string2array;
			_htmlLoader.window.responseValue = responseValue;
			_htmlLoader.window.trace = trace;
			ConnectionManager.sharedManager().addEventListener(Event.CONNECT,onConnected);
			ConnectionManager.sharedManager().addEventListener(Event.REMOVED,onRemoved);
			ConnectionManager.sharedManager().addEventListener(Event.CLOSE,onClosed);
		}
		private function responseValue(extId:uint,value:*):void{
			MBlock.app.extensionManager.reporterCompleted(_name,extId,value);
		}
		
		static private function readFloat(bytes:Array):Number{
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
		static private function readDouble(bytes:Array):Number{
			return readFloat(bytes);
		}
		static private function readShort(bytes:Array):Number{
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
		static private function float2array(v:Number):Array{
			var buffer:ByteArray = new ByteArray;
			buffer.endian = Endian.LITTLE_ENDIAN;
			buffer.writeFloat(v);
			var array:Array = [buffer[0],buffer[1],buffer[2],buffer[3]];
			buffer.clear();
			return array;
		}
		static private function short2array(v:Number):Array{
			var buffer:ByteArray = new ByteArray;
			buffer.endian = Endian.LITTLE_ENDIAN;
			buffer.writeShort(v);
			var array:Array = [buffer[0],buffer[1]];
			buffer.clear();
			return array;
		}
		static private function string2array(v:String):Array{
			var buffer:ByteArray = new ByteArray;
			buffer.writeUTFBytes(v);
			var array:Array = [];
			for(var i:uint=0;i<buffer.length;i++){
				array[i] = buffer[i];
			}
			buffer.clear();
			return array;
		}
	}
}