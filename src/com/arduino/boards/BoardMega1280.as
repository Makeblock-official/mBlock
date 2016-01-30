package com.arduino.boards
{
	import flash.filesystem.File;
	import com.arduino.BoardInfo;

	public class BoardMega1280 extends BoardInfo
	{
		public function BoardMega1280()
		{
			super("atmega1280", "wiring", 57600);
		}
		
		override public function getLibList(rootDir:File, result:Array):void
		{
			result.push(rootDir.resolvePath("hardware/arduino/avr/variants/mega"));
		}
		
		override public function getCompileArgList(result:Vector.<String>):void
		{
			result.push("-DARDUINO_AVR_MEGA");
		}
	}
}