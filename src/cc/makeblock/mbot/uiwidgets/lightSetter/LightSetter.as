package cc.makeblock.mbot.uiwidgets.lightSetter
{
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	
	internal class LightSetter extends Sprite
	{
		static public const BTN_LEFT:int = 700;
		static public const BTN_GAP:int = 10;
		
		private var sensor:LightSensor;
		private var btnList:Array = [];
		
		public function LightSetter()
		{
			sensor = new LightSensor();
			addChild(sensor);
			
			createBtn("light all", __onLightAll);
			createBtn("clear all", __onClearAll);
			createBtn("rotate view", __onRotateView);
			createBtn("rotate pixel", __onRotatePixel);
			createBtn("flip x", __onFlipX);
			createBtn("flip y", __onFlipY);
			createBtn("eraser", __onEraser);
		}
		/*
		public function getValue():ByteArray
		{
			return sensor.getValue();
		}
		*/
		private function __onLightAll(evt:MouseEvent):void
		{
			sensor.setValueAll(true);
		}
		
		private function __onEraser(evt:MouseEvent):void
		{
			sensor.eraserMode = !sensor.eraserMode;
			Mouse.cursor = sensor.eraserMode ? MouseCursor.HAND : MouseCursor.AUTO;
		}
		
		private function __onRotateView(evt:MouseEvent):void
		{
			sensor.rotateView();
		}
		
		private function __onRotatePixel(evt:MouseEvent):void
		{
			sensor.rotatePixel();
		}
		
		private function __onFlipX(evt:MouseEvent):void
		{
			if(sensor.isHorizontal()){
				sensor.flipX();
			}else{
				sensor.flipY();
			}
		}
		
		private function __onFlipY(evt:MouseEvent):void
		{
			if(sensor.isHorizontal()){
				sensor.flipY();
			}else{
				sensor.flipX();
			}
		}
		
		private function __onClearAll(evt:MouseEvent):void
		{
			sensor.setValueAll(false);
		}
		
		private function createBtn(label:String, callback:Function):void
		{
			var btn:LabelButton = new LabelButton(label);
			btn.x = BTN_LEFT;
			btn.y = btnList.length * (btn.height + BTN_GAP);
			addChild(btn);
			btn.addEventListener(MouseEvent.CLICK, callback);
			btnList.push(btn);
		}
	}
}