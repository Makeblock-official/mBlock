package util
{
	import flash.net.URLRequest;
	import flash.net.navigateToURL;

	public class Clicker
	{
		public var name:String;
		public var link:String;
		public var desc:String;
		public var type:String;
		
		public function Clicker()
		{
		}
		public function click():void{
			navigateToURL(new URLRequest(link));
			MBlock.app.track("click_"+name);
			SharedObjectManager.sharedManager().setObject("click_"+name,true);
		}
		public function isShow():Boolean{
			return (!SharedObjectManager.sharedManager().available("click_"+name)&&(type=="all"||type=="banner"));
		}
	}
}