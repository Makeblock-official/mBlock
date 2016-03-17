package util
{
	import flash.external.ExternalInterface;

	public class JsUtil
	{
		Init();
		static private function Init():void
		{
			if(!ExternalInterface.available)
				return;
			ExternalInterface.marshallExceptions = true;
			ExternalInterface.addCallback("responseValue", function():void{
				trace("js call me:", arguments);
			});
		}
		
		static public function Call(method:String, args:Array):void
		{
			if(ExternalInterface.available){
				args.unshift(method);
				ExternalInterface.call.apply(null, args);
			}else{
				trace("ExternalInterface is not available!");
			}
		}
		
		static public function Eval(code:String):void
		{
			Call("eval", [code]);
		}
	}
}