package cc.makeblock.mbot.util
{
	import flash.events.MouseEvent;
	
	import org.aswing.AsWingUtils;
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
		
		static public function showQuitAlert(callback:Function):void
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
			
			panel.getYesButton().setPreferredWidth(80);
			panel.getNoButton().setPreferredWidth(80);
			panel.getCancelButton().setPreferredWidth(80);
			
			panel.getYesButton().pack();
			panel.getNoButton().pack();
			panel.getCancelButton().pack();
			
			panel.getFrame().setSizeWH(280, 90);
			AsWingUtils.centerLocate(panel.getFrame());
			
			JOptionPane.YES_STR = "Yes";
			JOptionPane.NO_STR = "No";
			JOptionPane.CANCEL_STR = "Cancel";
			/*
			d.addTitle(Translator.map('Save project') + '?');
			d.addButton('Save', save);
			d.addButton('Don\'t save', proceedWithoutSaving);
			d.addButton('Cancel', cancel);
			*/
		}
	}
}