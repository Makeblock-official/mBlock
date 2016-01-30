package com.arduino
{
	import flash.filesystem.File;

	public class BoardInfo
	{
		public var partno:String;
		public var programmer:String;
		public var baudrate:int;
		
		public function BoardInfo(partno:String, programmer:String, baudrate:int)
		{
			this.partno = partno;
			this.programmer = programmer;
			this.baudrate = baudrate;
		}
		
		public function getLibList(rootDir:File, result:Array):void
		{
		}
		
		public function getCompileArgList(result:Vector.<String>):void
		{
		}
		
		public function prepareUpload(taskList:Array, port:String):String
		{
			return port;
		}
	}
}