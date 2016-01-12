package cc.makeblock.mbot.uiwidgets
{
	import cc.makeblock.mbot.util.PopupUtil;
	
	import org.aswing.AsWingConstants;
	import org.aswing.JFrame;
	
	public class MyFrame extends JFrame
	{
		public function MyFrame(owner:*=null, title:String="", modal:Boolean=false)
		{
			super(owner, title, modal);
			defaultCloseOperation = HIDE_ON_CLOSE;
			setResizable(false);
			PopupUtil.centerFrameTitle(this);
		}
	}
}