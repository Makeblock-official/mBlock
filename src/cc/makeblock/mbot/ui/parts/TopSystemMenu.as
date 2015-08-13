package cc.makeblock.mbot.ui.parts
{
	import flash.desktop.NativeApplication;
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import air.update.ApplicationUpdater;
	
	import cc.makeblock.mbot.uiwidgets.extensionMgr.ExtensionUtil;
	import cc.makeblock.menu.MenuUtil;
	import cc.makeblock.menu.SystemMenu;
	import cc.makeblock.updater.AppUpdater;
	
	import extensions.BluetoothManager;
	import extensions.ConnectionManager;
	import extensions.DeviceManager;
	import extensions.HIDManager;
	import extensions.SerialDevice;
	import extensions.SerialManager;
	import extensions.SocketManager;
	
	import translation.Translator;
	
	import util.ApplicationManager;
	import util.SharedObjectManager;
	import util.version.VersionManager;
	
	public class TopSystemMenu extends SystemMenu
	{
		public function TopSystemMenu(stage:Stage, path:String)
		{
			super(stage, path);
			
			if(!ApplicationManager.sharedManager().isCatVersion){
				var helpMenu:NativeMenu = getNativeMenu().getItemByName("Help").submenu;
				helpMenu.removeItemAt(2);
				helpMenu.removeItemAt(1);
				helpMenu.removeItemAt(0);
			}
			
			getNativeMenu().getItemByName("File").submenu.addEventListener(Event.DISPLAYING, __onInitFielMenu);
			getNativeMenu().getItemByName("Edit").submenu.addEventListener(Event.DISPLAYING, __onInitEditMenu);
			getNativeMenu().getItemByName("Extensions").submenu.addEventListener(Event.DISPLAYING, __onInitExtMenu);
			getNativeMenu().getItemByName("Boards").submenu.addEventListener(Event.DISPLAYING, __onShowBoards);
			getNativeMenu().getItemByName("Connect").submenu.addEventListener(Event.DISPLAYING, __onShowConnect);
			getNativeMenu().getItemByName("Language").submenu.addEventListener(Event.DISPLAYING, __onShowLanguage);
			
			register("File", __onFile);
			register("Edit", __onEdit);
			register("Connect", __onConnect);
			register("Boards", __onSelectBoard);
			register("Help", __onHelp);
			register("Manage Extensions", ExtensionUtil.OnManagerExtension);
			register("Restore Extensions", ExtensionUtil.OnLoadExtension);
		}
		
		public function changeLang():void
		{
			MenuUtil.ForEach(getNativeMenu(), changeLangImpl);
		}
		
		private function changeLangImpl(item:NativeMenuItem):*
		{
			var index:int = getNativeMenu().getItemIndex(item);
			if(0 <= index && index < defaultMenuCount){
				return true;
			}
			setItemLabel(item);
			if(item.name == "Boards"){
				return true;
			}
			if(item.name == "Language"){
				item = MenuUtil.FindItem(item.submenu, "set font size");
				setItemLabel(item);
				return true;
			}
		}
		
		private function setItemLabel(item:NativeMenuItem):void
		{
			var newLabel:String = Translator.map(item.name);
			if(item.label != newLabel){
				item.label = newLabel;
			}
		}
		
		private function __onFile(item:NativeMenuItem):void
		{
			switch(item.name)
			{
				case "New":
					MBlock.app.createNewProject();
					break;
				case "Load Project":
					MBlock.app.runtime.selectProjectFile();
					break;
				case "Save Project":
					MBlock.app.saveFile();
					break;
				case "Save Project As":
					MBlock.app.exportProjectToFile();
					break;
				case "Undo Revert":
					MBlock.app.undoRevert();
					break;
				case "Revert":
					MBlock.app.revertToOriginalProject();
					break;
			}
		}
		
		private function __onEdit(item:NativeMenuItem):void
		{
			switch(item.name){
				case "Undelete":
					MBlock.app.runtime.undelete();
					break;
				case "Hide stage layout":
					MBlock.app.toggleHideStage();
					break;
				case "Small stage layout":
					MBlock.app.toggleSmallStage();
					break;
				case "Turbo mode":
					MBlock.app.toggleTurboMode();
					break;
				case "Arduino mode":
					MBlock.app.changeToArduinoMode();
					break;
			}
			MBlock.app.track("/OpenEdit");
		}
		
		private function __onConnect(menuItem:NativeMenuItem):void
		{
			var key:String;
			if(menuItem.data){
				key = menuItem.data.@action;
			}else{
				key = menuItem.name;
			}
			ConnectionManager.sharedManager().onConnect(key);
		}
		
		private function __onShowLanguage(evt:Event):void
		{
			var languageMenu:NativeMenu = evt.target as NativeMenu;
			if(languageMenu.numItems <= 2){
				for each (var entry:Array in Translator.languages) {
					var item:NativeMenuItem = languageMenu.addItemAt(new NativeMenuItem(entry[1]), languageMenu.numItems-2);
					item.name = entry[0];
					item.checked = Translator.currentLang==entry[0];
				}
				languageMenu.addEventListener(Event.SELECT, __onLanguageSelect);
			}else{
				for each(item in languageMenu.items){
					if(item.isSeparator){
						break;
					}
					item.checked = Translator.currentLang==item.name;
				}
			}
			try{
				var fontItem:NativeMenuItem = languageMenu.items[languageMenu.numItems-1];
				for each(item in fontItem.submenu.items){
					item.checked = Translator.currentFontSize==Number(item.label);
				}
			}catch(e:Error){
				
			}
		}
		
		private function __onLanguageSelect(evt:Event):void
		{
			var item:NativeMenuItem = evt.target as NativeMenuItem;
			if(item.name == "setFontSize"){
				Translator.setFontSize(int(item.label));
			}else{
				Translator.setLanguage(item.name);
			}
		}
		
		private function __onInitFielMenu(evt:Event):void
		{
			var menu:NativeMenu = evt.target as NativeMenu;
			
			menu.getItemByName("Undo Revert").enabled = MBlock.app.canUndoRevert();
			menu.getItemByName("Revert").enabled = MBlock.app.canRevert();
			
			MBlock.app.track("/OpenFile");
		}
		
		private function __onInitEditMenu(evt:Event):void
		{
			var menu:NativeMenu = evt.target as NativeMenu;
			menu.getItemByName("Undelete").enabled = MBlock.app.runtime.canUndelete();
			menu.getItemByName("Hide stage layout").checked = MBlock.app.stageIsHided;
			menu.getItemByName("Small stage layout").checked = !MBlock.app.stageIsHided && MBlock.app.stageIsContracted;
			menu.getItemByName("Turbo mode").checked = MBlock.app.interp.turboMode;
			menu.getItemByName("Arduino mode").checked = MBlock.app.stageIsArduino;
			MBlock.app.track("/OpenEdit");
		}
		
		private function __onShowConnect(evt:Event):void
		{
			SocketManager.sharedManager().probe();
			HIDManager.sharedManager();
			
			var menu:NativeMenu = evt.target as NativeMenu;
			var subMenu:NativeMenu = new NativeMenu();
			
			var enabled:Boolean = MBlock.app.extensionManager.checkExtensionEnabled();
			var arr:Array = SerialManager.sharedManager().list;
			for(var i:int=0;i<arr.length;i++){
				var item:NativeMenuItem = subMenu.addItem(new NativeMenuItem(arr[i]));
				item.name = "serial_"+arr[i];
				item.enabled = enabled;
				item.checked = SerialDevice.sharedDevice().ports.indexOf(arr[i])>-1 && SerialManager.sharedManager().isConnected;
			}
			menu.getItemByName("Serial Port").submenu = subMenu;
			
			var bluetoothItem:NativeMenuItem = menu.getItemByName("Bluetooth");
			
			bluetoothItem.enabled = ApplicationManager.sharedManager().system == ApplicationManager.WINDOWS && BluetoothManager.sharedManager().isSupported
			while(bluetoothItem.submenu.numItems > 3){
				bluetoothItem.submenu.removeItemAt(3);
			}
			if(bluetoothItem.submenu.numItems>2){
				bluetoothItem.submenu.items[0].enabled = enabled;
				bluetoothItem.submenu.items[1].enabled = enabled;
				bluetoothItem.submenu.items[2].enabled = enabled;
			}
			arr = BluetoothManager.sharedManager().history;
			for(i=0;i<arr.length;i++){
				item = bluetoothItem.submenu.addItem(new NativeMenuItem(Translator.map(arr[i])));
				item.name = "bt_"+arr[i];
				item.enabled = enabled;
				item.checked = arr[i]==BluetoothManager.sharedManager().currentBluetooth && BluetoothManager.sharedManager().isConnected;
			}
			
			var tempItem:NativeMenuItem = menu.getItemByName("2.4G Serial").submenu.getItemAt(0);
			tempItem.enabled = enabled;
			tempItem.checked = HIDManager.sharedManager().isConnected;
			
			var netWorkMenuItem:NativeMenuItem = MenuUtil.FindItem(getNativeMenu(), "Network");
			subMenu = netWorkMenuItem.submenu;
			arr = SocketManager.sharedManager().list;
			while(subMenu.numItems > 1){
				subMenu.removeItemAt(1);
			}
			for(i=0;i<arr.length;i++){
				var ips:Array = arr[i].split(":");
				if(ips.length<3){
					continue;
				}
				var label:String = Translator.map(ips[0]+" - "+ips[2]);
				item = subMenu.addItem(new NativeMenuItem(label));
				item.name = "net_" + arr[i];
				item.enabled = enabled;
				item.checked = SocketManager.sharedManager().connected(ips[0]);
			}
			netWorkMenuItem.submenu = subMenu;
			var canReset:Boolean = SerialManager.sharedManager().isConnected && DeviceManager.sharedManager().currentName=="mBot";
			MenuUtil.FindItem(getNativeMenu(), "Reset Default Program").enabled = canReset;
			canReset = SerialManager.sharedManager().isConnected && DeviceManager.sharedManager().currentName!="PicoBoard";
			MenuUtil.FindItem(getNativeMenu(), "Upgrade Firmware").enabled = canReset;
			canReset = DeviceManager.sharedManager().currentName!="PicoBoard";
			MenuUtil.FindItem(getNativeMenu(), "View Source").enabled = canReset;
		}
		
		private function __onSelectBoard(menuItem:NativeMenuItem):void
		{
			DeviceManager.sharedManager().onSelectBoard(menuItem.name);
		}
		
		private function __onShowBoards(evt:Event):void
		{
			var menu:NativeMenu = evt.target as NativeMenu;
			for each(var item:NativeMenuItem in menu.items){
				if(item.enabled){
					item.checked = DeviceManager.sharedManager().checkCurrentBoard(item.name);
				}
			}
		}
		
		private function __onInitExtMenu(evt:Event):void
		{
			var menuItem:NativeMenu = evt.target as NativeMenu;
//			menuItem.removeEventListener(evt.type, __onInitExtMenu);
//			menuItem.addEventListener(evt.type, __onShowExtMenu);
			var list:Array = MBlock.app.extensionManager.extensionList;
			if(list.length==0){
				MBlock.app.extensionManager.copyLocalFiles();
				SharedObjectManager.sharedManager().setObject("first-launch",false);
			}
			while(menuItem.numItems > 3){
				menuItem.removeItemAt(menuItem.numItems-1);
			}
			list = MBlock.app.extensionManager.extensionList;
//			var subMenu:NativeMenu = menuItem;
			for(var i:int=0;i<list.length;i++){
				var extName:String = list[i].extensionName;
				var subMenuItem:NativeMenuItem = menuItem.addItem(new NativeMenuItem(Translator.map(extName)));
				subMenuItem.name = extName;
				subMenuItem.checked = MBlock.app.extensionManager.checkExtensionSelected(extName);
				register(extName, __onExtensions);
			}
		}
		/*
		private function __onShowExtMenu(evt:Event):void
		{
			var menuItem:NativeMenu = evt.target as NativeMenu;
			var list:Array = MBlock.app.extensionManager.extensionList;
			for(var i:int=0;i<list.length;i++){
				var extName:String = list[i].extensionName;
				var subMenuItem:NativeMenuItem = menuItem.getItemAt(i+2);
				subMenuItem.checked = MBlock.app.extensionManager.checkExtensionSelected(extName);
			}
		}
		*/
		private function __onExtensions(menuItem:NativeMenuItem):void
		{
			MBlock.app.extensionManager.onSelectExtension(menuItem.name);
		}
		
		private function __onHelp(menuItem:NativeMenuItem):void
		{
			var path:String = menuItem.data.@url;
			if("Forum" == menuItem.name){
				path = Translator.map(path);
			}
			if(path){
				navigateToURL(new URLRequest(path),"_blank");
			}
			
			switch(menuItem.name)
			{
				case "Share Your Project":
					MBlock.app.track("/OpenShare/");
					break;
				case "FAQ":
					MBlock.app.track("/OpenFaq/");
					break;
				default:
					MBlock.app.track("/OpenHelp/"+menuItem.data.@key);
			}
			
			switch(menuItem.data.@key.toString()){
				case "check_app_update":
					AppUpdater.getInstance().start(true);
					break;
				case "check_asset_update":
					VersionManager.sharedManager().start();
					break;
			}
		}
	}
}