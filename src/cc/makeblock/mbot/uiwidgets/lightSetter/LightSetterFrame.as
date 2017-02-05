package cc.makeblock.mbot.uiwidgets.lightSetter
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	
	import cc.makeblock.mbot.uiwidgets.MyFrame;
	import cc.makeblock.mbot.util.PopupUtil;
	
	import org.aswing.ASColor;
	import org.aswing.ASFont;
	import org.aswing.AbstractButton;
	import org.aswing.AsWingUtils;
	import org.aswing.AssetIcon;
	import org.aswing.AssetPane;
	import org.aswing.BorderLayout;
	import org.aswing.CenterLayout;
	import org.aswing.Component;
	import org.aswing.Insets;
	import org.aswing.JButton;
	import org.aswing.JPanel;
	import org.aswing.JToggleButton;
	import org.aswing.SoftBoxLayout;
	import org.aswing.border.EmptyBorder;
	import org.aswing.border.LineBorder;
	import org.aswing.event.AWEvent;
	import org.aswing.geom.IntDimension;
	
	import translation.Translator;
	
	import util.ApplicationManager;
	import util.JsUtil;
	
	public class LightSetterFrame extends MyFrame
	{
		[Embed("/assets/UI/ledFace/Eraser-normal.png")]
		static private const ERASER_CLS:Class;
		
		[Embed("/assets/UI/ledFace/Flip_X-normal.png")]
		static private const FLIP_X_CLS:Class;
		
		[Embed("/assets/UI/ledFace/Flip_Y-normal.png")]
		static private const FLIP_Y_CLS:Class;
		
		[Embed("/assets/UI/ledFace/Rotate_normal.png")]
		static private const ROTATE_CLS:Class;
		
		[Embed("/assets/UI/ledFace/Eraser-disable.png")]
		static private const ERASER_DISABLE_CLS:Class;
		
		static public const MAX_CUSTOM_ITEMS:int = 48;
		
//		private const focusBorder:Border = new LineBorder(null, new ASColor(0xcbcbcb), 4);
//		private const defaultBorder:Border = new EmptyBorder(null, new Insets(4, 4, 4, 4));
		
		private var sensor:LightSensor;
//		private var centerPanel:JPanel;
		
		private var btnLightAll:JButton;
		private var btnCleartAll:JButton;
//		private var btnRotateView:JButton;
		private var btnRotatePixel:JButton;
		private var btnFlipX:JButton;
		private var btnFlipY:JButton;
		private var btnEraser:JToggleButton;
		private var btnDelete:JButton;
		
		private var btnOk:JButton;
		private var btnCancel:JButton;
		private var btnAddToFavorite:JButton;
		
//		private var thumbPanel:JPanel;
//		private var presetPanel:JPanel;
		
		private var focusThumb:AssetPane;
		private var thumbPane:ThumbPane;
		
		public function LightSetterFrame()
		{
			super(null, "Face Panel", true);
			
			sensor = new LightSensor();
			sensor.addEventListener(Event.SELECT, __onSelect);
			
			btnLightAll = new JButton("Light All");
			btnCleartAll = new JButton("Clear All");
			btnLightAll.setPreferredSize(new IntDimension(76, 36));
			btnCleartAll.setPreferredSize(new IntDimension(76, 36));
			
			btnRotatePixel = new JButton(null, new AssetIcon(new ROTATE_CLS()));
			btnFlipX = new JButton(null, new AssetIcon(new FLIP_X_CLS()));
			btnFlipY = new JButton(null, new AssetIcon(new FLIP_Y_CLS()));
			btnEraser = new JToggleButton(null, new AssetIcon(new ERASER_DISABLE_CLS()));
//			btnEraser.setHorizontalAlignment(AsWingConstants.LEFT);
			btnDelete = new JButton();
			btnDelete.setPreferredSize(new IntDimension(142, 36));
			
			setIconBtnStyle(btnRotatePixel);
			setIconBtnStyle(btnFlipX);
			setIconBtnStyle(btnFlipY);
			setIconBtnStyle(btnEraser);
			
			btnEraser.setSelectedIcon(new AssetIcon(new ERASER_CLS()));
			
			var centerPanel:Component = new AssetPane(sensor);
			centerPanel.setBorder(new LineBorder(null, new ASColor(0xd0d1d2)));
			var wrapper:JPanel = new JPanel(new CenterLayout());
			wrapper.append(centerPanel);
			
			var btnPanel:JPanel = new JPanel(new SoftBoxLayout(SoftBoxLayout.X_AXIS, 10));
			var bottomBtn:JPanel = new JPanel(new SoftBoxLayout(SoftBoxLayout.X_AXIS, 4, SoftBoxLayout.CENTER));
			
			btnOk = new JButton("Complete");
			btnOk.setPreferredWidth(162);
			btnCancel = new JButton("Cancel");
			btnCancel.setPreferredWidth(162);
			btnAddToFavorite = new JButton();
			btnAddToFavorite.setPreferredSize(new IntDimension(142, 36));
			
			btnPanel.append(btnCancel);
			btnPanel.append(btnOk);
			
			bottomBtn.append(btnEraser);
			bottomBtn.append(createEmpty(46, 36));
			bottomBtn.append(btnCleartAll);
			bottomBtn.append(btnLightAll);
			bottomBtn.append(createEmpty(48, 36));
			bottomBtn.append(btnRotatePixel);
			bottomBtn.append(btnFlipX);
			bottomBtn.append(btnFlipY);
			bottomBtn.append(createEmpty(52, 36));
			bottomBtn.append(btnDelete);
			bottomBtn.append(btnAddToFavorite);
			
			btnDelete.setVisible(false);
			
			setBtnStyle(btnLightAll);
			setBtnStyle(btnCleartAll);
			setBtnStyle(btnDelete);
			setBtnStyle(btnAddToFavorite);
			setBtnStyle(btnOk);
			setBtnStyle(btnCancel);
			
			thumbPane = new ThumbPane(this);
			thumbPane.addBtn(btnPanel);
			
			getContentPane().setLayout(new BorderLayout(4, 4));
			getContentPane().setBorder(new EmptyBorder(null, new Insets(16, 20, 16, 20)));
			getContentPane().append(wrapper, BorderLayout.CENTER);
			getContentPane().append(bottomBtn, BorderLayout.NORTH);
			getContentPane().append(thumbPane, BorderLayout.SOUTH);
			
			loadPresets();
			addEvents();
		}
		
		private function loadPresets():void
		{
			trace(this, "loadPresets");
			//先读取预设表情列表
			JsUtil.callApp("getDirectoryListing","preset");
			var cnt:int=0;
			JsUtil.callBack = function(fileListStr:String):void{
				var fileList:Array = fileListStr.split(",");
				for each(var item:String in fileList){
					//通过列表读取每个文件的内容
					JsUtil.callApp("readDrawFile",["preset",item])//FileUtil.ReadString(item);
					JsUtil.callBack = function(str:String):void{
						if(str)
						{	
							thumbPane.addThumb(item, genBitmapData(str), true);
						}
						cnt++;
						//如果累计读取次数等于列表长度，说明预设文件夹读取完了，可以读取用户定义目录了
						if(cnt>=fileList.length)
						{
							cnt = 0;
							//读取用户定义目录
							JsUtil.callApp("getDirectoryListing","custom");
							JsUtil.callBack = function(fileListStr:String):void{
								var fileList:Array = fileListStr.split(",");
								for each(var item2:String in fileList){
									//挨个读取文件内容
									JsUtil.callApp("readDrawFile",["custom",item2])//FileUtil.ReadString(item);
									JsUtil.callBack = function(str:String):void{
										if(str)
										{
											thumbPane.addThumb(item2, genBitmapData(str), true);
										}
									}
								}
							}
						}
					}
				}
				
			}
		}
		/*private function getCustomEmotionDir():File
		{
			return File.documentsDirectory.resolvePath("mBlock/emotions");
		}*/
		
		private function saveToFile(bmd:BitmapData):String
		{
			trace(this, "saveToFile");
			
			var result:String = "";
			for(var i:int=0; i< LightSensor.COUNT_H; i++){
				for (var j:int = 0; j < LightSensor.COUNT_W; j++) 
				{
					if(bmd.getPixel(j, i) == LightSensor.THUMBNAIL_ON_COLOR){
						result += "X";
					}else{
						result += "_";
					}
				}
				result += "\r\n";
			}
			
			/*var dir:File = getCustomEmotionDir();
			if(!dir.exists){
				dir.createDirectory();
			}
			var fileList:Array = dir.getDirectoryListing();
			while(fileList.length >= MAX_CUSTOM_ITEMS){
				(fileList.shift() as File).deleteFileAsync();
			}
			var fileName:String = new Date().getTime() + ".txt";
			FileUtil.WriteString(dir.resolvePath(fileName), result);
			return fileName;
			
			return "";*/
			JsUtil.callApp("getDirectoryListing");//dir.getDirectoryListing();
			JsUtil.callBack = function(fileList:Array):void{
				while(fileList && fileList.length >= MAX_CUSTOM_ITEMS){
					var tmpfileName:String = fileList.shift();
					JsUtil.callApp("deleteDrawFile",tmpfileName);
				}
			}
			var fileName:String = new Date().getTime() + ".txt";
			JsUtil.callApp("saveDrawFile",[fileName,result]);
			return fileName;
		}
		
		private function __onSelect(evt:Event):void
		{
			if(focusThumb != null){
				showDeleteBtn(false);
				
				focusThumb.setBorder(ThumbPane.normalBorder);
				focusThumb = null;
			}
		}
		
		internal function clearFocus():void
		{
			if(focusThumb != null){
				focusThumb.setBorder(ThumbPane.normalBorder);
				focusThumb = null;
				showDeleteBtn(false);
			}
		}
		
		public function init(bmd:BitmapData):void
		{
			if(bmd == null){
				bmd = ThumbPane.defaultBmd;
			}
			sensor.copyFrom(bmd);
		}
		
		internal function __onClick(evt:MouseEvent):void
		{
			var target:AssetPane = evt.currentTarget as AssetPane;
			
			var bmd:BitmapData = (target.getAsset() as Bitmap).bitmapData;
			
			if(sensor.isDataDirty){
				__onAddToFavorite(null);
			}
			
			sensor.copyFrom(bmd);
			
			clearFocus();
			
			if(thumbPane.isPreset(target)){
				showDeleteBtn(false);
			}else{
				showDeleteBtn(true);
				focusThumb = target;
				target.setBorder(ThumbPane.selectBorder);
			}
		}
		
		private function __onDeleteFavorite(evt:AWEvent):void
		{
			/*
			if(null == focusThumb){
				return;
			}
			
			var file:File = getCustomEmotionDir().resolvePath(focusThumb.getName());
			if(file.exists){
				file.deleteFileAsync();
			}
			
			thumbPane.removeData(focusThumb.getName());
			focusThumb.setBorder(ThumbPane.normalBorder);
			focusThumb = null;
			
			showDeleteBtn(false);
			*/
			
			if(null == focusThumb){
			return;
			}
			JsUtil.callApp("deleteDrawFile",focusThumb.getName());
			
			thumbPane.removeData(focusThumb.getName());
			focusThumb.setBorder(ThumbPane.normalBorder);
			focusThumb = null;
			
			showDeleteBtn(false);
			
			trace(this, "__onDeleteFavorite");
		}
		
		private function showDeleteBtn(value:Boolean):void
		{
			btnDelete.setVisible(value);
			btnAddToFavorite.setVisible(!value);
		}
		
		static private function genBitmapData(str:String):BitmapData
		{
			var list:Array = ApplicationManager.sharedManager().system==ApplicationManager.MAC_OS?str.split("\n"):str.split("\r\n");
			var bmd:BitmapData = new BitmapData(LightSensor.COUNT_W, LightSensor.COUNT_H, false, LightSensor.THUMBNAIL_OFF_COLOR);
			bmd.lock();
			for(var i:int=0; i< LightSensor.COUNT_H; i++){
				for (var j:int = 0; j < LightSensor.COUNT_W; j++) 
				{
					if(list[i].charAt(j) == "X"){
						bmd.setPixel(j, i, LightSensor.THUMBNAIL_ON_COLOR);
					}
				}
			}
			bmd.unlock();
			return bmd;
		}
		
		private function addEvents():void
		{
			btnLightAll.addActionListener(__onLightAll);
			btnCleartAll.addActionListener(__onClearAll);
			btnRotatePixel.addActionListener(__onRotatePixel);
			btnFlipX.addActionListener(__onFlipX);
			btnFlipY.addActionListener(__onFlipY);
			btnEraser.addActionListener(__onEraser);
			btnAddToFavorite.addActionListener(__onAddToFavorite);
			
			btnOk.addActionListener(__onOk);
			btnCancel.addActionListener(__onCanel);
			btnDelete.addActionListener(__onDeleteFavorite);
		}
		
		private function __onAddToFavorite(evt:AWEvent):void
		{
			sensor.isDataDirty = false;
			if(sensor.isEmpty()){
				return;
			}
			if(thumbPane.getIconCount() >= MAX_CUSTOM_ITEMS){
//				JOptionPane.showMessageDialog("notice", "favorite is too much,please delete some first.");
				return;
			}
			var bmd:BitmapData = sensor.getBitmapData();
			var fileName:String = saveToFile(bmd);
			
			thumbPane.addThumb(fileName, bmd, false);
		}
		
		private function __onOk(evt:AWEvent):void
		{
			dispatchEvent(new Event(Event.COMPLETE));
			hide();
		}
		
		private function __onCanel(evt:AWEvent):void
		{
			hide();
		}
		
		override public function show():void
		{
			Translator.regChangeEvt(__onLangChanged);
			pack();
			AsWingUtils.centerLocate(this);
			super.show();
			PopupUtil.disableRightMouseEvent();
		}
		
		public function getValue():Array
		{
			return sensor.getValueArray();
		}
		
		public function getBitmapData():BitmapData
		{
			return sensor.getBitmapData();
		}
		
		private function __onLightAll(evt:AWEvent):void
		{
			sensor.setValueAll(true);
		}
		
		private function __onEraser(evt:AWEvent):void
		{
			sensor.eraserMode = !sensor.eraserMode;
			Mouse.cursor = sensor.eraserMode ? MouseCursor.HAND : MouseCursor.AUTO;
			var bgColor:ASColor = btnEraser.isSelected() ? new ASColor(0x17d7ac): null;
			btnEraser.setBackground(bgColor);
		}
		
		private function __onRotatePixel(evt:AWEvent):void
		{
			sensor.rotatePixel();
		}
		
		private function __onFlipX(evt:AWEvent):void
		{
			sensor.flipX();
		}
		
		private function __onFlipY(evt:AWEvent):void
		{
			sensor.flipY();
		}
		
		private function __onClearAll(evt:AWEvent):void
		{
			sensor.setValueAll(false);
		}
		
		override public function hide():void
		{
			if(btnEraser.isSelected()){
				btnEraser.setSelected(false);
				__onEraser(null);
			}
			super.hide();
			Translator.unregChangeEvt(__onLangChanged);
			PopupUtil.enableRightMouseEvent();
		}
		
		private function __onLangChanged(evt:Event=null):void
		{
			setTitle(Translator.map("Face Panel"));
			
			btnLightAll.setText(Translator.map("Light All"));
			btnCleartAll.setText(Translator.map("Clear All"));
			btnDelete.setText(Translator.map("Remove Emotion"));
			btnAddToFavorite.setText(Translator.map("Add To Favourite"));
			
			btnOk.setText(Translator.map("Complete"));
			btnCancel.setText(Translator.map("Cancel"));
		}
		
		static private function setBtnStyle(btn:JButton):void
		{
			btn.setFont(new ASFont("微软雅黑",14));
			btn.setForeground(new ASColor(0x424242));
		}
		
		static private function setIconBtnStyle(btn:AbstractButton):void
		{
			btn.setPreferredSize(new IntDimension(50, 36));
		}
		
		static public function createEmpty(w:int, h:int):Component
		{
			var result:Component = new Component();
			result.setSizeWH(w, h);
			return result;
		}
	}
}