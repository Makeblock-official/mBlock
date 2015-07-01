package cc.makeblock.mbot.uiwidgets.lightSetter
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.MouseEvent;
	
	import org.aswing.ASColor;
	import org.aswing.AssetPane;
	import org.aswing.Border;
	import org.aswing.CenterLayout;
	import org.aswing.FlowLayout;
	import org.aswing.GridLayout;
	import org.aswing.Insets;
	import org.aswing.JButton;
	import org.aswing.JPanel;
	import org.aswing.SoftBoxLayout;
	import org.aswing.border.EmptyBorder;
	import org.aswing.border.LineBorder;
	
	internal class ThumbPane extends JPanel
	{
		static public const presetBorder:Border = new EmptyBorder(new LineBorder(null, new ASColor(0xf2f2f2)), new Insets(3,3,3,3));
		static public const normalBorder:Border = new EmptyBorder(new LineBorder(null, new ASColor(0xd0d1d2)), new Insets(3,3,3,3));
		static public const selectBorder:Border = new LineBorder(null, new ASColor(0xd0d1d2), 4);
		
		
		static private const defaultBmd:BitmapData = new BitmapData(16, 8, false, 0xFFFFFF);
		
		static private const numW:int = 8;
		static private const numH:int = 2;
		
		static private const totalPages:int = 3;
		
		
		private var paneList:Array = [];
		private var count:int;
		private var dataList:Array = [];
		private var currentPage:int = 0;
		
		private var btnLayer:JPanel;
		
		public function ThumbPane(frame:LightSetterFrame)
		{
			super(new SoftBoxLayout(SoftBoxLayout.Y_AXIS, 10));
			var wrapper:JPanel = new JPanel(new CenterLayout());
			var dock:JPanel = new JPanel(new GridLayout(2, 8, 12, 4));
			for(var dy:int=0; dy<numH; dy++){
				for(var dx:int=0; dx<numW; dx++){
					var pane:AssetPane = new AssetPane(LightSensor.createBmp(defaultBmd));
					pane.setBorder(normalBorder);
					pane.addEventListener(MouseEvent.CLICK, frame.__onClick);
					dock.append(pane);
					paneList.push(pane);
				}
			}
			wrapper.append(dock);
			append(wrapper);
			
			btnLayer = new JPanel(new CenterLayout());
			append(btnLayer);
		}
		
		public function addBtn(btn:JPanel):void
		{
			btnLayer.append(btn);
		}
		
		public function addThumb(name:String, bmd:BitmapData, isPreset:Boolean):void
		{
			var index:int = dataList.length;
			
			var pane:AssetPane = paneList[index];
			if(isPreset){
				pane.setBorder(presetBorder);
			}else{
				pane.setBorder(normalBorder);
			}
			dataList.push(bmd);
			
			update();
		}
		
		public function update():void
		{
			for(var dy:int=0; dy<numH; dy++){
				for(var dx:int=0; dx<numW; dx++){
					var index:int = dy*numW+dx;
					var pane:AssetPane = paneList[index];
					if(index >= dataList.length){
						return;
					}
					setData(pane, dataList[index]);
				}
			}
		}
		
		private function setData(pane:AssetPane, bmd:BitmapData):void
		{
			(pane.getAsset() as Bitmap).bitmapData = bmd;
		}
	}
}