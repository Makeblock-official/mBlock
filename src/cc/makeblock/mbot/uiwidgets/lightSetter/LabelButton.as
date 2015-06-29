package cc.makeblock.mbot.uiwidgets.lightSetter
{
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	internal class LabelButton extends Sprite
	{
		private var tf:TextField;
		
		public function LabelButton(text:String)
		{
			mouseChildren = false;
			tf = new TextField();
			tf.autoSize = TextFieldAutoSize.LEFT;
			tf.background = true;
			tf.backgroundColor = 0xCCCCCC;
			tf.border = true;
			addChild(tf);
			tf.text = text;
		}
		
		private function drawBg():void
		{
			var g:Graphics = graphics;
			g.clear();
			g.beginFill(0x999999);
			g.drawRect(0, 0, tf.width, tf.height);
			g.endFill();
		}
	}
}