package cc.makeblock.interpreter
{
	import blockly.runtime.Thread;
	
	import blocks.Block;
	
	import scratch.ScratchObj;
	import scratch.ScratchSprite;

	internal class ThreadUserData
	{
		static public function getScratchObj(thread:Thread):ScratchObj
		{
			return (thread.userData as ThreadUserData).target;
		}
		
		static public function getScratchSprite(thread:Thread):ScratchSprite
		{
			return getScratchObj(thread) as ScratchSprite;
		}
		
		public var target:ScratchObj;
		public var block:Block;
		
		public function ThreadUserData(target:ScratchObj, block:Block)
		{
			this.target = target;
			this.block = block;
		}
	}
}