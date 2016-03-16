package cc.makeblock.mbot.uiwidgets.extensionMgr
{
	import flash.events.Event;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	
	import cc.makeblock.mbot.uiwidgets.MyFrame;
	import cc.makeblock.mbot.util.PopupUtil;
	
	import org.aswing.ASColor;
	import org.aswing.ASFont;
	import org.aswing.AsWingUtils;
	import org.aswing.BorderLayout;
	import org.aswing.CenterLayout;
	import org.aswing.DefaultListTextCellFactory;
	import org.aswing.JButton;
	import org.aswing.JList;
	import org.aswing.JPanel;
	import org.aswing.SoftBoxLayout;
	import org.aswing.SolidBackground;
	import org.aswing.event.AWEvent;
	import org.aswing.geom.IntDimension;
	
	import translation.Translator;
	
	internal class ExtensionMgrFrame extends MyFrame
	{
		private var extList:JList;
		private var btnList:JPanel;
		
		private var btnAdd:JButton;
		private var btnRemove:JButton;
		
		public function ExtensionMgrFrame(owner:*=null)
		{
			super(owner, "Extension Manager", true);
			extList = new JList(null, new DefaultListTextCellFactory(DefaultListCell, true, true, 38));
			extList.setBackgroundDecorator(new SolidBackground(new ASColor(0xFFFFFF)));
			
			btnList = new JPanel(new SoftBoxLayout(SoftBoxLayout.X_AXIS, 190, SoftBoxLayout.CENTER));
			
			btnAdd = new JButton("add extension");
			setBtnStyle(btnAdd);
			btnRemove = new JButton("remove extension");
			setBtnStyle(btnRemove);
			
			btnList.append(btnRemove);
			btnList.append(btnAdd);
			
			var bottomWrapper:JPanel = new JPanel(new CenterLayout());
			bottomWrapper.setBackgroundDecorator(new SolidBackground(new ASColor(0xe9e9ea)));
			bottomWrapper.setPreferredHeight(64);
			bottomWrapper.append(btnList);
			
			getContentPane().append(extList);
			getContentPane().append(bottomWrapper, BorderLayout.SOUTH);
			
			pack();
			setSizeWH(530, 400);
			addEvents();
		}
		
		private function addEvents():void
		{
			btnAdd.addActionListener(__onAddExtension);
			btnRemove.addActionListener(__onRemoveExtension);
		}
		
		private function __onAddExtension(evt:AWEvent):void
		{
			var file:FileReference = new FileReference();
			file.addEventListener(Event.SELECT, function(evt:Event):void{
				ExtensionUtil.OnAddExtension(file);
				updateList();
			});
			file.browse([new FileFilter("json file", "*.json"), new FileFilter("zip file", "*.zip")]);
		}
		
		private function __onRemoveExtension(evt:AWEvent):void
		{
			if(extList.getSelectedIndex() >= 0){
				ExtensionUtil.OnDelExtension(extList.getSelectedValue(), updateList);
			}
		}
		
		override public function show():void
		{
			Translator.regChangeEvt(__onLangChanged);
			updateList();
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
		
		private function updateList():void
		{
			extList.setListData(getExtNameList());
		}
		
		static private function getExtNameList():Array
		{
			var result:Array = [];
			for each(var ext:Object in MBlock.app.extensionManager.extensionList){
				result.push(ext.extensionName);
			}
			return result;
		}
		
		private function __onLangChanged(evt:Event=null):void
		{
			extList.setListData(null);
			updateList();
			
			setTitle(Translator.map("Manage Extensions"));
			
			btnAdd.setText(Translator.map("Add Extension"));
			btnRemove.setText(Translator.map("Remove Extension"));
		}
		
		static private function setBtnStyle(btn:JButton):void
		{
			btn.setPreferredSize(new IntDimension(150, 28));
			btn.setFont(new ASFont("微软雅黑",14));
			btn.setForeground(new ASColor(0x424242));
		}
	}
}