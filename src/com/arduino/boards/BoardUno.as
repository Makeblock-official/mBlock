package com.arduino.boards
{
	import flash.filesystem.File;
	import com.arduino.BoardInfo;

	public class BoardUno extends BoardInfo
	{
		public function BoardUno()
		{
			super("atmega328p", "arduino", 115200);
		}
		
		override public function getLibList(rootDir:File, result:Array):void
		{
			result.push(rootDir.resolvePath("hardware/arduino/avr/variants/standard"));
		}
		
		override public function getCompileArgList(result:Vector.<String>):void
		{
			result.push("-DARDUINO_AVR_UNO");
		}
	}
}