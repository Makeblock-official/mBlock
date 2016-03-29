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
				if(arguments.length < 2){
					RemoteCallMgr.Instance.onPacketRecv();
					return;
				}
				switch(arguments[0]){
					case 0x80:
						MBlock.app.runtime.mbotButtonPressed.notify(Boolean(arguments[1]));
						break;
					default:
						RemoteCallMgr.Instance.onPacketRecv(arguments[1]);
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