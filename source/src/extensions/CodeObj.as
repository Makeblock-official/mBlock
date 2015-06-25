package extensions
{
	public class CodeObj
	{
		public var type:String = "code";
		public var code:String = "";
		public function CodeObj(c:String="")
		{
			code = c;
		}
		public function toString():String {
			return code
		}
	}
}