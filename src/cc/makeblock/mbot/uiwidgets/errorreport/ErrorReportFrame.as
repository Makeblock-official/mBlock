package cc.makeblock.mbot.uiwidgets.errorreport
{
	import flash.events.Event;
	
	import cc.makeblock.mbot.uiwidgets.MyFrame;
	import cc.makeblock.mbot.util.PopupUtil;
	import cc.makeblock.util.Email;
	
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
			new Email("testing@makeblock.cc", "bug report", textArea.getText()).send();
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
			setTitle(Translator.map("Error Report"));
			sendBtn.setText(Translator.map("Send"));
		}
	}
}