package cc.makeblock.mbot.util
{
	public class StringUtil
	{
		static public function EndWith(str:String, value:String):Boolean
		{
			if(str.length < value.length){
				return false;
			}
			return str.lastIndexOf(value) == (str.length - value.length);
		}
		
		public static function substitute(str:String, ... rest):String
		{
			if (str == null) return '';
			
			// Replace all of the parameters in the msg string.
			var len:uint = rest.length;
			var args:Array;
			if (len == 1 && rest[0] is Array)
			{
				args = rest[0] as Array;
				len = args.length;
			}
			else
			{
				args = rest;
			}
			
			for (var i:int = 0; i < len; i++)
			{
				str = str.replace(new RegExp("\\{"+i+"\\}", "g"), args[i]);
			}
			
			return str;
		}
	}
}