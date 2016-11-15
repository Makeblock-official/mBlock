package
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.system.Security;
	import flash.text.TextField;
	
	public class core extends Sprite
	{
		private var _text:TextField = new TextField;
		public function core()
		{
			this.addEventListener(Event.ADDED_TO_STAGE,onInit);
		}
		private function onInit(evt:Event):void{
			if(ExternalInterface.available){
				try{
					ExternalInterface.addCallback("openProject",openProject);
				}catch(e:*){
					_text.text = e.toString();
				}
				setTimeout(function(){
					ExternalInterface.call("sendMsg","world");
				},2000);
			}
			addChild(_text);
			_text.width = 300;
			_text.height = 300;
			_text.multiline = true;
		}
		public function openProject(url:String):void{
			_text.text = url;
		}
	}
}