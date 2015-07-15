package cc.makeblock.util
{
	import blocks.Block;

	public class BlockUtil
	{
		static public function ForEach(block:Block, callback:Function):void
		{
			while(block != null){
				callback(block);
				if(block.subStack1){
					ForEach(block.subStack1, callback);
				}
				if(block.subStack2){
					ForEach(block.subStack2, callback);
				}
				block = block.nextBlock;
			}
		}
	}
}