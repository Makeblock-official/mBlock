package cc.makeblock.mbot.util
{
	import flash.events.MouseEvent;
	
	import org.aswing.AsWingConstants;
	import org.aswing.AsWingUtils;
	import org.aswing.JFrame;
	import org.aswing.JOptionPane;
	
	import translation.Translator;

	public class PopupUtil
	{
		static public function enableRightMouseEvent():void
		{
			var app:MBlock = MBlock.app;
			app.stage.addEventListener(MouseEvent.MOUSE_DOWN, app.gh.mouseDown);
			app.stage.addEventListener(MouseEvent.MOUSE_MOVE, app.gh.mouseMove);
			app.stage.addEventListener(MouseEvent.MOUSE_UP, app.gh.mouseUp);
			app.stage.addEventListener(MouseEvent.MOUSE_WHEEL, app.gh.mouseWheel);
			app.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, app.gh.onRightMouseDown);
		}
		
		static public function disableRightMouseEvent():void
		{
			var app:MBlock = MBlock.app;
			app.stage.removeEventListener(MouseEvent.MOUSE_DOWN, app.gh.mouseDown);
			app.stage.removeEventListener(MouseEvent.MOUSE_MOVE, app.gh.mouseMove);
			app.stage.removeEventListener(MouseEvent.MOUSE_UP, app.gh.mouseUp);
			app.stage.removeEventListener(MouseEvent.MOUSE_WHEEL, app.gh.mouseWheel);
			app.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, app.gh.onRightMouseDown);
		}
		
		static public function showConfirm(title:String, callback:Function):void
		{
			var panel:JOptionPane = showQuitAlert(callback);
			
			panel.getFrame().setTitle(Translator.map(title));
			panel.getNoButton().getParent().remove(panel.getNoButton());
			panel.getYesButton().setText(Translator.map('OK'));
			panel.getCancelButton().setText(Translator.map('Cancel'));
			
			panel.getFrame().setSizeWH(240, 90);
			AsWingUtils.centerLocate(panel.getFrame());
		}
		
		static public function showQuitAlert(callback:Function):JOptionPane
		{
			JOptionPane.YES_STR = Translator.map('Save');
			JOptionPane.NO_STR = Translator.map("Don't save");
			JOptionPane.CANCEL_STR = Translator.map('Cancel');
			
			disableRightMouseEvent();
			var panel:JOptionPane = JOptionPane.showMessageDialog(
				Translator.map('Save project?'),
				null,
				function(value:int):void{
					enableRightMouseEvent();
					callback(value);
			}, null, true, null, JOptionPane.YES | JOptionPane.NO | JOptionPane.CANCEL);
			
			panel.getFrame().setClosable(false);
			centerFrameTitle(panel.getFrame());
			
			panel.getYesButton().setPreferredWidth(80);
			panel.getNoButton().setPreferredWidth(80);
			panel.getCancelButton().setPreferredWidth(80);
			
			panel.getYesButton().pack();
			panel.getNoButton().pack();
			panel.getCancelButton().pack();
			
			panel.getFrame().setSizeWH(280, 90);
			AsWingUtils.centerLocate(panel.getFrame());
			
			return panel;
		}
		
		static public function centerFrameTitle(frame:JFrame):void
		{
			frame.getTitleBar().getLabel().setHorizontalAlignment(AsWingConstants.CENTER);
		}
	}
}