package cc.makeblock.mbot.uiwidgets.lightSetter
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filesystem.File;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	
	import cc.makeblock.mbot.util.ButtonFactory;
	import cc.makeblock.mbot.util.PopupUtil;
	import cc.makeblock.util.FileUtil;
	
	import org.aswing.ASColor;
	import org.aswing.AsWingConstants;
	import org.aswing.AsWingUtils;
	import org.aswing.AssetPane;
	import org.aswing.Border;
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
	
	import translation.Translator;
	
	public class LightSetterFrame extends JFrame
	{
		static public const MAX_CUSTOM_ITEMS:int = 9;
		
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
			super(null, "Face Palate", true);
			setResizable(false);
			defaultCloseOperation = HIDE_ON_CLOSE;
			
			sensor = new LightSensor();
			sensor.addEventListener(Event.SELECT, __onSelect);
			
			btnLightAll = ButtonFactory.createBtn("light all");
			btnCleartAll = ButtonFactory.createBtn("clear all");
//			btnRotateView = ButtonFactory.createBtn("rotate view");
			btnRotatePixel = ButtonFactory.createBtn("rotate pixel");
			btnFlipX = ButtonFactory.createBtn("flip x");
			btnFlipY = ButtonFactory.createBtn("flip y");
			btnEraser = new JToggleButton("eraser");
			btnEraser.setHorizontalAlignment(AsWingConstants.LEFT);
			btnDelete = ButtonFactory.createBtn("remove emotion");
			btnDelete.setEnabled(false);
			
//			centerPanel = new JPanel();
			var centerPanel:Component = new AssetPane(sensor);
			centerPanel.setBorder(
				new LineBorder(
					new EmptyBorder(null, new Insets(10,10,10,10)),
					new ASColor(0xd0d1d2)
				)
			);
			var wrapper:JPanel = new JPanel(new CenterLayout());
			wrapper.append(centerPanel);
			
//			centerPanel.append(assetPane);
			
			var btnPanel:JPanel = new JPanel(new SoftBoxLayout(SoftBoxLayout.X_AXIS, 10));
			
			var bottomBtn:JPanel = new JPanel(new SoftBoxLayout(SoftBoxLayout.X_AXIS, 5, SoftBoxLayout.CENTER));
			
			btnOk = new JButton("Complete");
			btnOk.setPreferredWidth(162);
			btnCancel = new JButton("Cancel");
			btnCancel.setPreferredWidth(162);
			btnAddToFavorite = new JButton("add to favorite");
			
			bottomBtn.append(btnAddToFavorite);
			btnPanel.append(btnCancel);
			btnPanel.append(btnOk);
			
			bottomBtn.append(btnLightAll);
			bottomBtn.append(btnCleartAll);
//			btnPanel.append(btnRotateView);
			bottomBtn.append(btnRotatePixel);
			bottomBtn.append(btnFlipX);
			bottomBtn.append(btnFlipY);
			bottomBtn.append(btnEraser);
			bottomBtn.append(btnDelete);
			
			thumbPane = new ThumbPane(this);
			thumbPane.addBtn(btnPanel);
			
//			thumbPanel = new JPanel(new SoftBoxLayout(SoftBoxLayout.X_AXIS, 4));
//			presetPanel = new JPanel(new SoftBoxLayout(SoftBoxLayout.Y_AXIS, 4));
			
			getContentPane().setLayout(new BorderLayout(4, 4));
			getContentPane().setBorder(new EmptyBorder(null, new Insets(16, 20, 16, 20)));
			getContentPane().append(wrapper, BorderLayout.CENTER);
//			getContentPane().append(btnPanel, BorderLayout.EAST);
			getContentPane().append(bottomBtn, BorderLayout.NORTH);
//			getContentPane().append(thumbPanel, BorderLayout.NORTH);
			getContentPane().append(thumbPane, BorderLayout.SOUTH);
//			getContentPane().append(presetPanel, BorderLayout.WEST);
			
			loadPresets();
			addEvents();
		}
		
		private function loadPresets():void
		{
			var file:File = File.applicationDirectory.resolvePath("assets/emotions");
			for each(var item:File in file.getDirectoryListing()){
				var str:String = FileUtil.ReadString(item);
				thumbPane.addThumb(item.name, genBitmapData(str), true);
//				appendBitmapData(presetPanel, genBitmapData(str));
			}
			file = getCustomEmotionDir();
			if(!file.exists){
				return;
			}
			for each(item in file.getDirectoryListing()){
				str = FileUtil.ReadString(item);
				thumbPane.addThumb(item.name, genBitmapData(str), false);
//				var wrapper:AssetPane = appendBitmapData(thumbPanel, genBitmapData(str));
//				wrapper.name = item.name;
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
			btnDelete.setEnabled(false);
			if(focusThumb != null){
				focusThumb.setBorder(ThumbPane.normalBorder);
				focusThumb = null;
			}
		}
		
		internal function __onClick(evt:MouseEvent):void
		{
			var target:AssetPane = evt.currentTarget as AssetPane;
			var bmd:BitmapData = (target.getAsset() as Bitmap).bitmapData;
			sensor.copyFrom(bmd);
			
//			btnDelete.setEnabled(target.getParent() == thumbPanel);
			
			if(focusThumb != null){
				focusThumb.setBorder(ThumbPane.normalBorder);
			}
			
			focusThumb = target;
			target.setBorder(ThumbPane.selectBorder);
		}
		
		private function __onDeleteFavorite(evt:AWEvent):void
		{
//			thumbPanel.remove(focusThumb);
			//todo 删除文件
			var file:File = getCustomEmotionDir().resolvePath(focusThumb.name);
			if(file.exists){
				file.deleteFileAsync();
			}
			
			focusThumb = null;
			btnDelete.setEnabled(false);
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
//			btnRotateView.addActionListener(__onRotateView);
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
			if(sensor.isEmpty()){
				JOptionPane.showMessageDialog("notice", "image is empty.");
				return;
			}
//			if(thumbPanel.getComponentCount() >= MAX_CUSTOM_ITEMS){
//				JOptionPane.showMessageDialog("notice", "favorite is too much,please delete some first.");
//				return;
//			}
			var bmd:BitmapData = sensor.getBitmapData();
			var fileName:String = saveToFile(bmd);
			
			thumbPane.addThumb(fileName, bmd, false);
//			var wrapper:AssetPane = appendBitmapData(thumbPanel, bmd);
//			wrapper.name = fileName;
		}
		/*
		private function appendBitmapData(parent:JPanel, bmd:BitmapData):AssetPane
		{
			var pane:AssetPane = new AssetPane(LightSensor.createBmp(bmd));
			pane.setBorder(defaultBorder);
			parent.append(pane);
			pane.addEventListener(MouseEvent.CLICK, __onClick);
//			thumbPane.addThumb(bmd);
			return pane;
		}
		*/
		private function __onOk(evt:AWEvent):void
		{
			hide();
			dispatchEvent(new Event(Event.COMPLETE));
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
		/*
		private function __onRotateView(evt:AWEvent):void
		{
			sensor.rotateView();
			centerPanel.setPreferredSize(new IntDimension(sensor.width, sensor.height));
			invalidate();
			pack();
			AsWingUtils.centerLocate(this);
		}
		*/
		private function __onRotatePixel(evt:AWEvent):void
		{
			sensor.rotatePixel();
		}
		
		private function __onFlipX(evt:AWEvent):void
		{
			if(sensor.isHorizontal()){
				sensor.flipX();
			}else{
				sensor.flipY();
			}
		}
		
		private function __onFlipY(evt:AWEvent):void
		{
			if(sensor.isHorizontal()){
				sensor.flipY();
			}else{
				sensor.flipX();
			}
		}
		
		private function __onClearAll(evt:AWEvent):void
		{
			sensor.setValueAll(false);
		}
		
		override public function hide():void
		{
			super.hide();
			Translator.unregChangeEvt(__onLangChanged);
			PopupUtil.enableRightMouseEvent();
		}
		
		private function __onLangChanged(evt:Event=null):void
		{
			btnLightAll.setText(Translator.map("light all"));
			btnCleartAll.setText(Translator.map("clear all"));
			btnRotatePixel.setText(Translator.map("rotate pixel"));
			
			btnFlipX.setText(Translator.map("flip x"));
			btnFlipY.setText(Translator.map("flip y"));
			btnEraser.setText(Translator.map("eraser"));
			btnDelete.setText(Translator.map("remove emotion"));
			trace("frame lang changed");
		}
	}
}