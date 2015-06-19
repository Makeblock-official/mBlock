package cc.makeblock.mbot.util
{
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.net.FileFilter;

	public class ExtensionUtil
	{
		static public function OnAddExtension():void
		{
			function onSelect(evt:Event):void
			{
				if(!CheckFormat(file)){
					trace("format error!");
					return;
				}
				ImportExtension(file);
			}
			
			var file:File = new File();
			file.addEventListener(Event.SELECT, onSelect);
			file.browseForOpen("please select file", [new FileFilter("zip file", "*.zip")]);
		}
		
		static public function OnRemoveExtension():void
		{
		}
		
		static private function CheckFormat(file:File):Boolean
		{
			return false;
		}
		
		static private function ImportExtension(file:File):void
		{
			
		}
		
		static private function RemoveExtension(file:File):void
		{
			
		}
	}
}