package cc.makeblock.updater
{
	import cc.makeblock.mbot.util.PopupUtil;
	
	import org.aswing.JOptionPane;
	
	import translation.Translator;
	
	public class UpdateFrame
	{
		private static var _instance:UpdateFrame;
		static public function getInstance():UpdateFrame
		{
			if(null == _instance){
				_instance = new UpdateFrame();
			}
			return _instance;
		}
		
		public function UpdateFrame()
		{
		}
		
		private var panel:JOptionPane;
		
		public function show():void
		{
			hide();
			panel = PopupUtil.showAlert("Checking for updates");
			panel.getYesButton().setText(Translator.map("Cancel"));
		}
		
		public function hide():void
		{
			if(panel != null){
				panel.getFrame().dispose();
				panel = null;
			}
		}
	}
}