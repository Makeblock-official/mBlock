package cc.makeblock.mbot.uiwidgets.lightSetter
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	
	import cc.makeblock.mbot.util.PopupUtil;
	import cc.makeblock.util.FileUtil;
	
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
	import org.aswing.JFrame;
	import org.aswing.JOptionPane;
	import org.aswing.JPanel;
	import org.aswing.JToggleButton;
	import org.aswing.SoftBoxLayout;
	import org.aswing.border.EmptyBorder;
	import org.aswing.border.LineBorder;
	import org.aswing.event.AWEvent;
	import org.aswing.geom.IntDimension;
	
	import translation.Translator;
	
	public class LightSetterFrame extends JFrame
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
			setResizable(false);
			defaultCloseOperation = HIDE_ON_CLOSE;
			
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
			btnAddToFavorite = new JButton("add to favorite");
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
			var file:File = File.applicationDirectory.resolvePath("assets/emotions");
			for each(var item:File in file.getDirectoryListing()){
				var str:String = FileUtil.ReadString(item);
				thumbPane.addThumb(item.name, genBitmapData(str), true);
			}
			file = getCustomEmotionDir();
			if(!file.exists){
				return;
			}
			for each(item in file.getDirectoryListing()){
				str = FileUtil.ReadString(item);
				thumbPane.addThumb(item.name, genBitmapData(str), false);
			}
		}
		
		private function getCustomEmotionDir():File
		{
			return File.documentsDirectory.resolvePath("mBlock/emotions");
		}
		
		private function saveToFile(bmd:BitmapData):String
		{
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
			var dir:File = getCustomEmotionDir();
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
		}
		
		private function showDeleteBtn(value:Boolean):void
		{
			btnDelete.setVisible(value);
			btnAddToFavorite.setVisible(!value);
		}
		
		static private function genBitmapData(str:String):BitmapData
		{
			var list:Array = str.split("\r\n");
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
				JOptionPane.showMessageDialog("notice", "image is empty.");
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
			btnLightAll.setText(Translator.map("Light All"));
			btnCleartAll.setText(Translator.map("Clear All"));
			btnDelete.setText(Translator.map("Remove Emotion"));
			btnAddToFavorite.setText(Translator.map("Add to Favourite"));
		}
		
		static private function setBtnStyle(btn:JButton):void
		{
			btn.setFont(new ASFont("Arial",16));
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