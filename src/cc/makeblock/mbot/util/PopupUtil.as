package cc.makeblock.mbot.util
{
	import flash.events.MouseEvent;
	
	import org.aswing.JOptionPane;
	
	import translation.Translator;

	public class PopupUtil
	{
		static public function enableRightMouseEvent():void
		{
			MBlock.app.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, MBlock.app.gh.onRightMouseDown);
		}
		
		static public function disableRightMouseEvent():void
		{
			MBlock.app.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, MBlock.app.gh.onRightMouseDown);
		}
		
		static public function showQuitAlert(callback:Function):void
		{
			JOptionPane.YES_STR = Translator.map('Save');
			JOptionPane.NO_STR = Translator.map("Don't save");
			JOptionPane.CANCEL_STR = Translator.map('Cancel');
			disableRightMouseEvent();
			JOptionPane.showMessageDialog(Translator.map('Save project?'), null, function(value:int):void{
				enableRightMouseEvent();
				callback(value);
			}, null, true, null, JOptionPane.YES | JOptionPane.NO | JOptionPane.CANCEL);
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