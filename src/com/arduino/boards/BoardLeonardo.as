package com.arduino.boards
{
	import flash.desktop.NativeProcessStartupInfo;
	import flash.filesystem.File;
	import com.arduino.BoardInfo;

	public class BoardLeonardo extends BoardInfo
	{
		public function BoardLeonardo()
		{
			super("atmega32u4", "avr109", 57600);
		}
		
		override public function getLibList(rootDir:File, result:Array):void
		{
			result.push(rootDir.resolvePath("hardware/arduino/avr/variants/leonardo"));
		}
		
		override public function getCompileArgList(result:Vector.<String>):void
		{
			result.push("-DARDUINO_AVR_LEONARDO");
			result.push("-DUSB_VID=0x2341");
			result.push("-DUSB_PID=0x8036");
			result.push('-DUSB_MANUFACTURER="Unknown"');
			result.push('-DUSB_PRODUCT="Arduino Leonardo"');
		}
		
		override public function prepareUpload(taskList:Array, port:String):String
		{
			var info:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			info.executable = new File("C:/Windows/System32/cmd.exe");
			info.arguments = new <String>["/c", "MODE " + port + ": BAUD=1200 PARITY=N DATA=8 STOP=1"];
			taskList.push(info);
			return port;
		}
	}
}