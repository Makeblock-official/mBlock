package util.version
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;

	public class VerFile extends EventDispatcher
	{
		private var _file:File;
		public var bytes:ByteArray;
		public var path:String;
		private var _stream:FileStream = new FileStream();
		public function VerFile()
		{
		}
		public function save():void{
			_file = new File(path);
			_stream.openAsync(_file,FileMode.WRITE);
			_stream.addEventListener(Event.COMPLETE,onFileSaved);
			_stream.addEventListener(IOErrorEvent.IO_ERROR,onFileError);
			_stream.addEventListener(Event.CLOSE,onFileClosed);
			try{
				_stream.writeBytes(bytes,0,bytes.length);
				_stream.close();
			}catch(e:*){
				trace(e);
			}
		}private function onFileClosed(evt:Event):void{
			dispatchEvent(new Event(Event.COMPLETE));
		}
		private function onFileSaved(evt:Event):void{
			dispatchEvent(new Event(Event.COMPLETE));
			_stream.close();
		}
		private function onFileError(evt:IOErrorEvent):void{
			dispatchEvent(new Event(Event.CANCEL));
			_stream.close();
		}
	}
}