package cc.makeblock.boards
{

	public class BlockContextMenuMgr
	{
		static public const Instance:BlockContextMenuMgr = new BlockContextMenuMgr();
		
		public var boardDefine:BoardDefine;
		
		public function BlockContextMenuMgr()
		{
			boardDefine = BoardDefineFactory.GetMBot();
		}
		
		public function show(menuName:String):void
		{
		}
	}
}