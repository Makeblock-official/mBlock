package cc.makeblock.mbot.util
{
	import flash.display.NativeWindow;
	
	import translation.Translator;

	public class AppTitleMgr
	{
		static public const Instance:AppTitleMgr = new AppTitleMgr();
		
		private var window:NativeWindow;
		private var strList:Array;
		
		public function AppTitleMgr()
		{
		}
		
		public function init(window:NativeWindow):void
		{
			this.window = window;
			strList = [window.title];
			setConnectInfo(null);
		}
		
		public function setConnectInfo(info:String):void
		{
			if(Boolean(info)){
				strList[1] = info;
			}else{
				strList[1] = Translator.map("Unconnected");
			}
			updateTitle();
		}
		
		private function updateTitle():void
		{
			if(!window.closed)
			{
				window.title = strList.join(" - ");
			}
		}
	}
}