package cc.makeblock.mbot.uiwidgets.lightSetter
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.ByteArray;
	
	public class LightSensor extends Sprite
	{
		[Embed(source="/assets/UI/ledFace/dash_line-horizental.png")]
		static private const DASH_W:Class;
		
		[Embed(source="/assets/UI/ledFace/dash_line-vertical.png")]
		static private const DASH_H:Class;
		
		
		static public const THUMBNAIL_ON_COLOR:uint = 0x00ABFD;
		static public const THUMBNAIL_OFF_COLOR:uint = 0xFFFFFF;
		
		static public const COUNT_W:int = 16;
		static public const COUNT_H:int = 8;
		
		static public const GAP_X:int = 10;
		static public const GAP_Y:int = 15;
		
		static public const OFFSET_X:int = 10;
		static public const OFFSET_Y:int = 10;
		
		private var lightDict:Array;
		private var direction:int;
		
		public var eraserMode:Boolean;
		public var isDataDirty:Boolean;
		
		public function LightSensor()
		{
			init();
			drawBg();
			addEventListener(MouseEvent.MOUSE_DOWN, __onMouseDown);
			addEventListener(MouseEvent.CLICK, __onClick);
		}
		
		private function drawBg():void
		{
			var w:int = width+OFFSET_X*2;
			var h:int = height+OFFSET_Y*2;
			
			var g:Graphics = graphics;
			g.beginFill(0, 0);
			g.drawRect(0, 0, w, h);
			g.endFill();
			
			var pic:Bitmap = new DASH_W();
			pic.y = 0.5 * (h - pic.height);
			addChild(pic);
			
			pic = new DASH_H();
			pic.x = 0.5 * (w - pic.width);
			addChild(pic);
		}
		
		private function __onClick(evt:MouseEvent):void
		{
			if(evt.target != this){
				var light:LightPoint = evt.target as LightPoint;
				if(!eraserMode || light.isOn){
					light.toggle();
					notifyEvt();
					
				}
			}
		}
		
		private function notifyEvt():void
		{
			if(!isDataDirty){
				isDataDirty = true;
				dispatchEvent(new Event(Event.SELECT));
			}
		}
		
		private function __onMouseDown(evt:MouseEvent):void
		{
			stage.addEventListener(MouseEvent.MOUSE_MOVE, __onMouseMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, __onMouseUp);
		}
		
		private function __onMouseUp(evt:MouseEvent):void
		{
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, __onMouseMove);
			stage.removeEventListener(MouseEvent.MOUSE_UP, __onMouseUp);
		}
		
		private function __onMouseMove(evt:MouseEvent):void
		{
			for(var i:int=0; i < COUNT_W; ++i){
				for(var j:int=0; j < COUNT_H; ++j) {
					var light:LightPoint = getLightAt(i, j);
					if(eraserMode == light.isOn && light.hitTestPoint(evt.stageX, evt.stageY)){
						light.toggle();
						notifyEvt();
					}
				}
			}
		}
		
		private function init():void
		{
			lightDict = [];
			for(var i:int=0; i < COUNT_W; ++i){
				lightDict[i] = [];
				for(var j:int=0; j < COUNT_H; ++j){
					var light:LightPoint = new LightPoint();
					light.px = i;
					light.py = j;
					light.x = i * (light.width + GAP_X) + OFFSET_X;
					light.y = j * (light.height + GAP_Y) + OFFSET_Y;
					addChild(light);
					lightDict[i][j] = light;
				}
			}
		}
		
		public function isEmpty():Boolean
		{
			for(var i:int=0; i < COUNT_W; ++i){
				for(var j:int=0; j < COUNT_H; ++j) {
					var light:LightPoint = getLightAt(i, j);
					if(light.isOn){
						return false;
					}
				}
			}
			return true;
		}
		
		public function copyFrom(source:BitmapData):void
		{
			for(var i:int=0; i < COUNT_W; ++i){
				for(var j:int=0; j < COUNT_H; ++j) {
					var light:LightPoint = getLightAt(i, j);
					if(light.isOn == (source.getPixel(i, j) == THUMBNAIL_OFF_COLOR)){
						light.toggle();
					}
				}
			}
		}
		
		/**
		 * 颜色反转,亮的变暗,暗的变亮
		 */		
		public function revert():void
		{
			for(var i:int=0; i < COUNT_W; ++i){
				for(var j:int=0; j < COUNT_H; ++j) {
					getLightAt(i, j).toggle();
				}
			}
		}
		
		public function getValueArray():Array
		{
			var result:Array = [];
			for(var i:int=0; i < COUNT_W; ++i){
				var key:int = 0;
				for(var j:int=0; j < COUNT_H; ++j) {
					var light:LightPoint = getLightAt(i, j);
					if(light.isOn){
						key |= 1 << j;
					}
				}
				result.push(key);
			}
			return result.reverse();
		}
		
		private function getValue():ByteArray
		{
			var result:ByteArray = new ByteArray();
			
			for(var i:int=0; i < COUNT_W; ++i){
				for(var j:int=0; j < COUNT_H; ++j) {
					var light:LightPoint = getLightAt(i, j);
					if(light.isOn){
						result[i] |= 1 << j;
					}
				}
			}
			return result;
		}
		
		public function getBitmapData():BitmapData
		{
			var bmd:BitmapData = new BitmapData(COUNT_W, COUNT_H, false, THUMBNAIL_OFF_COLOR);
			
			bmd.lock();
			
			for(var i:int=0; i < COUNT_W; ++i){
				for(var j:int=0; j < COUNT_H; ++j) {
					var light:LightPoint = getLightAt(i, j);
					if(light.isOn){
						bmd.setPixel(i, j, THUMBNAIL_ON_COLOR);
					}
				}
			}
			
			bmd.unlock();
			
			return bmd;
		}
		
		public function getLightAt(px:int, py:int):LightPoint
		{
			return lightDict[px][py];
		}
		
		public function rotatePixel():void
		{
			var bytes:ByteArray = getValue();
			
			for(var i:int=0; i < COUNT_W; ++i){
				for(var j:int=0; j < COUNT_H; ++j) {
					var light:LightPoint = getLightAt(i, j);
					if(getValueAt(bytes, COUNT_W - 1 - i, COUNT_H - 1 - j)){
						light.setOn();
					}else{
						light.setOff();
					}
				}
			}
		}
		
		
		public function flipX():void
		{
			var bytes:ByteArray = getValue();
			
			for(var i:int=0; i < COUNT_W; ++i){
				for(var j:int=0; j < COUNT_H; ++j) {
					var light:LightPoint = getLightAt(i, j);
					if(getValueAt(bytes, COUNT_W - 1 - i, j)){
						light.setOn();
					}else{
						light.setOff();
					}
				}
			}
		}
		
		public function flipY():void
		{
			var bytes:ByteArray = getValue();
			
			for(var i:int=0; i < COUNT_W; ++i){
				for(var j:int=0; j < COUNT_H; ++j) {
					var light:LightPoint = getLightAt(i, j);
					if(getValueAt(bytes, i, COUNT_H - 1 - j)){
						light.setOn();
					}else{
						light.setOff();
					}
				}
			}
		}
		
		static private function getValueAt(bytes:ByteArray, px:int, py:int):Boolean
		{
			return 0 != (bytes[px] & (1 << py));
		}
		
		public function setValueAll(value:Boolean):void
		{
			for(var i:int=0; i < COUNT_W; ++i){
				for(var j:int=0; j < COUNT_H; ++j) {
					var light:LightPoint = getLightAt(i, j);
					if(light.isOn != value){
						light.toggle();
						notifyEvt();
					}
				}
			}
		}
		
		static public const BMP_SCALE:Number = 4;
		static public const BMP_ICON_SCALE:Number = 2;
		
		static public function createBmp(bmd:BitmapData):Bitmap
		{
			var bmp:Bitmap = new Bitmap(bmd);
			bmp.scaleX = bmp.scaleY = BMP_SCALE;
			return bmp;
		}
	}
}