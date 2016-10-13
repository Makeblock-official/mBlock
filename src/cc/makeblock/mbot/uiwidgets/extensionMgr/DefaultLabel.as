package cc.makeblock.mbot.uiwidgets.extensionMgr
{
	import flash.text.TextField;
	
	import org.aswing.Component;


	public class DefaultLabel extends Component
	{
		public var htmlText:TextField;
		private var currWid:Number=150;
		private var currHeig:Number=40;
		public function DefaultLabel(multiline:Boolean = true,wordWrap:Boolean = true)
		{
			htmlText = new TextField();
			htmlText.multiline = multiline;
			htmlText.wordWrap = wordWrap;
			htmlText.width = 120;
			htmlText.width = currWid;
			htmlText.height = currHeig;
			this.addChild(htmlText);
		}
		
		public function setLabel(str:String):void
		{
			htmlText.htmlText+=str;
			
			htmlText.height = htmlText.textHeight+5;
			currHeig = htmlText.height;
			//trace("设置文字")
		}
		public function getText():String
		{
			return htmlText.getLineText(0);
		}
		public function clearText():void
		{
			htmlText.htmlText="";
		}
	}
}