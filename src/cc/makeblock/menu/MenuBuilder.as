package cc.makeblock.menu
{
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;

	public class MenuBuilder
	{
		static public function BuildMenu(source:XML):NativeMenu
		{
			var result:NativeMenu = new NativeMenu();
			for each(var node:XML in source.children()){
				result.addItem(BuildMenuItem(node));
			}
			return result;
		}
		
		static private function BuildMenuItem(source:XML):NativeMenuItem
		{
			var result:NativeMenuItem = new NativeMenuItem(source.@label, source.@isSeparator == "true");
			result.name = source.@name;
			result.keyEquivalent = source.@keyEquivalent;
			if(source.hasOwnProperty("@enabled")){
				result.enabled = (source.@enabled == "true");
			}
			if(source.hasOwnProperty("@mnemonic")){
				var mnemonic:String = source.@mnemonic;
				if(result.label.indexOf(mnemonic) < 0){
					result.label += "(" + mnemonic + ")";
					result.mnemonicIndex = result.label.length - 2;
				}else{
					result.mnemonicIndex = result.label.lastIndexOf(mnemonic);
				}
			}
			if(source.hasComplexContent()){
				result.submenu = BuildMenu(source);
			}else{
				result.data = source;
			}
			return result;
		}
	}
}