package util.version
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.setTimeout;
	
	import extensions.DeviceManager;
	
	import util.SharedObjectManager;

	public class VersionManager 
	{
		private static var _instance:VersionManager;
		private var _reqLoader:URLLoader = new URLLoader();
		private var _list:Array = [];
		private var _requestIndex:uint = 0;
		private var _isFirst:Boolean;
		public function VersionManager()
		{
		}
		public static function sharedManager():VersionManager{
			if(_instance==null){
				_instance = new VersionManager;
			}
			return _instance;
		}
		public function start():void{
//			SharedObjectManager.sharedManager().clear();
			_isFirst = SharedObjectManager.sharedManager().getObject("first-launch",true);
			var req:URLRequest = new URLRequest("http://makeblock.sinaapp.com/scratch/mblock_resources_v3.php");
			_reqLoader.load(req);
			_reqLoader.addEventListener(IOErrorEvent.IO_ERROR,onReqError);
			_reqLoader.addEventListener(Event.COMPLETE,onReqComplete);
		}
		private function onReqComplete(evt:Event):void{
			var xml:XML = new XML(evt.target.data);
			_list = [];
			for(var i:uint = 0;i<xml[0].resource.length();i++){
				var res:VerResource = new VerResource();
				res.name = xml[0].resource[i].@name;
				res.path = xml[0].resource[i].@path;
				res.version = xml[0].resource[i].@version;
				res.url = xml[0].resource[i];
				res.addEventListener(Event.COMPLETE,onComplete);
				res.addEventListener("LOADED_ERROR",onError);
				_list.push(res);
			}
			trace("onReqComplete");
			startRequest();
		}
		private function onReqError(evt:Event):void{
			trace("req error!")
			if(_isFirst){
				MBlock.app.extensionManager.copyLocalFiles();
				SharedObjectManager.sharedManager().setObject("first-launch",false);
			}
			MBlock.app.extensionManager.clearImportedExtensions();
			MBlock.app.extensionManager.importExtension();
		}
		private function startRequest():void{
			if(_requestIndex<_list.length){
				var res:VerResource = _list[_requestIndex];
				res.load();
			}else{
				trace("finish");
				//MBlock.app.extensionManager.clearImportedExtensions();
				setTimeout(DeviceManager.sharedManager().onSelectBoard,1000,DeviceManager.sharedManager().currentBoard);
				MBlock.app.extensionManager.importExtension();
			}
		}
		private function onComplete(evt:Event):void{
			_requestIndex++;
			startRequest();
		}
		private function onError(evt:Event):void{
			_requestIndex++;
			startRequest();
		}
	}
}