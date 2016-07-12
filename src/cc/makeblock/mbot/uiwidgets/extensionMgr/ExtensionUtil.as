package cc.makeblock.mbot.uiwidgets.extensionMgr
{
	import flash.filesystem.File;
	import flash.utils.ByteArray;
	
	import cc.makeblock.mbot.util.PathUtil;
	import cc.makeblock.mbot.util.PopupUtil;
	import cc.makeblock.mbot.util.StringUtil;
	import cc.makeblock.util.FileUtil;
	
	import deng.fzip.FZip;
	import deng.fzip.FZipFile;
	
	import org.aswing.JOptionPane;
	
	import translation.Translator;
	
	import uiwidgets.DialogBox;
	
	import util.ApplicationManager;
	import util.JSON;
	import util.SharedObjectManager;

	public class ExtensionUtil
	{
		static private var panel:ExtensionMgrFrame;
		
		static public function OnLoadExtension():void
		{
			MBlock.app.extensionManager.copyLocalFiles();
			MBlock.app.extensionManager.importExtension();
			var d:DialogBox = new DialogBox;
			function closeHandle():void{
				d.cancel();
			}
			d.addTitle(Translator.map('Extension Files Updated'));
			d.addButton('Close', closeHandle);
			d.showOnStage(MBlock.app.stage);
		}
		
		static public function OnManagerExtension():void
		{
			if(null == panel){
				panel = new ExtensionMgrFrame();
			}
			panel.show();
		}
		
		static public function OnAddExtension(file:File):void
		{
			if(file.extension == "json"){
				var fileName:String = file.name.slice(0, file.name.lastIndexOf("."));
				try{
					var json:Object = util.JSON.parse(FileUtil.ReadString(file));
					SharedObjectManager.sharedManager().setObject(json.extensionName+"_selected",true);
				}catch(e:Error){
					return;
				}
				file.copyTo(libPath.resolvePath(fileName + "/" + file.name), true);
				MBlock.app.extensionManager.importExtension();
				return;
			}
			
			var fileData:ByteArray = FileUtil.ReadBytes(file);
			
			var fzip:FZip = new FZip();
			try{
				fzip.loadBytes(fileData);
			}catch(e:Error){
				showErrorAlert();
				return;
			}
			onParseSuccess(fzip);
		}
		
		static public function OnDelExtension(extName:String, callback:Function):void
		{
			PopupUtil.showConfirm("Want to delete?", function(value:int):void{
				if(value != JOptionPane.YES){
					return;
				}
				if(delExt(extName)){
					MBlock.app.extensionManager.importExtension();
					callback();
				}
			});
		}
		
		static private function showErrorAlert():void
		{
			JOptionPane.showMessageDialog(Translator.map("Warning"), "file is not a valid extension zip!");
		}
		
		static private var extensionDir:String;
		static private var extensionName:String;
		
		private static function onParseSuccess(fzip:FZip):void
		{
			var file:FZipFile = get_s2e_file(fzip);
			extensionDir = PathUtil.GetDirName(file.filename);
			
			if(file != null && is_s2e_valid(fzip, file)){
				if(isExtNameExist(extensionName)){
					delExt(extensionName);
				}
				copyFileToDocuments(fzip);
				SharedObjectManager.sharedManager().setObject(extensionName+"_selected",true);
				MBlock.app.extensionManager.importExtension();
			}else{
				showErrorAlert();
			}
		}
		
		static private function get_s2e_file(fzip:FZip):FZipFile
		{
			var n:int = fzip.getFileCount();
			for (var i:int = 0; i < n; i++) 
			{
				var file:FZipFile = fzip.getFileAt(i);
				if(StringUtil.EndWith(file.filename, ".s2e")){
					return file;
				}
			}
			return null;
		}
		
		static private const s2eKeys:Array = [
			"extensionName",
//			"extensionPort",
			"sort",
//			"firmware",
			"javascriptURL",
			"blockSpecs"
		];
		
		static private function is_s2e_valid(fzip:FZip, file:FZipFile):Boolean
		{
			file.content.position = 0;
			var str:String = file.content.readUTFBytes(file.content.bytesAvailable);
			var json:Object;
			try{
				json = util.JSON.parse(str);
			}catch(e:Error){
				return false;
			}
			for each(var key:String in s2eKeys){
				if(!json.hasOwnProperty(key)){
					return false;
				}
			}
			extensionName = json.extensionName;
			var jsPath:String = json.javascriptURL;
			var jsFullPath:String = PathUtil.GetPath(file.filename, jsPath);
			return fzip.getFileByName(jsFullPath) != null;
		}
		
		static private function copyFileToDocuments(fzip:FZip):void
		{
			var dir:File = libPath;
			
			var n:int = fzip.getFileCount();
			for (var i:int = 0; i < n; i++) 
			{
				var file:FZipFile = fzip.getFileAt(i);
				if(StringUtil.EndWith(file.filename, "/")){
					continue;
				}
				var path:String = extensionName + "/" + file.filename.slice(extensionDir.length);
				FileUtil.WriteBytes(dir.resolvePath(path), file.content);
			}
		}
		
		static private function isExtNameExist(extName:String):Boolean
		{
			return MBlock.app.extensionManager.findExtensionByName(extName) != null;
		}
		
		static private function delExt(extName:String):Boolean
		{
			for each(var obj:Object in MBlock.app.extensionManager.extensionList)
			{
				if(obj.extensionName==extName)
				{
					var path:String = decodeURI(obj.srcPath);
					var _arr:Array = path.split("/");
					path = _arr[_arr.length-2];
					break;
				}
			}
			var file:File = libPath.resolvePath(path);
			if(file.exists){
				file.moveToTrash();
				return true;
			}
			return false;
		}
		
		static private function get libPath():File
		{
			return ApplicationManager.sharedManager().documents.resolvePath("mBlock/libraries");
		}
	}
}