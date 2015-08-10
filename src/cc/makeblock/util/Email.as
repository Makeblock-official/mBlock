package cc.makeblock.util
{
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;

	public class Email
	{
		public var to:String;
		public var subject:String;
		public var body:String;
		
		public function Email(to:String, subject:String=null, body:String=null)
		{
			this.to = to;
			this.subject = subject;
			this.body = body;
		}
		
		public function send():void
		{
			var request:URLRequest = new URLRequest("mailto:" + to);
			var data:URLVariables = new URLVariables();
			if(subject != null){
				data.subject = subject;
			}
			if(body != null){
				data.body = body;
			}
			request.data = data;
			navigateToURL(request);
		}
	}
}