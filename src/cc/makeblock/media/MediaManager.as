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
			var panelArr:Array=[]
			for each(var info:Object in libData){
				if(info.tags[0] != "favourite"){
					continue;
				}
				var fileName:String = info.md5;
				if(exportFile.resolvePath(fileName).exists)
				{
					var tmpFileName:String = fileName.length<15?fileName:fileName.substr(0,15)+"…";
					
					var panel:JOptionPane = PopupUtil.showConfirm(Translator.map('File')+' "'+tmpFileName+'" '+Translator.map('already exists, overwrite?'),function(value:int):void{
						if(value==JOptionPane.YES)
						{
							mediaDir.resolvePath(fileName).copyToAsync(exportFile.resolvePath(fileName),true);
						}
						else
						{
							if(panelArr.length>0)
							{
								panelArr.shift().getFrame().visible = true;
							}
						}
					});
					panel.getFrame().setWidth(400);
					panel.getFrame().visible = false;
					panelArr.push(panel);
				}
				else
				{
					mediaDir.resolvePath(fileName).copyToAsync(exportFile.resolvePath(fileName));
				}
				
			}
			panelArr.shift().getFrame().visible = true;
		}
	}
}