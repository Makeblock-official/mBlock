package extensions
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	
	import translation.Translator;
	
	import uiwidgets.DialogBox;
	
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
		
		private var _dialog:DialogBox = new DialogBox();
		
		public function UploaderEx()
		{
			_dialog.addTitle(Translator.map('Start Uploading'));
			_dialog.addButton(Translator.map('Close'), _dialog.cancel);
		}
		private function updateDialog():void
		{
			_dialog.setTitle(('Start Uploading'));
			_dialog.setButton(('Close'));
			_dialog.fixLayout();
		}
		public function upload(filePath:String):void
		{
			_dialog.setText(Translator.map('Uploading'));
			_dialog.showOnStage(MBlock.app.stage);
			updateDialog();
			var info:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			info.executable = getArduino();
			var argList:Vector.<String> = new Vector.<String>();
			argList.push("--upload");
			argList.push("--board", getBoardInfo());
			argList.push("--port", SerialDevice.sharedDevice().port);
			argList.push("--verbose", "--preserve-temp-files");
			argList.push(filePath);
			
			MBlock.app.scriptsPart.appendMessage(getArduino().nativePath + " " + argList.join(" "));
			
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
			if(event.exitCode == 0){
				_dialog.setText(Translator.map('Upload Finish'));
			}else{
				_dialog.setText(Translator.map('Upload Failed'));
			}
			SerialManager.sharedManager().reopen();
		}
		
		private function __onData(event:ProgressEvent):void
		{
			var process:NativeProcess = event.target as NativeProcess;
			var info:String = process.standardOutput.readMultiByte(process.standardOutput.bytesAvailable, "gb2312");
			MBlock.app.scriptsPart.appendRawMessage(info);
		}
		
		private function __onErrorData(event:ProgressEvent):void
		{
			var process:NativeProcess = event.target as NativeProcess;
			var info:String = process.standardError.readMultiByte(process.standardError.bytesAvailable, "gb2312");
			MBlock.app.scriptsPart.appendRawMessage(info);
		}
	}
}