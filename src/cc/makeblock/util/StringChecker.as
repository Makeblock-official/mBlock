package cc.makeblock.util
{
	final public class StringChecker
	{
		static private const numberPattern:RegExp = /^-?\d+(.\d+)?$/;
		static private const intPattern:RegExp = /^-?\d+$/;
		
		static public function IsNumber(str:String):Boolean
		{
			return numberPattern.test(str);
		}
		
		static public function IsInt(str:String):Boolean
		{
			return intPattern.test(str);
		}
	}
}