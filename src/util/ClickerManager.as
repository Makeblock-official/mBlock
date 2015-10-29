package util
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import util.JSON;
	public class ClickerManager
	{
		private static var _instance:ClickerManager;
		private var _objs:Object;
		private var _list:Array;
		public function ClickerManager()
		{
		}
		public static function sharedManager():ClickerManager{
			if(_instance==null){
				_instance = new ClickerManager;
			}
			return _instance;
		}
		public function update():void{
			var urlloader:URLLoader = new URLLoader;
			urlloader.addEventListener(Event.COMPLETE,onComplete);
			urlloader.addEventListener(IOErrorEvent.IO_ERROR,onError);
			urlloader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,onError);
			urlloader.load(new URLRequest("http://download.makeblock.cc/mblock/resources/click"+(ApplicationManager.sharedManager().isCatVersion?"_myh":"")+".txt?time="+Math.floor(new Date().time/100000)));
		}
		private function onComplete(evt:Event):void{
			try{
				_objs = util.JSON.parse(evt.target.data);
				var list:Array = _objs.list;
				_list = [];
				for(var i:uint=0;i<list.length;i++){
					var clicker:Clicker = new Clicker;
					clicker.name = list[i].name;
					clicker.link = list[i].link;
					clicker.desc = list[i].desc;
					clicker.type = list[i].type;
					_list.push(clicker);
				}
				MBlock.app.topBarPart.updateClicker();
			}catch(err:*){
				trace(err);
			}
		}
		private function onError(evt:*):void{
			
		}
		public function get list():Array{
			return _list;
		}
	}
}