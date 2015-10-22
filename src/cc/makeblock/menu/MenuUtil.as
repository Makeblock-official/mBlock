package cc.makeblock.menu
{
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	
	import translation.Translator;

	final public class MenuUtil
	{
		static public function ChangeLang(menu:NativeMenu):void
		{
			ForEach(menu, ChangeLangImpl);
		}
		
		static private function ChangeLangImpl(item:NativeMenuItem):void
		{
			if(item.name && item.name.indexOf("@@") == 0){
				return;
			}
			item.label = Translator.map(item.name);
		}
		
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
		
		static public function AddItem(menu:NativeMenu, itemName:String):void
		{
			menu.addItem(new NativeMenuItem()).name = itemName;
		}
		
		static public function AddLine(menu:NativeMenu):void
		{
			if(menu.numItems <= 0){
				return;
			}
			menu.addItem(new NativeMenuItem(null, true));
		}
		
		static public function RemoveLastLines(menu:NativeMenu):void
		{
			while(menu.numItems > 0){
				var lastIndex:int = menu.numItems - 1;
				if(menu.getItemAt(lastIndex).isSeparator){
					menu.removeItemAt(lastIndex);
				}else{
					break;
				}
			}
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
		
		static public function setEnable(item:NativeMenuItem, value:Boolean):void
		{
			if(item.enabled != value){
				item.enabled = value;
			}
		}
		
		static public function setChecked(item:NativeMenuItem, value:Boolean):void
		{
			if(item.checked != value){
				item.checked = value;
			}
		}
	}
}