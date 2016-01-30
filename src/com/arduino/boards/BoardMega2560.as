package com.arduino.boards
{
	import flash.filesystem.File;
	import com.arduino.BoardInfo;

	public class BoardMega2560 extends BoardInfo
	{
		public function BoardMega2560()
		{
			super("atmega2560", "wiring", 115200);
		}
		
		override public function getLibList(rootDir:File, result:Array):void
		{
			result.push(rootDir.resolvePath("hardware/arduino/avr/variants/mega"));
		}
		
		override public function getCompileArgList(result:Vector.<String>):void
		{
			result.push("-DARDUINO_AVR_MEGA2560");
		}
	}
}