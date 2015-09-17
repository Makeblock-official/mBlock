package cc.makeblock.media
{
	import flash.events.Event;
	import flash.events.FileListEvent;
	import flash.filesystem.File;
	import flash.net.FileFilter;
	
	import cc.makeblock.mbot.util.PopupUtil;
	import cc.makeblock.util.FileUtil;
	
	import org.aswing.JOptionPane;
	
	import translation.Translator;
	
	import ui.media.MediaLibrary;
	
	import util.JSON;

	public class MediaManager
	{
		static public var _instance:MediaManager;
		
		static public function getInstance():MediaManager
		{
			if(null == _instance){
				_instance = new MediaManager();
			}
			return _instance;
		}
		
		private var isBackDrop:Boolean;
		
		public function MediaManager()
		{
		}
		
		public function importImage():void
		{
			var panel:JOptionPane = PopupUtil.showConfirm("Type", __onChooseType);
			panel.getYesButton().setText(Translator.map('Backdrop'));
			panel.getCancelButton().setText(Translator.map('Costume'));
		}
		
		private function __onChooseType(code:int):void
		{
			isBackDrop = (JOptionPane.YES == code);
			var file:File = new File();
			file.addEventListener(FileListEvent.SELECT_MULTIPLE, __onSelect);
			file.browseForOpenMultiple(Translator.map("Please choose images to import"), [new FileFilter("image", "*.png;*.jpg")]);
		}
		
		private function __onSelect(evt:FileListEvent):void
		{
			if(evt.files.length <= 0){
				return;
			}
			
			var mediaDir:File = File.applicationStorageDirectory.resolvePath("mBlock/media");
			var jsonPath:File = mediaDir.resolvePath("mediaLibrary.json");
			var s:String = FileUtil.ReadString(jsonPath);
			var libData:Array = util.JSON.parse(MediaLibrary.stripComments(s)) as Array;
			
			for each(var file:File in evt.files){
				file.copyTo(mediaDir.resolvePath(file.name));
				var info:Object = {};
				info.name = file.name.split(".")[0];
				info.md5 = file.name;
				info.type = isBackDrop ? "backdrop" : "costume";
				info.tags = ["favourite"];
				info.info = [];
				libData.push(info);
			}
			
			FileUtil.WriteString(jsonPath, util.JSON.stringify(libData));
		}
		
		public function exportImage():void
		{
			var file:File = new File();
			file.addEventListener(Event.SELECT, __onChooseDir);
			file.browseForDirectory(Translator.map("Please choose export directory"));
		}
		
		private function __onChooseDir(evt:Event):void
		{
			var exportFile:File = evt.target as File;
			
			var mediaDir:File = File.applicationStorageDirectory.resolvePath("mBlock/media");
			var jsonPath:File = mediaDir.resolvePath("mediaLibrary.json");
			var s:String = FileUtil.ReadString(jsonPath);
			var libData:Array = util.JSON.parse(MediaLibrary.stripComments(s)) as Array;
			
			for each(var info:Object in libData){
				if(info.tags[0] != "favourite"){
					continue;
				}
				var fileName:String = info.md5;
				mediaDir.resolvePath(fileName).copyToAsync(exportFile.resolvePath(fileName));
			}
		}
	}
}