package cc.makeblock.menu
{
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;

	final public class MenuUtil
	{
		static public function ForEach(menu:NativeMenu, handler:Function):void
		{
			for(var i:int=0, n:int=menu.numItems; i<n; ++i){
				var menuItem:NativeMenuItem = menu.getItemAt(i);
				var skipFlag:Boolean = handler(menuItem);
				if(skipFlag){
					continue;
				}
				if(menuItem.submenu != null){
					ForEach(menuItem.submenu, handler);
				}
			}
		}
		
		static public function AddLine(menu:NativeMenu):void
		{
			menu.addItem(new NativeMenuItem(null, true));
		}
		
		static public function FindItem(menu:NativeMenu, name:String):NativeMenuItem
		{
			for(var i:int=0, n:int=menu.numItems; i<n; ++i){
				var menuItem:NativeMenuItem = menu.getItemAt(i);
				if(menuItem.name == name){
					return menuItem;
				}
				if(menuItem.submenu != null){
					menuItem = FindItem(menuItem.submenu, name);
					if(menuItem != null){
						return menuItem;
					}
				}
			}
			return null;
		}
		
		static public function FindParentItem(menuItem:NativeMenuItem):NativeMenuItem
		{
			var menu:NativeMenu = menuItem.menu.parent;
			if(null == menu){
				return null;
			}
			for(var i:int=0, n:int=menu.numItems; i<n; ++i){
				var testItem:NativeMenuItem = menu.getItemAt(i);
				if(testItem.submenu == menuItem.menu){
					return testItem;
				}
			}
			return null;
		}
	}
}