package cc.makeblock.mbot.uiwidgets.extensionMgr
{
	import org.aswing.ASColor;
	import org.aswing.AbstractListCell;
	import org.aswing.BorderLayout;
	import org.aswing.Component;
	import org.aswing.Insets;
	import org.aswing.JLabel;
	import org.aswing.JLabelButton;
	import org.aswing.JPanel;
	import org.aswing.JSharedToolTip;
	import org.aswing.border.EmptyBorder;
	import org.aswing.border.SideLineBorder;
	import org.aswing.event.AWEvent;
	import org.aswing.event.ResizedEvent;
	import org.aswing.geom.IntPoint;
	
	import translation.Translator;
	
	/**
	 * Default list cell, render item value.toString() text.
	 * @author iiley
	 */
	public class DefaultListCell extends AbstractListCell{
		
		private var jlabel:JLabel;
		private var btn:JLabelButton;
		private var wrapper:JPanel;
		
		private static var sharedToolTip:JSharedToolTip;
		
		public function DefaultListCell(){
			super();
			if(sharedToolTip == null){
				sharedToolTip = new JSharedToolTip();
				sharedToolTip.setOffsetsRelatedToMouse(false);
				sharedToolTip.setOffsets(new IntPoint(0, 0));
			}
		}
		
		override public function setCellValue(value:*) : void {
			super.setCellValue(value);
			getJLabel().setText(getStringValue(value));
			__resized(null);
		}
		
		/**
		 * Override this if you need other value->string translator
		 */
		protected function getStringValue(value:*):String{
			return value + "";
		}
		
		override public function getCellComponent() : Component {
			if(null == wrapper){
				wrapper = new JPanel(new BorderLayout());
				wrapper.append(getJLabel(), BorderLayout.CENTER);
				btn = new JLabelButton();
				btn.addActionListener(__onViewSource);
				btn.setX(200);
				btn.setBorder(new EmptyBorder(null, new Insets(0, 0, 0, 6)));
				wrapper.append(btn, BorderLayout.EAST);
				wrapper.setBorder(new SideLineBorder(null, SideLineBorder.SOUTH, new ASColor(0xf5f5f5)));
				wrapper.setOpaque(true);
			}
			btn.setText(Translator.map("View Source"));
			return wrapper;
		}
		
		private function __onViewSource(evt:AWEvent):void
		{
			var extName:String = getJLabel().getText().toLowerCase();
			if(extName == "communication"){
				extName = "serial";
			}
			trace(this, "__onViewSource");
		}
		
		protected function getJLabel():JLabel{
			if(jlabel == null){
				jlabel = new JLabel();
				jlabel.setBorder(new EmptyBorder(null, new Insets(0, 6, 0, 0)));
				initJLabel(jlabel);
			}
			return jlabel;
		}
		
		protected function initJLabel(jlabel:JLabel):void{
			jlabel.setHorizontalAlignment(JLabel.LEFT);
//			jlabel.setOpaque(true);
			jlabel.setFocusable(false);
			jlabel.addEventListener(ResizedEvent.RESIZED, __resized);
		}
		
		protected function __resized(e:ResizedEvent):void{
			if(getJLabel().getWidth() < getJLabel().getPreferredWidth()){
				getJLabel().setToolTipText(value.toString());
				JSharedToolTip.getSharedInstance().unregisterComponent(getJLabel());
				sharedToolTip.registerComponent(getJLabel());
			}else{
				getJLabel().setToolTipText(null);
				sharedToolTip.unregisterComponent(getJLabel());
			}
		}
	}
}

