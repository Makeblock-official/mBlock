package cc.makeblock.updater
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import cc.makeblock.mbot.util.PopupUtil;
	
	import org.aswing.BorderLayout;
	import org.aswing.Insets;
	import org.aswing.JCheckBox;
	import org.aswing.JOptionPane;
	import org.aswing.border.EmptyBorder;
	
	import translation.Translator;
	
	import util.SharedObjectManager;
	import util.version.VersionManager;

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
//		private var frame:UpdateFrame;
		private var needNotice:Boolean;
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
			UpdateFrame.getInstance().hide();
		}
		
		
		private function __onLoad(evt:Event):void
		{
			UpdateFrame.getInstance().hide();
			var str:String = ldr.data;
			var result:Array = versionRegExp.exec(str);
			if(null == result){
				return;
			}
			var panel:JOptionPane;
			if(isSourceVerGreatThan(result[1], MBlock.versionString.slice(1)) && (needNotice || SharedObjectManager.sharedManager().getObject(_key, true))){
				panel = PopupUtil.showConfirm(Translator.map("There is a newer version"), __onConfirm);
				panel.getYesButton().setText(Translator.map("Download Now"));
				panel.getCancelButton().setText(Translator.map("Download Later"));
				panel.getFrame().setModal(false);
				_checkBox = new JCheckBox(Translator.map("Dont't show next time"));
				_checkBox.setBorder(new EmptyBorder(null, new Insets(10, 0, 0, 0)));
				panel.append(_checkBox, BorderLayout.CENTER);
				panel.getFrame().setSizeWH(240, 100);
			}else{
				VersionManager.sharedManager().start();
				if(needNotice){
					PopupUtil.showAlert(Translator.map("It's already the latest version"));
				}
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
		
		private var _checkBox:JCheckBox;
		private var _key:String = "show app update panel";
		
		private function __onConfirm(value:int):void
		{
			SharedObjectManager.sharedManager().setObject(_key, !_checkBox.isSelected());
			if(value == JOptionPane.YES){
				navigateToURL(new URLRequest("http://mblock.cc/download/"));
			}
			_checkBox = null;
//			closeAndNotify();
		}
		
		public function start(needNotice:Boolean=false):void
		{
			this.needNotice = needNotice;
			ldr.load(new URLRequest(CONFIG_PATH));
			if(needNotice){
				UpdateFrame.getInstance().show();
			}
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
		static public function isSourceVerGreatThan(source:String, compareTarget:String):Boolean
		{
			return VerToInt(source) > VerToInt(compareTarget);
		}
		
		static public function VerToInt(str:String):uint
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
		
		static public function VersionXml2Obj(xml:XML):Object
		{
			var result:Object = {};
			var resList:XMLList = xml.resource;
			for(var i:int=0, n:int=resList.length(); i<n; i++){
				var resXml:XML = resList[i];
				var key:String = resXml.@name;
				var value:String = resXml.@version;
				result[key] = value;
			}
			return result;
		}
	}
}