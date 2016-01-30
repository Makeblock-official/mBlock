package cc.makeblock.boards
{
	public class PortDefine
	{
		public var id:int;
		public var name:String;
		public var flag:uint;
		
		public function PortDefine()
		{
		}
		
		public function toString():String
		{
			return name;
		}
	}
}