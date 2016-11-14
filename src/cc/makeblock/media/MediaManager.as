package cc.makeblock.media
{
	import flash.events.Event;
	
	import cc.makeblock.mbot.util.PopupUtil;
	
	import org.aswing.JOptionPane;
	
	import translation.Translator;

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
			var panel:JOptionPane = PopupUtil.showQuitAlert( __onChooseType);
			panel.getFrame().setTitle("Type");
			panel.getYesButton().setText(Translator.map('Backdrop'));
			panel.getNoButton().setText(Translator.map('Costume'));
			panel.getCancelButton().setText(Translator.map("Cancel"));
		}
		
		private function __onChooseType(code:int):void
		{
			if(code==JOptionPane.CANCEL)
			{
				return;
			}
			isBackDrop = (JOptionPane.YES == code);
			/*
			var file:File = new File();
			file.addEventListener(FileListEvent.SELECT_MULTIPLE, __onSelect);
			file.browseForOpenMultiple(Translator.map("Please choose images to import"), [new FileFilter("image", "*.png;*.jpg")]);
			*/
			trace(this, "__onChooseType");
		}
		/*
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
				file.copyTo(mediaDir.resolvePath(file.name), true);
				var info:Object = {};
				info.name = file.name.split(".")[0];
				info.md5 = file.name;
				info.type = isBackDrop ? "backdrop" : "sprite";
				info.tags = ["favourite"];
				info.info = [];
				libData.push(info);
			}
			
			FileUtil.WriteString(jsonPath, util.JSON.stringify(libData));
			PopupUtil.showAlert("Import Success");
		}
		*/
		public function exportImage():void
		{
			/*
			var file:File = new File();
			file.addEventListener(Event.SELECT, __onChooseDir);
			file.browseForDirectory(Translator.map("Please choose export directory"));
			*/
			trace(this, "exportImage");
		}
		
		private function __onChooseDir(evt:Event):void
		{
			/*
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
			*/
			trace(this, "__onChooseDir");
		}
	}
}