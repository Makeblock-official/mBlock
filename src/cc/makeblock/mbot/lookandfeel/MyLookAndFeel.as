package cc.makeblock.mbot.lookandfeel
{
	import org.aswing.UIDefaults;
	import org.aswing.plaf.ASColorUIResource;
	import org.aswing.plaf.basic.BasicLookAndFeel;
	
	public class MyLookAndFeel extends BasicLookAndFeel
	{
		public function MyLookAndFeel(){}
		
		override public function getDefaults():UIDefaults
		{
			var uiDefault:UIDefaults = super.getDefaults();
			
			uiDefault.put("Button.background", new ASColorUIResource(0xe8e8e8));
			uiDefault.put("Button.foreground", new ASColorUIResource(0x424242));
			uiDefault.put("Button.textFilters", null);
			
			uiDefault.put("ToggleButton.background", uiDefault.get("Button.background"));
			uiDefault.put("ToggleButton.foreground", uiDefault.get("Button.foreground"));
			
			uiDefault.put("Frame.mideground", new ASColorUIResource(0xe8e8e8));
			uiDefault.put("FrameTitleBar.mideground", uiDefault.get("Frame.mideground"));
			uiDefault.put("FrameTitleBar.foreground", new ASColorUIResource(0x666666));
			
			return uiDefault;
		}
	}
}