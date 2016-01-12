package cc.makeblock.interpreter
{
	import flash.utils.Dictionary;
	
	import blockly.runtime.Interpreter;
	import blockly.runtime.Thread;
	
	import blocks.Block;
	
	import scratch.ScratchObj;
	
	public class BlockInterpreter
	{
		static public const Instance:BlockInterpreter = new BlockInterpreter();
		
		private var converter:BlockJsonPrinter;
		private var realInterpreter:Interpreter;
		private const threadDict:Object = new Dictionary(true);
		
		public function BlockInterpreter()
		{
			Thread.EXEC_TIME = 25;
			realInterpreter = new Interpreter(new ArduinoFunctionProvider());
			converter = new BlockJsonPrinter();
		}
		
		public function execute(block:Block, targetObj:ScratchObj):Thread
		{
			var funcList:Array = targetObj.procedureDefinitions();
			var blockList:Array = [];
			for each(var funcBlock:Block in funcList){
				blockList.push.apply(null, converter.printBlockList(funcBlock));
			}
			
			blockList.push.apply(null, converter.printBlockList(block));
			var thread:Thread = realInterpreter.execute(blockList);
			thread.userData = targetObj;
			threadDict[thread] = block;
			return thread;
		}
		
		public function stopAllThreads():void
		{
			realInterpreter.stopAllThreads();
		}
		
		public function hasTheadsRunning():Boolean
		{
			return realInterpreter.getThreadCount() > 0;
		}
		/*
		public function stopThreadByBlock(block:Block):void
		{
			for(var t:* in threadDict){
				if(threadDict[t] == block){
					t.interrupt();
				}
			}
		}
		*/
		public function isRunning(block:Block, targetObj:ScratchObj):Boolean
		{
			var list:Vector.<Thread> = realInterpreter.getCopyOfThreadList();
			for each(var t:Thread in list){
				if(threadDict[t] == block && t.userData == targetObj){
					return true;
				}
			}
			return false;
		}
		public function stopThread(block:Block, targetObj:ScratchObj):void
		{
			var list:Vector.<Thread> = realInterpreter.getCopyOfThreadList();
			for each(var t:Thread in list){
				if(threadDict[t] == block && t.userData == targetObj){
					t.interrupt();
					delete threadDict[t];
				}
			}
		}
		
		public function stopObjAllThreads(obj:ScratchObj):void
		{
			if(null == obj){
				return;
			}
			var threadList:Vector.<Thread> = realInterpreter.getCopyOfThreadList();
			for(var i:int=threadList.length-1; i>=0; --i){
				var thread:Thread = threadList[i];
				if(thread.userData === obj){
					thread.interrupt();
				}
			}
		}
		
		public function stopObjOtherThreads(t:Thread):void
		{
			if(null == t.userData){
				return;
			}
			var threadList:Vector.<Thread> = realInterpreter.getCopyOfThreadList();
			for(var i:int=threadList.length-1; i>=0; --i){
				var thread:Thread = threadList[i];
				if(t != thread && thread.userData === t.userData){
					thread.interrupt();
				}
			}
		}
	}
}