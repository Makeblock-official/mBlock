package cc.makeblock.mbot.uiwidgets.extensionMgr
{
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.net.FileFilter;
	
	import cc.makeblock.mbot.util.ButtonFactory;
	import cc.makeblock.mbot.util.PopupUtil;
	
	import org.aswing.AsWingUtils;
	import org.aswing.BorderLayout;
	import org.aswing.JButton;
	import org.aswing.JFrame;
	import org.aswing.JList;
	import org.aswing.JPanel;
	import org.aswing.SoftBoxLayout;
	import org.aswing.event.AWEvent;
	
	import translation.Translator;
	
	internal class ExtensionMgrFrame extends JFrame
	{
		private var extList:JList;
		private var btnList:JPanel;
		
		private var btnAdd:JButton;
		private var btnRemove:JButton;
		
		public function ExtensionMgrFrame(owner:*=null)
		{
			super(owner, "Extension Manager", true);
			defaultCloseOperation = HIDE_ON_CLOSE;
			setResizable(false);
			
			extList = new JList();
			
			
			btnList = new JPanel(new SoftBoxLayout(SoftBoxLayout.Y_AXIS, 2, SoftBoxLayout.LEFT));
			
			btnAdd = ButtonFactory.createBtn("add extension");
			btnRemove = ButtonFactory.createBtn("remove extension");
			
			btnList.append(btnAdd);
			btnList.append(btnRemove);
			
			getContentPane().append(extList);
			getContentPane().append(btnList, BorderLayout.EAST);
			
			pack();
			setSizeWH(550, 400);
			addEvents();
		}
		
		private function addEvents():void
		{
			btnAdd.addActionListener(__onAddExtension);
			btnRemove.addActionListener(__onRemoveExtension);
		}
		
		private function __onAddExtension(evt:AWEvent):void
		{
			var file:File = new File();
			file.addEventListener(Event.SELECT, function(evt:Event):void{
				ExtensionUtil.OnAddExtension(file);
				updateList();
			});
			file.browseForOpen("please select file", [new FileFilter("zip file", "*.zip")]);
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
			setTitle(Translator.map("Extension Manager"));
			
			btnAdd.setText(Translator.map("Add Extension"));
			btnRemove.setText(Translator.map("Remove Extension"));
		}
	}
}