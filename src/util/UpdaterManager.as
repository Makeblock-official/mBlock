package util
{
	import com.riaspace.nativeApplicationUpdater.NativeApplicationUpdater;
	
	import flash.events.ErrorEvent;
	import flash.events.ProgressEvent;
	import flash.utils.setTimeout;
	
	import air.update.events.DownloadErrorEvent;
	import air.update.events.StatusUpdateErrorEvent;
	import air.update.events.StatusUpdateEvent;
	import air.update.events.UpdateEvent;
	
	import translation.Translator;
	
	import uiwidgets.DialogBox;

	public class UpdaterManager
	{
		private var _appUpdater:NativeApplicationUpdater = new NativeApplicationUpdater();
		private var _download_dialog:DialogBox = new DialogBox;
		public function UpdaterManager():void{
			
		}
		private static var _instance:UpdaterManager;
		public static function sharedManager():UpdaterManager{
			if(_instance==null){
				_instance = new UpdaterManager;
			}
			return _instance;
		}
		public function checkForUpdate():void {  
			_appUpdater.updateURL = "http://makeblock.vipsinaapp.com/scratch/update_myh.xml?temp="+new Date().time; 
			_appUpdater.addEventListener(DownloadErrorEvent.DOWNLOAD_ERROR, onError);
			_appUpdater.addEventListener(ProgressEvent.PROGRESS,onProgress);
			_appUpdater.addEventListener(UpdateEvent.DOWNLOAD_START, onDownloadStart);
			_appUpdater.addEventListener(UpdateEvent.DOWNLOAD_COMPLETE, onDownloadComplete);
			_appUpdater.addEventListener(UpdateEvent.INITIALIZED,onUpdate);
			_appUpdater.addEventListener(ErrorEvent.ERROR,onError);
			_appUpdater.addEventListener(StatusUpdateErrorEvent.UPDATE_ERROR,onError);
			_appUpdater.addEventListener(StatusUpdateEvent.UPDATE_STATUS,onRefresh);
			_appUpdater.addEventListener(UpdateEvent.CHECK_FOR_UPDATE,onCheckForUpdate);
			setTimeout(_appUpdater.initialize,1000);
		}    
		private function onError(evt:*):void {  
			 trace(evt);
		} 
		private function onCheckForUpdate(evt:*):void {  
//			if(evt.available){
				//_appUpdater.downloadUpdate();
//			}
			
		}  
		private function onDownloadStart(evt:*):void {  
			trace("download start");
			_download_dialog = new DialogBox;
			_download_dialog.addTitle(Translator.map("Updating"));
			_download_dialog.showOnStage(MBlock.app.stage);
		}  
		private function onDownloadComplete(evt:*):void {  
			trace("download complete");
			
		}  
		private function onProgress(evt:ProgressEvent):void{
			trace("downloading:"+Math.floor(evt.bytesLoaded/evt.bytesTotal*100)+"%");
			_download_dialog.setText(Translator.map("Downloading")+":"+Math.floor(evt.bytesLoaded/evt.bytesTotal*100)+"%");
		}
		private function checkVersion(v1:String,v2:String):Boolean{
			var a1:Array = v1.split(".");
			var a2:Array = v2.split(".");
			var vv1:Number = 0;
			var vv2:Number = 0;
			for(var i:uint=0;i<a1.length;i++){
				vv1+=Number(a1[i])*Math.pow(100,(3-i))/100;
			}
			for(i=0;i<a1.length;i++){
				vv2+=Number(a2[i])*Math.pow(100,(3-i))/100;
			}
			if(vv2>vv1){
				return true;
			}
			return false;
		}
		private function onRefresh(evt:StatusUpdateEvent):void{
		
			if(_appUpdater.currentState=="AVAILABLE"){
				if(checkVersion(_appUpdater.currentVersion,_appUpdater.updateVersion)){
				
					function checkNow():void{
						_appUpdater.currentState="READY";
						_appUpdater.checkNow();
						_appUpdater.removeEventListener(StatusUpdateEvent.UPDATE_STATUS,onRefresh);
						_appUpdater.removeEventListener(UpdateEvent.CHECK_FOR_UPDATE,onCheckForUpdate);
					}
					function cancelNow():void{
						dialog.cancel();
					}
					var dialog:DialogBox = new DialogBox;
					dialog.addTitle(Translator.map("New Version Available!"));
					var list:XMLList = new XML(_appUpdater.updateDescription).children();
					
					for(var i:uint=0;i<list.length();i++){
						var xml:XML = list[i];
						if(xml.attributes().indexOf(SharedObjectManager.sharedManager().getObject("lang"))>-1){
							dialog.addText(xml);
							break;
						}
					}
					dialog.addButton(Translator.map("Update Now"),checkNow);
					dialog.addButton(Translator.map("Cancel"),cancelNow);
					dialog.showOnStage(MBlock.app.stage);
				}
			}
		}
		private function onBefore(evt:UpdateEvent):void {  
		}  
		private function onUpdate(evt:*):void {  
			if(_appUpdater.currentState=="READY"&&_appUpdater.updateVersion!=null){
				if(checkVersion(_appUpdater.currentVersion,_appUpdater.updateVersion)){
					function checkNow():void{
						_appUpdater.checkNow();
						_appUpdater.removeEventListener(StatusUpdateEvent.UPDATE_STATUS,onRefresh);
						_appUpdater.removeEventListener(UpdateEvent.CHECK_FOR_UPDATE,onCheckForUpdate);
					}
					function cancelNow():void{
						dialog.cancel();
					}
					var dialog:DialogBox = new DialogBox;
					dialog.addTitle(Translator.map("New Version Available!"));
					dialog.addButton(Translator.map("Update Now"),checkNow);
					dialog.addButton(Translator.map("Cancel"),cancelNow);
					dialog.showOnStage(MBlock.app.stage);
				}
			}else{
				_appUpdater.currentState = "BEFORE_CHECKING";
				_appUpdater.checkForUpdate();
			}
			//_appUpdater.checkNow(); // Go check for an update now  
		}   
	}
}