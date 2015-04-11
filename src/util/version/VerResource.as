package util.version
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.filesystem.File;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import deng.fzip.FZip;
	import deng.fzip.FZipErrorEvent;
	import deng.fzip.FZipEvent;
	import deng.fzip.FZipFile;
	
	import util.ApplicationManager;
	import util.SharedObjectManager;

	public class VerResource extends EventDispatcher
	{
		public var name:String = "";
		public var path:String = "";
		public var url:String = "";
		public var version:String = "";
		
		private var _request:URLRequest;
		private var _loader:URLLoader;
		private var _list:Array = [];
		private var _saveIndex:uint = 0;
		public function VerResource():void
		{
		}
		public function load():void{
			if(url==""||SharedObjectManager.sharedManager().getObject(path+"/"+name)==version){
//				trace(path+"/"+name+" exist");
				this.dispatchEvent(new Event(Event.COMPLETE));
			}else{
				_request = new URLRequest(url);
				
				var zipProcess:FZip = new FZip();
				zipProcess.load(_request);
				zipProcess.addEventListener(FZipEvent.FILE_LOADED,onFileLoaded);
				zipProcess.addEventListener(Event.COMPLETE,onFileComplete);
				zipProcess.addEventListener(FZipErrorEvent.PARSE_ERROR,onFileError);
			}
		}
		private function onFileLoaded(evt:FZipEvent):void{
		}
		private function onFileComplete(evt:Event):void{
			_list = [];
			var zipProcess:FZip = evt.target as FZip;
			var documentPath:String = ApplicationManager.sharedManager().documents.nativePath+"/mBlock/"+path+"/";
			
			for(var i:uint = 0;i<zipProcess.getFileCount();i++){
				var file:FZipFile = zipProcess.getFileAt(i);
				if(file.sizeUncompressed>0){
					var verFile:VerFile = new VerFile;
					verFile.bytes = file.content;
					verFile.path = (documentPath+file.filename);//.split("\\").join("/");
					verFile.addEventListener(Event.COMPLETE,onSaveComplete);
					verFile.addEventListener(Event.CANCEL,onSaveError);
					_list.push(verFile);
				}
			}
			startSave();
		}
		private function startSave():void{
			if(_saveIndex<_list.length){
				var verFile:VerFile = _list[_saveIndex] as VerFile;
				verFile.save();
			}else{
				SharedObjectManager.sharedManager().setObject(path+"/"+name,version);
				this.dispatchEvent(new Event(Event.COMPLETE));
			}
		}
		private function onSaveComplete(evt:Event):void{
			_saveIndex++;
			startSave();
		}
		private function onSaveError(evt:Event):void{
			this.dispatchEvent(new Event("LOADED_ERROR"));
		}
		private function onFileError(evt:FZipErrorEvent):void{
			this.dispatchEvent(new Event("LOADED_ERROR"));
		}
		private function onError(evt:IOErrorEvent):void{
			this.dispatchEvent(new Event("LOADED_ERROR"));
		}
	}
}