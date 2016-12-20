package util
{
	import flash.display.BitmapData;
	import flash.display.PNGEncoderOptions;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;
	
	import by.blooddy.crypto.Base64;
	
	import cc.makeblock.interpreter.BlockInterpreter;
	import cc.makeblock.interpreter.RemoteCallMgr;
	
	import extensions.DeviceManager;
	
	import translation.Translator;

	public class JsUtil
	{
		static private var _app:Object;
		static public function Init(stage:Stage):void
		{
//			stage.addEventListener(MouseEvent.CLICK, function(e){
//				__getStageSnapshot();
//			});
			var projectUrl:String = stage.loaderInfo.parameters["url"];
//			projectUrl = "__proj.sb2"
			MBlock.app.setEditMode(true);
			if(projectUrl != null){
				__openProject(projectUrl, function():void{
					MBlock.app.fixLayout();
					setTimeout(__showFullscreen, 0);
				});
			}else{
				MBlock.app.runtime.installNewProject();
				MBlock.app.fixLayout();
			}
			if(!ExternalInterface.available)
				return;
			try{
				ExternalInterface.marshallExceptions = true;
				ExternalInterface.addCallback("responseValue", __responseValue);
				ExternalInterface.addCallback("importProject", __importProject);
				ExternalInterface.addCallback("selectProjectFile",__selectProjectFile);
				ExternalInterface.addCallback("openProject", __openProject);
				ExternalInterface.addCallback("newProject", __newProject);
				ExternalInterface.addCallback("exportProject", __exportProject);
				ExternalInterface.addCallback("saveProject", __saveProject);
				ExternalInterface.addCallback("saveLocalCopy", __saveLocalCopy);
				ExternalInterface.addCallback("hasChanged", __hasChanged);
				ExternalInterface.addCallback("onReadyToRun", __onReadyToRun);
				ExternalInterface.addCallback("setRobotName", __setRobotName);
				ExternalInterface.addCallback("getRobotName", __getRobotName);
				ExternalInterface.addCallback("setUnmodified", __setUnmodified);
				ExternalInterface.addCallback("setProjectTitle", __setProjectTitle);
				ExternalInterface.addCallback("setLanguage", __setLanguage);
				ExternalInterface.addCallback("getStageSnapshot", __getStageSnapshot);
				ExternalInterface.addCallback("showFullscreen", __showFullscreen);
				ExternalInterface.addCallback("changeStageMode",__changeStageMode);
				ExternalInterface.addCallback("playCode", __playCode);
				ExternalInterface.addCallback("stopCode", __stopCode);
				callApp("readyForFlash");
			}catch(e:*){
				
			}
		}
		
		static public function Call(method:String, args:Array):*
		{
			if(ExternalInterface.available){
				args.unshift(method);
				ExternalInterface.call("_app.sendMsg",method);

				return ExternalInterface.call.apply(null, args);
			}else{
				trace("ExternalInterface is not available!");
			}
		}
		static public function callApp(method:String,args:Object=null):void{
			Call("_app."+method,[args]);
		}
		static public function callUtils(method:String,args:Object=null):void{
			Call("_utils."+method,[args]);
		}
		static public function callExtension(method:String,args:Object=null):void{
			Call("_ext."+method,[args]);
		}
		/*
		static public function Eval(code:String):void
		{
			Call("eval", [code]);
		}
		*/
		static public function setProjectRobotName(name:String):void
		{
			callApp("setProjectRobotName", [name]);
		}
		static public function readyToRun():Boolean
		{
			return callApp("readyToRun", []);
		}
		static public function boardConnected():Boolean
		{
			return callApp("boardConnected",[]);
		}
		static private function __responseValue(...args):void
		{
			if(args.length < 2){
				RemoteCallMgr.Instance.onPacketRecv();
				return;
			}
			switch(args[0]){
				case 0x80:
					MBlock.app.runtime.mbotButtonPressed.notify(Boolean(args[1]));
					break;
				default:
					RemoteCallMgr.Instance.onPacketRecv(args[1]);
			}
		}
		
		static private function __changeStageMode(name:String=""):void{
			switch(name.toLocaleLowerCase()){
				case "undelete":
					MBlock.app.runtime.undelete();
					break;
				case "hide stage layout":
					MBlock.app.toggleHideStage();
					break;
				case "small stage layout":
					MBlock.app.toggleSmallStage();
					break;
				case "turbo mode":
					MBlock.app.toggleTurboMode();
					break;
				case "arduino mode":
					MBlock.app.changeToArduinoMode();
					break;
			}
			MBlock.app.track("/OpenEdit");
		}
		static private function __selectProjectFile():void{
			MBlock.app.runtime.selectProjectFile();
		}
		static private function __importProject(projectData:String):void
		{
			var fileData:ByteArray = Base64.decode(projectData);
			MBlock.app.runtime.installProjectFromData(fileData);
//			MBlock.app.runtime.selectProjectFile();
		}
		static private function __openProject(url:String,callback:Function=null):void
		{
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.addEventListener(Event.COMPLETE, function(evt:Event):void{
				MBlock.app.runtime.installProjectFromData(loader.data, true,callback);
				callApp("openSuccess",[]);
				//回调成功消息
			});
			loader.addEventListener(IOErrorEvent.IO_ERROR, function(evt:IOErrorEvent):void{
				trace(evt);
			});
			loader.load(new URLRequest(url));
		}
		
		static private function __newProject(projectName:String=null):void
		{
//			DeviceManager.sharedManager().board = "mbot_uno";
//			trace("__newProject", projectName);
			MBlock.app.createNewProject();
		}
		
		static private function __exportProject(token:String):void
		{
			function squeakSoundsConverted(projIO:ProjectIO):void {
				var zipData:ByteArray = projIO.encodeProjectAsZipFile(MBlock.app.stagePane);
				var base64Str:String = Base64.encode(zipData);
				callApp("exportProject", [token, base64Str]);
			}
			var projIO:ProjectIO = new ProjectIO(MBlock.app);
			projIO.convertSqueakSounds(MBlock.app.stagePane, squeakSoundsConverted);
			trace("__exportProject");
		}
		
		static private function __saveLocalCopy(key:Object):void
		{
			trace("__saveLocalCopy");
//			MBlock.app.exportProjectToFile();
			function squeakSoundsConverted(projIO:ProjectIO):void {
				var zipData:ByteArray = projIO.encodeProjectAsZipFile(MBlock.app.stagePane);
				var base64Str:String = Base64.encode(zipData);
				callApp("saveLocalCopy", [key, base64Str]);
			}
			var projIO:ProjectIO = new ProjectIO(MBlock.app);
			projIO.convertSqueakSounds(MBlock.app.stagePane, squeakSoundsConverted);
		}
		
		static private function __saveProject():void
		{
			function squeakSoundsConverted(projIO:ProjectIO):void {
				var zipData:ByteArray = projIO.encodeProjectAsZipFile(MBlock.app.stagePane);
				var base64Str:String = Base64.encode(zipData);
				//Call("saveProject", [base64Str]);
				callApp("saveProject",{title: MBlock.app.projectName() + '.sb2', data:base64Str});
			}
			var projIO:ProjectIO = new ProjectIO(MBlock.app);
			projIO.convertSqueakSounds(MBlock.app.stagePane, squeakSoundsConverted);
		}
		static private function __hasChanged():Boolean
		{
			trace("__hasChanged");
			return MBlock.app.saveNeeded;
		}
		
		static private function __onReadyToRun():void
		{
			trace("__onReadyToRun");
			BlockInterpreter.Instance.onReadyToRun();
		}
		
		static private function __setRobotName(value:String):void
		{
			switch(value.toLowerCase()){
				case "mbot":
					DeviceManager.sharedManager().onSelectBoard("mbot_uno");
					break;
				case "mbot ranger":
					DeviceManager.sharedManager().onSelectBoard("me/auriga");
					break;
			}
		}
		
		static private function __getRobotName():String
		{
			switch(DeviceManager.sharedManager().currentName){
				case "mBot":
					return "mBot";
				case "Me Auriga":
					return "mBot Ranger";
			}
			return "";
		}
		
		static private function __setUnmodified():void
		{
			MBlock.app.saveNeeded = false;
		}
		
		static private function __setProjectTitle(title:String):void
		{
			MBlock.app.setProjectName(title);
		}
		static private function __setLanguage(lang:String,dict:Object):void{
			Translator.setDictionary(lang,dict);
		}
		static private function __getStageSnapshot():String
		{
			var view:Sprite = MBlock.app.stagePart;
			var bmd:BitmapData = new BitmapData(
				view.width-4, view.height-20,false
			);
			bmd.draw(view, null, null, null, null, false);
			var jpeg:ByteArray = bmd.encode(bmd.rect, new PNGEncoderOptions());
			var result:String = Base64.encode(jpeg);
			bmd.dispose();
			jpeg.clear();
			return result;
		}
		
		static private function __showFullscreen():void
		{
			MBlock.app.setPresentationMode(true, false);
			MBlock.app.stagePart.switchPresentationMode(true);
			MBlock.app.stagePart.hideTopBar();
		}
		
		static private function __playCode():void
		{
			MBlock.app.runtime.startGreenFlags();
		}
		
		static private function __stopCode():void
		{
			MBlock.app.runtime.stopAll();
		}
	}
}