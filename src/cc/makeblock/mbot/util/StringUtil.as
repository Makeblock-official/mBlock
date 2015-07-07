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
	}
}