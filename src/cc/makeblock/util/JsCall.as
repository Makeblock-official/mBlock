package cc.makeblock.util
{
	import flash.utils.getTimer;

	public class JsCall
	{
		static private const info:Object = {};
		/**
		 * 有种场景,同时读取两个超声波的读数,请求不应该丢掉
		 */		
		static public function canCall(method:String):Boolean
		{
			/*
			if(!info.hasOwnProperty(method)){
				info[method] = getTimer();
				return true;
			}
			var now:int = getTimer();
			var prev:int = info[method];
			if(now - prev < 20){
				return false;
			}
			info[method] = now;
			*/
			return true;
		}
	}
}