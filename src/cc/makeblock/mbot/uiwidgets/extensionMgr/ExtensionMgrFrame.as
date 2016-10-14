package cc.makeblock.mbot.uiwidgets.extensionMgr
{
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.net.FileFilter;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	import flash.utils.getDefinitionByName;
	
	import cc.makeblock.mbot.uiwidgets.MyFrame;
	import cc.makeblock.mbot.uiwidgets.extensionMgr.DefaultListCell;
	import cc.makeblock.mbot.util.PopupUtil;
	
	import org.aswing.ASColor;
	import org.aswing.ASFont;
	import org.aswing.AsWingConstants;
	import org.aswing.AsWingUtils;
	import org.aswing.BorderLayout;
	import org.aswing.BoxLayout;
	import org.aswing.DefaultListTextCellFactory;
	import org.aswing.FlowLayout;
	import org.aswing.JButton;
	import org.aswing.JLabel;
	import org.aswing.JList;
	import org.aswing.JPanel;
	import org.aswing.JTextField;
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
		private var searchTxtField:JTextField;
		private var availableBtn:JButton;
		private var installedBtn:JButton;
		private var searchLabel:JLabel;
		private var defalutSearchTxt:String = "                                                 ";

		private var searchTimer:Timer = new Timer(1000,1);
		
		public function ExtensionMgrFrame(owner:*=null)
		{
			super(owner, "Extension Manager", true);
			extList = new JList(null, new DefaultListTextCellFactory(DefaultListCell, true, true, 50));
			extList.setBackgroundDecorator(new SolidBackground(new ASColor(0xFFFFFF)));

			btnList = new JPanel(new SoftBoxLayout(SoftBoxLayout.X_AXIS, 190, SoftBoxLayout.CENTER));
			
			btnAdd = new JButton("add extension");
			setBtnStyle(btnAdd);
			/*btnRemove = new JButton("remove extension");
			setBtnStyle(btnRemove);*/
			
			searchTxtField = new JTextField(defalutSearchTxt);

			searchTxtField.setWidth(500);
			searchTxtField.setTextFormat(new TextFormat(null,null,0x999999),0,searchTxtField.getText().length);
			//btnList.append(btnRemove);
			btnList.append(btnAdd);
			
			var bottomWrapper:JPanel = new JPanel(new FlowLayout(AsWingConstants.RIGHT));
			bottomWrapper.setBackgroundDecorator(new SolidBackground(new ASColor(0xe9e9ea)));
			bottomWrapper.setPreferredHeight(50);
			bottomWrapper.append(btnList);
			
			var chooseBtnPanel:JPanel = new JPanel(new FlowLayout(2,0));
			availableBtn = new JButton(Translator.map("Available"));
			installedBtn = new JButton(Translator.map("Installed"));
			chooseBtnPanel.append(availableBtn);
			chooseBtnPanel.append(installedBtn);
			
			var searchPanel:JPanel = new JPanel(new FlowLayout());
			searchLabel = new JLabel(Translator.map("Search"));
			searchPanel.append(searchLabel);
			searchPanel.append(searchTxtField);
			
			var northList:JPanel = new JPanel(new BoxLayout(0,0));
			northList.append(chooseBtnPanel,BorderLayout.WEST);
			northList.append(searchPanel,BorderLayout.EAST);
			
			getContentPane().append(northList,BorderLayout.NORTH);
			
			
			getContentPane().append(extList);
			getContentPane().append(bottomWrapper, BorderLayout.SOUTH);
			
			pack();
			setSizeWH(530, 500);
			addEvents();
			availableBtn.dispatchEvent(new AWEvent(AWEvent.ACT));
		}
		
		private function addEvents():void
		{
			btnAdd.addActionListener(__onAddExtension);
			//btnRemove.addActionListener(__onRemoveExtension);
			searchTxtField.addEventListener(FocusEvent.FOCUS_IN,onFocusIn);
			searchTxtField.addEventListener(FocusEvent.FOCUS_OUT,onFocusOut);
			searchTxtField.addEventListener(Event.CHANGE,onTextChangeHandler)
			availableBtn.addActionListener(shwoAvailableExtension);
			installedBtn.addActionListener(showInstalledExtension);
			ExtensionUtil.dispatcher.addEventListener("removeItem",__onRemoveExtension);
			ExtensionUtil.dispatcher.addEventListener("updateList",updateList);
		}
		private function onTextChangeHandler(e:Event):void
		{
			searchTimer.reset();
			searchTimer.start();
			searchTimer.addEventListener(TimerEvent.TIMER_COMPLETE,onTimerComplete);
		}
		private function onTimerComplete(e:TimerEvent):void
		{
			if(/\S/.test(searchTxtField.getText()))
			{
				var result:Array = searchItems(searchTxtField.getText());
				extList.setListData(result);
				
			}
			else if(searchTxtField.getText()=="")
			{
				updateList();
			}
		}
		private function searchItems(str:String):Array
		{
			str = str.replace(/^\s+|\s+$/g,"");
			var vec:Array = new Array();
			for each(var obj:Object in ExtensionUtil.currExtArr)
			{
				if(obj.name.toLowerCase().indexOf(str.toLocaleLowerCase())>-1)
				{
					vec.push(obj);
				}
				else if(obj.description.toLowerCase().indexOf(str.toLocaleLowerCase())>-1)
				{
					vec.push(obj);
				}
			}
			return vec;
		}
		private function shwoAvailableExtension(evt:AWEvent):void
		{
			if(availableBtn.isSelected())
			{
				return;
			}
			extList.clearSelection();
			availableBtn.setSelected(true);
			installedBtn.setSelected(false);
			
			ExtensionUtil.checkAvailExtList(function():void{
				updateList();
				
				
			})
		}
		private function showInstalledExtension(evt:AWEvent):void
		{
			if(installedBtn.isSelected())
			{
				return;
			}
			extList.clearSelection();
			availableBtn.setSelected(false);
			installedBtn.setSelected(true);
			updateList();
		}
		private function onFocusIn(e:FocusEvent):void
		{
			if(searchTxtField.getText()==defalutSearchTxt)
			searchTxtField.getTextField().text = "";
		}
		private function onFocusOut(e:FocusEvent):void
		{
			if(searchTxtField.getText()=="")
			{
				searchTxtField.setText(defalutSearchTxt);
				searchTxtField.setTextFormat(new TextFormat(null,null,0x999999),0,searchTxtField.getText().length);
			}
		}
		private function __onAddExtension(evt:AWEvent):void
		{
			var file:File = new File();
			file.addEventListener(Event.SELECT, function(evt:Event):void{
				ExtensionUtil.OnAddExtension(file);
				updateList();
			});
			file.browseForOpen("please select file", [new FileFilter("json file", "*.json"), new FileFilter("zip file", "*.zip")]);
		}
		
		private function __onRemoveExtension(evt:Event):void
		{
			if(extList.getSelectedIndex() >= 0){
				ExtensionUtil.OnDelExtension(extList.getSelectedValue().name, updateList);
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
		
		private function updateList(e:Event=null):void
		{
			ExtensionUtil.currExtArr = [];
			if(availableBtn.isSelected())
			{
				ExtensionUtil.showType = 0;
				extList.setListData(ExtensionUtil.getAvailableList());
			}
			else if(installedBtn.isSelected())
			{
				ExtensionUtil.showType = 1;
				extList.setListData(getExtNameList());
			}
		}
		
		static private function getExtNameList():Array
		{
			var result:Array = [];
			for each(var ext:Object in MBlock.app.extensionManager.extensionList){
				var author:String = ext.author?ext.author.substr(0,ext.author.indexOf("(")):"";
				var authorLink:String = ext.author?ext.author.match(/\(.+\)/):"";
				authorLink = authorLink && authorLink.length>0?authorLink.substring(1,authorLink.length-1):"";
				var obj:Object = {name:ext.extensionName||"",description:ext.description||"",version:ext.version||"",author:author,authorLink:authorLink,homepage:ext.homepage||""}
				result.push(obj);
			}
			return result;
		}
		
		private function __onLangChanged(evt:Event=null):void
		{
			extList.setListData(null);
			updateList();
			
			setTitle(Translator.map("Manage Extensions"));
			
			btnAdd.setText(Translator.map("Add Extension"));
			
			availableBtn.setText(Translator.map("Available"));
			installedBtn.setText(Translator.map("Installed"));
			
			searchLabel.setText(Translator.map("Search"));
			
			//btnRemove.setText(Translator.map("Remove Extension"));
		}
		
		static private function setBtnStyle(btn:JButton):void
		{
			btn.setPreferredSize(new IntDimension(150, 28));
			btn.setFont(new ASFont("微软雅黑",14));
			btn.setForeground(new ASColor(0x424242));
		}
	}
}