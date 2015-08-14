package util.version
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.setTimeout;
	
	import cc.makeblock.updater.AppUpdater;
	import cc.makeblock.util.FileUtil;
	
	import extensions.DeviceManager;
	
	import util.LogManager;
	import util.SharedObjectManager;

	public class VersionManager 
	{
		private static var _instance:VersionManager;
		private var _reqLoader:URLLoader = new URLLoader();
		private var _list:Array = [];
		private var _requestIndex:uint = 0;
		private var _isFirst:Boolean;
		
		static public const resource_version_file_name:String = "resource_version.xml";
		
		private var localVersionInfo:Object;
		private var remoteVersionXml:String;
		private var localVersionFile:File;
		
		public function VersionManager()
		{
			localVersionFile = File.applicationStorageDirectory.resolvePath("mBlock");
			if(!localVersionFile.exists){
				localVersionFile.createDirectory();
			}
			localVersionFile = localVersionFile.resolvePath(resource_version_file_name);
			if(!localVersionFile.exists){
				var sourceFile:File = File.applicationDirectory.resolvePath("assets/"+resource_version_file_name);
				sourceFile.copyTo(localVersionFile);
			}
			localVersionInfo = AppUpdater.VersionXml2Obj(XML(FileUtil.ReadString(localVersionFile)));
		}
		
		public static function sharedManager():VersionManager{
			if(_instance==null){
				_instance = new VersionManager;
			}
			return _instance;
		}
		public function start():void{
			_isFirst = SharedObjectManager.sharedManager().getObject("first-launch",true);
			var req:URLRequest = new URLRequest("http://makeblock.sinaapp.com/scratch/mblock_resources_v5.php?time="+new Date().time);
			_reqLoader.load(req);
			_reqLoader.addEventListener(IOErrorEvent.IO_ERROR,onReqError);
			_reqLoader.addEventListener(Event.COMPLETE,onReqComplete);
		}
		private function onReqComplete(evt:Event):void{
			remoteVersionXml = evt.target.data;
			var xml:XML = XML(remoteVersionXml);
			var remoteVersionInfo:Object = AppUpdater.VersionXml2Obj(xml);
			var resList:XMLList = xml.resource;
			_list = [];
			for(var i:int = 0, n:int=resList.length();i<n;i++){
				var resXml:XML = resList[i];
				var res:VerResource = new VerResource();
				res.name = resXml.@name;
				res.path = resXml.@path;
				res.version = resXml.@version;
				res.url = resXml.text();
				
				if(!AppUpdater.isSourceVerGreatThan(remoteVersionInfo[res.name], localVersionInfo[res.name])){
					continue;
				}
				res.addEventListener(Event.COMPLETE,onComplete);
				res.addEventListener("LOADED_ERROR",onError);
				_list.push(res);
			}
			if(_list.length > 0){
				LogManager.sharedManager().log("onReqComplete");
				startRequest();
			}
		}
		private function onReqError(evt:Event):void{
			LogManager.sharedManager().log("req error!");
			if(_isFirst){
				MBlock.app.extensionManager.copyLocalFiles();
				SharedObjectManager.sharedManager().setObject("first-launch",false);
			}
			setTimeout(DeviceManager.sharedManager().onSelectBoard,1000,DeviceManager.sharedManager().currentBoard);
			MBlock.app.extensionManager.clearImportedExtensions();
			MBlock.app.extensionManager.importExtension();
		}
		private function startRequest():void{
			if(_requestIndex<_list.length){
				var res:VerResource = _list[_requestIndex];
				res.load();
			}else{
				FileUtil.WriteString(localVersionFile, remoteVersionXml);
				LogManager.sharedManager().log("finish");
//				PopupUtil.showAlert("Update Complete");
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