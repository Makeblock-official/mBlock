package interpreter
{
	import blocks.Block;

	internal class StackFrame
	{
		internal var block:Block;
		private var isLoop:Boolean;
		private var firstTime:Boolean;
		private var tmp:int;
		private var args:Array;
		
		private var thread:Thread;
		
		public function StackFrame(thread:Thread)
		{
			this.thread = thread;
		}
		
		public function save():void
		{
//			block 		= thread.block;
			isLoop 		= thread.isLoop;
			firstTime 	= thread.firstTime;
			tmp 		= thread.tmp;
			args 		= thread.args;
		}
		
		public function restore():void
		{
//			thread.block		= block;
			thread.isLoop		= isLoop;
			thread.firstTime	= firstTime;
			thread.tmp			= tmp;
			thread.args			= args;
		}
	}
}