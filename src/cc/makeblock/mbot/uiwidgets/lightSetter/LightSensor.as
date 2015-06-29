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
		static public const THUMBNAIL_ON_COLOR:uint = 0x00ABFD;
		static public const THUMBNAIL_OFF_COLOR:uint = 0xFFFFFF;
		
		static public const COUNT_W:int = 16;
		static public const COUNT_H:int = 8;
		
		static public const PANEL_W:int = 630;
		static public const PANEL_H:int = 310;
		
		static public const GAP:int = 10;
		
		private var lightDict:Array;
		private var direction:int;
		
		public var eraserMode:Boolean;
		
		public function LightSensor()
		{
			init();
			drawBg();
			addEventListener(MouseEvent.MOUSE_DOWN, __onMouseDown);
			addEventListener(MouseEvent.CLICK, __onClick);
		}
		
		private function drawBg():void
		{
			var g:Graphics = graphics;
			g.beginFill(0, 0);
			g.drawRect(0, 0, width, height);
			g.endFill();
		}
		
		private function __onClick(evt:MouseEvent):void
		{
			if(evt.target != this){
				var light:LightPoint = evt.target as LightPoint;
				light.toggle();
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
					light.x = i * (light.width + GAP);
					light.y = j * (light.height + GAP);
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
		
		public function isHorizontal():Boolean
		{
			return direction % 2 == 0;
		}
		
		public function rotateView():void
		{
			direction = (direction + 1) % 4;
			
			switch(direction){
				case 0:
					rotation = 0;
					x = 0;
					y = 0;
					break;
				case 1:
					rotation = 90;
					x = PANEL_H;
					y = 0;
					break;
				case 2:
					rotation = 180;
					x = PANEL_W;
					y = PANEL_H;
					break;
				case 3:
					rotation = -90;
					x = 0;
					y = PANEL_W;
					break;
			}
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
					}
				}
			}
		}
		
		static public const BMP_SCALE:Number = 2;
		
		static public function createBmp(bmd:BitmapData):Bitmap
		{
			var bmp:Bitmap = new Bitmap(bmd);
			bmp.scaleX = bmp.scaleY = BMP_SCALE;
			return bmp;
		}
		
		override public function get width():Number
		{
			if(direction % 2 == 0){
				return PANEL_W;
			}
			return PANEL_H;
		}
		
		override public function get height():Number
		{
			if(direction % 2 == 0){
				return PANEL_H;
			}
			return PANEL_W;
		}
	}
}