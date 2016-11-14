package cc.makeblock.interpreter
{
	import blockly.runtime.Interpreter;
	import blockly.runtime.Thread;
	
	import blocks.Block;
	
	import scratch.ScratchObj;
	
	import util.JsUtil;
	
	public class BlockInterpreter
	{
		static public const Instance:BlockInterpreter = new BlockInterpreter();
		
		private var converter:BlockJsonPrinter;
		private var realInterpreter:Interpreter;
		
		private var waitList:Array = [];
		
		public function BlockInterpreter()
		{
			Thread.EXEC_TIME = 25;
			realInterpreter = new Interpreter(new ArduinoFunctionProvider());
			converter = new BlockJsonPrinter();
		}
		
		public function onReadyToRun():void
		{
			if(!JsUtil.readyToRun()){
				return;
			}
			while(waitList.length > 0){
				execute.apply(null, waitList.shift());
			}
		}
		
		public function execute(block:Block, targetObj:ScratchObj):Thread
		{
			var thread:Thread;
			if(!JsUtil.readyToRun()){
				waitList.push(arguments);
				thread = realInterpreter.executeAssembly([]);
				thread.userData = new ThreadUserData(targetObj, block);
				return thread;
			}
			
			var funcList:Array = targetObj.procedureDefinitions();
			var blockList:Array = [];
			for each(var funcBlock:Block in funcList){
				blockList.push.apply(null, converter.printBlockList(funcBlock));
			}
			
			blockList.push.apply(null, converter.printBlockList(block));
//			trace("begin==================");
//			trace(JSON.stringify(blockList));
//			var codeList:Array = realInterpreter.compile(blockList);
//			trace(codeList.join("\n"));
//			trace("end==================");
			thread = realInterpreter.execute(blockList);
			thread.userData = new ThreadUserData(targetObj, block);
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
				var userData:ThreadUserData = t.userData;
				if(userData.block == block && userData.target == targetObj){
					return true;
				}
			}
			return false;
		}
		public function stopThread(block:Block, targetObj:ScratchObj):void
		{
			var list:Vector.<Thread> = realInterpreter.getCopyOfThreadList();
			for each(var t:Thread in list){
				var userData:ThreadUserData = t.userData;
				if(userData.block == block && userData.target == targetObj){
					t.interrupt();
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
				if(ThreadUserData.getScratchObj(thread) === obj){
					thread.interrupt();
				}
			}
		}
		
		public function stopObjOtherThreads(t:Thread):void
		{
			var target:ScratchObj = ThreadUserData.getScratchObj(t);
			var threadList:Vector.<Thread> = realInterpreter.getCopyOfThreadList();
			for(var i:int=threadList.length-1; i>=0; --i){
				var thread:Thread = threadList[i];
				if(t != thread && ThreadUserData.getScratchObj(thread) === target){
					thread.interrupt();
				}
			}
		}
	}
}