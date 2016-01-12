package cc.makeblock.mbot.ui.parts
{
	import flash.html.HTMLLoader;
	import flash.net.URLRequest;
	
	import cc.makeblock.mbot.uiwidgets.MyFrame;
	import cc.makeblock.mbot.util.PopupUtil;
	
	import org.aswing.AsWingUtils;
	
	import translation.Translator;

	public class HelpFrame extends MyFrame
	{
		private var ldr:HTMLLoader;
		
		public function HelpFrame()
		{
			setSizeWH(340, 440);
			ldr = new HTMLLoader();
			ldr.width = 550;
			ldr.height = 400;
			getContentPane().addChild(ldr);
		}
		
		override public function show():void
		{
			AsWingUtils.centerLocate(this);
			super.show();
			ldr.load(new URLRequest("static_tips/en/home.html"));
		}
	}
}