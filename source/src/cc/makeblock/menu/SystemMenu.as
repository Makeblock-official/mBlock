package cc.makeblock.menu
{
	import flash.desktop.NativeApplication;
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.display.NativeWindow;
	import flash.display.Stage;
	import flash.events.Event;
	
	import cc.makeblock.util.FileUtil;

	public class SystemMenu
	{
		private const handlerDict:Object = {};
		private var menu:NativeMenu;
		
		public function SystemMenu(stage:Stage, path:String)
		{
			var source:String = FileUtil.LoadFile(path);
			menu = MenuBuilder.BuildMenu(XML(source));
			if(NativeApplication.supportsMenu){
				NativeApplication.nativeApplication.menu = menu;
			}else if(NativeWindow.supportsMenu){
				stage.nativeWindow.menu = menu;
			}
			menu.addEventListener(Event.SELECT, __onSelect);
		}
		
		private function __onSelect(evt:Event):void
		{
			var menuItem:NativeMenuItem = evt.target as NativeMenuItem;
			
			var handler:Function = handlerDict[menuItem.name];
			if(null != handler){
				handler(menuItem);
				return;
			}
			
			var testItem:NativeMenuItem = menuItem;
			for(;;){
				testItem = MenuUtil.FindParentItem(testItem);
				if(null == testItem){
					return;
				}
				handler = handlerDict[testItem.name];
				if(null != handler){
					handler(menuItem);
					return;
				}
			}
		}
		
		public function getNativeMenu():NativeMenu
		{
			return menu;
		}
		
		public function register(menuName:String, handler:Function):void
		{
			handlerDict[menuName] = handler;
		}
	}
}