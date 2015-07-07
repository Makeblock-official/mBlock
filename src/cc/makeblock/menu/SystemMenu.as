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
				onAddAppMenu(menu);
			}else if(NativeWindow.supportsMenu){
				stage.nativeWindow.menu = menu;
			}
			menu.addEventListener(Event.SELECT, __onSelect);
		}
		
		protected function onAddAppMenu(menu:NativeMenu):void
		{
		}
		
		private function __onSelect(evt:Event):void
		{
			var menuItem:NativeMenuItem = evt.target as NativeMenuItem;
			
			var handler:Function = handlerDict[menuItem.name];
			if(null != handler){
				execHandler(handler, menuItem);
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
					execHandler(handler, menuItem);
					return;
				}
			}
		}
		
		private function execHandler(handler:Function, menuItem:NativeMenuItem):void
		{
			if(handler.length > 0){
				handler(menuItem);
			}else{
				handler();
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