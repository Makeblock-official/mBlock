package cc.makeblock.mbot.util
{
	import flash.display.NativeWindow;
	import flash.display.NativeWindowDisplayState;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.ColorTransform;
	import flash.geom.Rectangle;
	
	import org.aswing.AsWingConstants;
	import org.aswing.AsWingUtils;
	import org.aswing.JFrame;
	import org.aswing.JOptionPane;
	import org.aswing.JPopup;
	
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
		
		static public function showAlert(title:String):JOptionPane
		{
			var panel:JOptionPane = PopupUtil.showConfirm(title, null);
			panel.getCancelButton().getParent().remove(panel.getCancelButton());
			panel.getYesButton().setText(Translator.map("I know"));
			panel.getFrame().setModal(true);
			return panel;panel
		}
		
		static public function showConfirm(title:String, callback:Function):JOptionPane
		{
			var panel:JOptionPane = showQuitAlert(callback);
			
			panel.getFrame().setTitle(Translator.map(title));
			panel.getNoButton().getParent().remove(panel.getNoButton());
			panel.getYesButton().setText(Translator.map('OK'));
			panel.getCancelButton().setText(Translator.map('Cancel'));
			
			panel.getFrame().setSizeWH(240, 90);
			AsWingUtils.centerLocate(panel.getFrame());
			return panel;
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
					if(callback != null){
						callback(value);
					}
			}, null, true, null, JOptionPane.YES | JOptionPane.NO | JOptionPane.CANCEL);
			
			panel.getFrame().setClosable(false);
			centerFrameTitle(panel.getFrame());
			
			panel.getYesButton().setPreferredWidth(100);
			panel.getNoButton().setPreferredWidth(100);
			panel.getCancelButton().setPreferredWidth(100);
			
			panel.getYesButton().pack();
			panel.getNoButton().pack();
			panel.getCancelButton().pack();
			
			panel.getFrame().setSizeWH(340, 90);
			
			
			
			var window:NativeWindow = panel.stage.nativeWindow;
			var frame:JFrame = panel.getFrame();
			if(window.displayState == NativeWindowDisplayState.MINIMIZED){
				var bounds:Rectangle = window.bounds;
				frame.setX((bounds.width - frame.getWidth()) * 0.5);
				frame.setY((bounds.height - frame.getHeight()) * 0.5);
			}else{
				AsWingUtils.centerLocate(frame);
			}
			
			var modalMC:Sprite = panel.getFrame().getModalMC();
			var trans:ColorTransform = new ColorTransform();
			trans.alphaOffset = 100;
			modalMC.transform.colorTransform = trans;
			MBlock.app.stage.addEventListener(MouseEvent.MOUSE_DOWN,mouseHandler);
			return panel;
		}
		static private function mouseHandler(e:MouseEvent):void
		{
			trace("e.target="+e.target)
		}
		static public function centerFrameTitle(frame:JFrame):void
		{
			frame.getTitleBar().getLabel().setHorizontalAlignment(AsWingConstants.CENTER);
		}
	}
}