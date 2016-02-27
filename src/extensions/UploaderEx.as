package extensions
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	
	import util.ApplicationManager;

	public class UploaderEx
	{
		static public const Instance:UploaderEx = new UploaderEx();
		
		static private function getArduino():File
		{
			if(ApplicationManager.sharedManager().system == ApplicationManager.MAC_OS){
				return File.applicationDirectory.resolvePath("Arduino/Arduino.app/Contents/MacOS/Arduino");
			}
			return File.applicationDirectory.resolvePath("Arduino/arduino_debug.exe");
		}
		
		public function UploaderEx()
		{
		}
		
		public function upload(filePath:String):void
		{
			var info:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			info.executable = getArduino();
			var argList:Vector.<String> = new Vector.<String>();
			argList.push("--upload");
			argList.push("--board", getBoardInfo());
			argList.push("--port", SerialDevice.sharedDevice().port);
			argList.push("--verbose", "--preserve-temp-files");
			argList.push(filePath);
			trace("compile",argList.join(" "));
			info.arguments = argList;
			var process:NativeProcess = new NativeProcess();
			process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, __onData);
			process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, __onErrorData);
			process.addEventListener(NativeProcessExitEvent.EXIT, __onExit);
			process.start(info);
		}
		
		private function getBoardInfo():String
		{
			var board:String = DeviceManager.sharedManager().currentBoard;
			if(board.indexOf("_uno") >= 0){
				return "arduino:avr:uno";
			}else if(board.indexOf("_leonardo") >= 0){
				return "arduino:avr:leonardo";
			}else if(board.indexOf("_mega2560") >= 0){
				return "arduino:avr:mega:cpu=atmega2560";
			}else if(board.indexOf("_mega1280") >= 0){
				return "arduino:avr:mega:cpu=atmega1280";
			}else if(board.indexOf("_nano328") >= 0){
				return "arduino:avr:nano:cpu=atmega328";
			}else if(board.indexOf("_nano168") >= 0){
				return "arduino:avr:nano:cpu=atmega168";
			}
			return "arduino:avr:uno";
		}
		
		private function __onExit(event:NativeProcessExitEvent):void
		{
			ArduinoManager.sharedManager().isUploading = false;
			MBlock.app.scriptsPart.appendMessage("exit code:" + event.exitCode);
		}
		
		private function __onData(event:ProgressEvent):void
		{
			var process:NativeProcess = event.target as NativeProcess;
			var info:String = process.standardOutput.readUTFBytes(process.standardOutput.bytesAvailable);
			MBlock.app.scriptsPart.appendRawMessage(info);
		}
		
		private function __onErrorData(event:ProgressEvent):void
		{
			var process:NativeProcess = event.target as NativeProcess;
			var info:String = process.standardError.readUTFBytes(process.standardError.bytesAvailable);
			MBlock.app.scriptsPart.appendRawMessage(info);
		}
	}
}