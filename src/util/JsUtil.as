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
			ExternalInterface.addCallback("responseValue", __responseValue);
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
		
		static private function __responseValue(...args):void
		{
			if(args.length < 2){
				RemoteCallMgr.Instance.onPacketRecv();
				return;
			}
			switch(args[0]){
				case 0x80:
					MBlock.app.runtime.mbotButtonPressed.notify(Boolean(args[1]));
					break;
				default:
					RemoteCallMgr.Instance.onPacketRecv(args[1]);
			}
		}
	}
}