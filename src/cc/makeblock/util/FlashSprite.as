package cc.makeblock.util
{
	import com.greensock.TweenLite;
	import com.greensock.easing.Cubic;
	
	import flash.display.Shape;
	import flash.geom.Rectangle;
	
	import scratch.ScratchSprite;
	
	public class FlashSprite extends Shape
	{
		public function FlashSprite(){}
		
		public function flash(spr:ScratchSprite):void
		{
			var r:Rectangle = spr.getVisibleBounds(this);
			graphics.lineStyle(3, CSS.overColor, 1, true);
			graphics.beginFill(0x808080);
			graphics.drawRoundRect(0, 0, r.width, r.height, 12, 12);
			x = r.x;
			y = r.y;
			MBlock.app.addChild(this);
			TweenLite.to(this, 0.5, {"alpha":0, "ease":Cubic.easeOut, "onComplete":removeSelf});
		}
		
		private function removeSelf():void
		{
			if (parent){
				parent.removeChild(this);
			}
		} 
	}
}