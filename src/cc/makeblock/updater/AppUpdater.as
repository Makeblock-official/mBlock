package cc.makeblock.updater
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.NativeProcessExitEvent;
	import flash.filesystem.File;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import cc.makeblock.mbot.util.PopupUtil;
	import cc.makeblock.util.FileUtil;
	
	import org.aswing.JOptionPane;

	public class AppUpdater extends EventDispatcher
	{
		static private var _instance:AppUpdater;
		static public function getInstance():AppUpdater
		{
			if(null == _instance){
				_instance = new AppUpdater();
			}
			return _instance;
		}
		
		static private const versionRegExp:RegExp = /v([\d.]+)\.zip/;
		static public const CONFIG_PATH:String = "http://mblock.cc/download/";
		
		private var ldr:URLLoader;
		private var frame:UpdateFrame;
		/*
		private var needUpdateApp:Boolean;
		private var needUpdateAsset:Boolean;
		private var assetPath:String;
		*/
		public function AppUpdater()
		{
			ldr = new URLLoader();
			ldr.addEventListener(Event.COMPLETE, __onLoad);
			ldr.addEventListener(IOErrorEvent.IO_ERROR, __onError);
		}
		
		private function __onError(evt:IOErrorEvent):void
		{
		}
		
		
		private function __onLoad(evt:Event):void
		{
			var str:String = ldr.data;
			var result:Array = versionRegExp.exec(str);
			if(null == result){
				return;
			}
			if(isSourceVerGreatThan(result[1], MBlock.versionString.slice(1))){
				PopupUtil.showConfirm("有新版本可以下载", __onConfirm);
			}
			/*
			parseData(JSON.parse(ldr.data));
			if(needUpdateApp){
				PopupUtil.showConfirm("有新版本可以下载", __onConfirm);
			}else if(needUpdateAsset){
				ldr.removeEventListener(Event.COMPLETE, __onLoad);
				ldr.removeEventListener(IOErrorEvent.IO_ERROR, __onError);
				ldr.addEventListener(Event.COMPLETE, __onAssetLoad);
				ldr.addEventListener(IOErrorEvent.IO_ERROR, __onAssetError);
				ldr.dataFormat = URLLoaderDataFormat.BINARY;
				ldr.load(new URLRequest(assetPath));
			}else{
				closeAndNotify();
			}
			*/
		}
		
		private function __onConfirm(value:int):void
		{
			if(value == JOptionPane.YES){
				navigateToURL(new URLRequest("http://mblock.cc/download/"));
			}
//			closeAndNotify();
		}
		
		public function start():void
		{
			ldr.load(new URLRequest(CONFIG_PATH));
		}
		/*
		private function closeAndNotify():void
		{
			if(frame != null){
				frame.hide();
				frame = null;
			}
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		private function parseData(info:Object):void
		{
			var localInfo:Object = JSON.parse(FileUtil.ReadString(getVersionFile()));
			
			needUpdateApp = isSourceVerGreatThan(info.appVersion, localInfo.appVersion);
			needUpdateAsset = isSourceVerGreatThan(info.assetVersion, localInfo.assetVersion);
			assetPath = info.assetPath;
		}
		
		private function __onAssetError(evt:IOErrorEvent):void
		{
			closeAndNotify();
		}
		
		private function __onAssetLoad(evt:Event):void
		{
			
		}
		
		private function getVersionFile():File
		{
			return File.documentsDirectory.resolvePath("mBlock/version.txt");
		}
		
		public function checkVersionFile(callback:Function):void
		{
			var file:File = getVersionFile();
			if(file.exists){
				callback();
				return;
			}
			runProcess(File.applicationDirectory.resolvePath("assets/version/data.zip"),function():void{
				var localFile:File = File.applicationDirectory.resolvePath("assets/version/version.txt");
				localFile.copyTo(file);
				callback();
			});
		}
		
		private function runProcess(zipFile:File, callback:Function):void
		{
			var process:NativeProcess = new NativeProcess();
			process.addEventListener(NativeProcessExitEvent.EXIT, function(evt:Event):void{
				process.removeEventListener(evt.type, arguments.callee);
				if(callback != null){
					callback();
				}
			});
			var startInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			startInfo.executable = File.applicationDirectory.resolvePath("assets/version/7z.exe");
			var wd:File = File.documentsDirectory.resolvePath("mBlock");
			if(!wd.exists){
				wd.createDirectory();
			}
			startInfo.workingDirectory = wd;
			startInfo.arguments = new <String>["x", "-y", zipFile.nativePath];
			process.start(startInfo);
		}
		*/
		static private function isSourceVerGreatThan(source:String, compareTarget:String):Boolean
		{
			return VerToInt(source) > VerToInt(compareTarget);
		}
		
		static private function VerToInt(str:String):uint
		{
			var list:Array = str.split(".");
			list.length = 3;
			var result:uint = 0;
			for each(var item:String in list){
				result *= 1000;
				result += parseInt(item);
			}
			return result;
		}
	}
}