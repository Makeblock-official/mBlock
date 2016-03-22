package util
{
	import flash.external.ExternalInterface;
	
	import cc.makeblock.interpreter.RemoteCallMgr;

	public class JsUtil
	{
		Init();
		static private function Init():void
		{
			if(!ExternalInterface.available)
				return;
			ExternalInterface.marshallExceptions = true;
			ExternalInterface.addCallback("responseValue", function():void{
				if(arguments.length > 0){
					RemoteCallMgr.Instance.onPacketRecv(arguments[0]);
				}else{
					RemoteCallMgr.Instance.onPacketRecv();
				}
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