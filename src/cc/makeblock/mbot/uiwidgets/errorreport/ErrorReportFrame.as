package cc.makeblock.mbot.uiwidgets.errorreport
{
	import flash.events.Event;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	import flash.system.Capabilities;
	
	import cc.makeblock.mbot.uiwidgets.MyFrame;
	import cc.makeblock.mbot.util.PopupUtil;
	
	import org.aswing.AsWingUtils;
	import org.aswing.BorderLayout;
	import org.aswing.CenterLayout;
	import org.aswing.JButton;
	import org.aswing.JPanel;
	import org.aswing.JTextArea;
	import org.aswing.event.AWEvent;
	
	import translation.Translator;
	
	public class ErrorReportFrame extends MyFrame
	{
		static public function OpenSendWindow(msg:String):void
		{
			var request:URLRequest = new URLRequest("http://feedback.makeblock.com/");
			var data:URLVariables = new URLVariables();
			data.m = msg;
			data.os = Capabilities.os;
			data.v = "mBlock " + MBlock.versionString;
			data.l = (Translator.currentLang.indexOf("zh_") == 0) ? "zh" : "en";
			request.data = data;
			navigateToURL(request);
		}
		
		private var textArea:JTextArea;
		private var sendBtn:JButton;
		
		public function ErrorReportFrame()
		{
			super(null, "Error Report", true);
			
			textArea = new JTextArea();
			getContentPane().append(textArea);
			
			sendBtn = new JButton("Send");
			var bottomPane:JPanel = new JPanel(new CenterLayout());
			bottomPane.append(sendBtn);
			getContentPane().append(bottomPane, BorderLayout.SOUTH);
			
			pack();
			setSizeWH(530, 400);
			
			sendBtn.addActionListener(__onSend);
		}
		
		private function __onSend(evt:AWEvent):void
		{
			OpenSendWindow(textArea.getText());
		}
		
		public function setText(value:String):void
		{
			textArea.setText(value);
		}
		
		override public function show():void
		{
			Translator.regChangeEvt(__onLangChanged);
			AsWingUtils.centerLocate(this);
			super.show();
			PopupUtil.disableRightMouseEvent();
		}
		
		override public function hide():void
		{
			super.hide();
			Translator.unregChangeEvt(__onLangChanged);
			PopupUtil.enableRightMouseEvent();
		}
		
		private function __onLangChanged(evt:Event=null):void
		{
			setTitle(Translator.map("Upload Bug"));
			sendBtn.setText(Translator.map("Send"));
		}
	}
}