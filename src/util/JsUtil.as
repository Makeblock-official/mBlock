package util
{
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import by.blooddy.crypto.Base64;
	
	import cc.makeblock.interpreter.RemoteCallMgr;

	public class JsUtil
	{
		Init();
		static private function Init():void
		{
			if(!ExternalInterface.available)
				return;
			ExternalInterface.marshallExceptions = true;
			ExternalInterface.addCallback("responseValue", __responseValue);
			ExternalInterface.addCallback("importProject", __importProject);
			ExternalInterface.addCallback("openProject", __openProject);
			ExternalInterface.addCallback("newProject", __newProject);
			ExternalInterface.addCallback("exportProject", __exportProject);
			ExternalInterface.addCallback("saveLocalCopy", __saveLocalCopy);
			ExternalInterface.addCallback("hasChanged", __hasChanged);
			ExternalInterface.addCallback("onReadyToRun", __onReadyToRun);
			ExternalInterface.addCallback("setRobotName", __setRobotName);
			ExternalInterface.addCallback("getRobotName", __getRobotName);
		}
		
		static public function Call(method:String, args:Array):*
		{
			if(ExternalInterface.available){
				args.unshift(method);
				return ExternalInterface.call.apply(null, args);
			}else{
				trace("ExternalInterface is not available!");
			}
		}
		/*
		static public function Eval(code:String):void
		{
			Call("eval", [code]);
		}
		*/
		static public function setProjectRobotName(name:String):void
		{
			Call("setProjectRobotName", [name]);
		}
		
		static public function readyToRun():Boolean
		{
			return Call("readyToRun", []);
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
		
		static private function __importProject(projectData:String):void
		{
			var fileData:ByteArray = Base64.decode(projectData);
			MBlock.app.runtime.installProjectFromData(fileData);
//			MBlock.app.runtime.selectProjectFile();
		}
		
		static private function __openProject(url:String):void
		{
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.addEventListener(Event.COMPLETE, function(evt:Event):void{
				MBlock.app.runtime.installProjectFromData(loader.data);
			});
			loader.load(new URLRequest(url));
		}
		
		static private function __newProject(projectName:String):void
		{
			trace("__newProject", projectName);
			MBlock.app.createNewProject();
		}
		
		static private function __exportProject(token:String):void
		{
			function squeakSoundsConverted(projIO:ProjectIO):void {
				var zipData:ByteArray = projIO.encodeProjectAsZipFile(MBlock.app.stagePane);
				var base64Str:String = Base64.encode(zipData);
				Call("exportProject", [token, base64Str]);
			}
			var projIO:ProjectIO = new ProjectIO(MBlock.app);
			projIO.convertSqueakSounds(MBlock.app.stagePane, squeakSoundsConverted);
			trace("__exportProject");
		}
		
		static private function __saveLocalCopy():void
		{
			trace("__saveLocalCopy");
//			MBlock.app.exportProjectToFile();
			function squeakSoundsConverted(projIO:ProjectIO):void {
				var zipData:ByteArray = projIO.encodeProjectAsZipFile(MBlock.app.stagePane);
				var base64Str:String = Base64.encode(zipData);
				Call("saveLocalCopy", [base64Str]);
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
		}
		
		static private function __setRobotName(value:String):void
		{
			trace("__setRobotName", value);
		}
		
		static private function __getRobotName():String
		{
			trace("__getRobotName");
			return "TestRobotName";
		}
	}
}