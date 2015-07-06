package cc.makeblock.mbot.uiwidgets.lightSetter
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.MouseEvent;
	
	import org.aswing.ASColor;
	import org.aswing.AssetIcon;
	import org.aswing.AssetPane;
	import org.aswing.Border;
	import org.aswing.BorderLayout;
	import org.aswing.CenterLayout;
	import org.aswing.GridLayout;
	import org.aswing.Insets;
	import org.aswing.JButton;
	import org.aswing.JPanel;
	import org.aswing.border.EmptyBorder;
	import org.aswing.border.LineBorder;
	import org.aswing.event.AWEvent;
	import org.aswing.geom.IntDimension;
	
	internal class ThumbPane extends JPanel
	{
		[Embed("/assets/UI/ledFace/Paging_left-normal.png")]
		static private const ARROR_LEFT_CLS:Class;
		
		[Embed("/assets/UI/ledFace/Paging_left-hover.png")]
		static private const ARROR_LEFT_OVER_CLS:Class;
		
		[Embed("/assets/UI/ledFace/Paging_left-click.png")]
		static private const ARROR_LEFT_DOWN_CLS:Class;
		
		[Embed("/assets/UI/ledFace/Paging_right-normal.png")]
		static private const ARROR_RIGHT_CLS:Class;
		
		[Embed("/assets/UI/ledFace/Paging_right-hover.png")]
		static private const ARROR_RIGHT_OVER_CLS:Class;
		
		[Embed("/assets/UI/ledFace/Paging_right-click.png")]
		static private const ARROR_RIGHT_DOWN_CLS:Class;
		
		static public const presetBorder:Border = new EmptyBorder(new LineBorder(null, new ASColor(0xf2f2f2)), new Insets(3,3,3,3));
		static public const normalBorder:Border = new EmptyBorder(new LineBorder(null, new ASColor(0xd0d1d2)), new Insets(3,3,3,3));
		static public const selectBorder:Border = new LineBorder(null, new ASColor(0xd0d1d2), 4);
		
		static internal const defaultBmd:BitmapData = new BitmapData(16, 8, false, 0xFFFFFF);
		
		static private const numW:int = 8;
		static private const numH:int = 2;
		
		private var totalPages:int = 1;
		
		private var paneList:Array = [];
		private var dataList:Array = [];
		private var currentPage:int = 1;
		
		private var btnLayer:JPanel;
		private var btnLeft:JButton;
		private var btnRight:JButton;
		
		private var frame:LightSetterFrame;
		
		public function ThumbPane(frame:LightSetterFrame)
		{
			super(new BorderLayout(10, 10));
			this.frame = frame;
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
			append(wrapper, BorderLayout.CENTER);
			
			btnLeft = new JButton(null, new AssetIcon(new ARROR_LEFT_CLS()));
			btnLeft.setPreferredSize(new IntDimension(12, 36));
			btnRight = new JButton(null, new AssetIcon(new ARROR_RIGHT_CLS()));
			btnRight.setPreferredSize(new IntDimension(12, 36));
			
			btnLeft.setRollOverIcon(new AssetIcon(new ARROR_LEFT_OVER_CLS()));
			btnLeft.setPressedIcon(new AssetIcon(new ARROR_LEFT_DOWN_CLS()));
			
			btnRight.setRollOverIcon(new AssetIcon(new ARROR_RIGHT_OVER_CLS()));
			btnRight.setPressedIcon(new AssetIcon(new ARROR_RIGHT_DOWN_CLS()));
			
			wrapper = new JPanel(new CenterLayout());
			wrapper.append(btnLeft);
			append(wrapper, BorderLayout.WEST);
			
			wrapper = new JPanel(new CenterLayout());
			wrapper.append(btnRight);
			append(wrapper, BorderLayout.EAST);
			
			btnLayer = new JPanel(new CenterLayout());
			append(btnLayer, BorderLayout.SOUTH);
			
			btnLeft.addActionListener(__onPrev);
			btnRight.addActionListener(__onNext);
			
			updatePageData();
		}
		
		private function __onPrev(evt:AWEvent):void
		{
			if(currentPage <= 1){
				return;
			}
			--currentPage;
			frame.clearFocus();
			updatePageData();
		}
		
		private function __onNext(evt:AWEvent):void
		{
			if(currentPage >= totalPages){
				return;
			}
			++currentPage;
			frame.clearFocus();
			updatePageData();
		}
		
		private function updatePageData():void
		{
			btnLeft.setEnabled(currentPage > 1);
			btnRight.setEnabled(currentPage < totalPages);
			
			for(var dy:int=0; dy<numH; dy++){
				for(var dx:int=0; dx<numW; dx++){
					var index:int = dy*numW+dx;
					var pane:AssetPane = paneList[index];
					var dataIndex:int = index + (currentPage - 1) * numW * numH;
					setData(pane, dataList[dataIndex]);
				}
			}
		}
		
		public function addBtn(btn:JPanel):void
		{
			btnLayer.append(btn);
		}
		
		public function addThumb(name:String, bmd:BitmapData, isPreset:Boolean):void
		{
			dataList.push(new DataItem(name, bmd, isPreset));
			calcTotalPages();
			updatePageData();
		}
		
		private function calcTotalPages():void
		{
			totalPages = Math.ceil(dataList.length / (numW * numH));
		}
		
		private function setData(pane:AssetPane, item:DataItem):void
		{
			if(null == item){
//				(pane.getAsset() as Bitmap).bitmapData = defaultBmd;
				pane.setVisible(false);
				pane.setBorder(normalBorder);
				return;
			}
			pane.setVisible(true);
			pane.setName(item.name);
			(pane.getAsset() as Bitmap).bitmapData = item.bmd;
			if(item.isPreset){
				pane.setBorder(presetBorder);
			}else{
				pane.setBorder(normalBorder);
			}
		}
		
		public function removeData(iconName:String):void
		{
			for(var i:int=0; i<dataList.length; ++i){
				var item:DataItem = dataList[i];
				if(item.name == iconName){
					dataList.splice(i, 1);
					break;
				}
			}
			calcTotalPages();
			updatePageData();
		}
		
		public function isPreset(pane:AssetPane):Boolean
		{
			return pane.getBorder() == presetBorder;
		}
		
		public function isEmpty(pane:AssetPane):Boolean
		{
			return (pane.getAsset() as Bitmap).bitmapData == defaultBmd;
		}
		
		public function getIconCount():int
		{
			return dataList.length;
		}
	}
}

import flash.display.BitmapData;

class DataItem
{
	public var bmd:BitmapData;
	public var name:String;
	public var isPreset:Boolean;
	
	public function DataItem(name:String, bmd:BitmapData, isPreset:Boolean)
	{
		this.name = name;
		this.bmd = bmd;
		this.isPreset = isPreset;
	}
}