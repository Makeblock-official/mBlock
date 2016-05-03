package blockly.runtime
{
	import flash.display.Shape;
	import flash.events.Event;
	import flash.utils.getTimer;

	internal class VirtualMachine
	{
		private var instructionExector:InstructionExector;
		private const threadList:Vector.<Thread> = new Vector.<Thread>();
		private const timer:Shape = new Shape();
		
		public function VirtualMachine(functionProvider:FunctionProvider)
		{
			instructionExector = new InstructionExector(functionProvider);
			timer.addEventListener(Event.ENTER_FRAME, onUpdateThreads);
		}
		
		public function getThreadCount():uint
		{
			return threadList.length;
		}
		
		public function getCopyOfThreadList():Vector.<Thread>
		{
			return threadList.slice();
		}
		
		public function startThread(thread:Thread):void
		{
			if(threadList.indexOf(thread) < 0){
				threadList.push(thread);
			}
		}
		
		public function stopAllThreads():void
		{
			for each(var thread:Thread in threadList){
				thread.interrupt();
			}
		}
		
		private function notifyFrameBeginEvent():void
		{
			for each(var thread:Thread in threadList){
				thread.onFrameBegin();
			}
		}
		
		private function onUpdateThreads(evt:Event):void
		{
			notifyFrameBeginEvent();
			var endTime:int = getTimer() + Thread.EXEC_TIME;
			while(updateThreads() && getTimer() < endTime);
		}
		
		private function updateThreads():Boolean
		{
			var hasActiveThread:Boolean = false;
			var needRedraw:Boolean = false;
			var threadCount:int = threadList.length;
			for(var index:int=0; index<threadCount; ++index){
				var thread:Thread = threadList[index];
				for(;;){
					if(thread.isFinish()){
						threadList.splice(index, 1);
						thread.notifyFinish();
						--threadCount;
						--index;
						break;
					}
					if(thread.isSuspend()){
						thread.updateSuspendState();
						break;
					}
					if(thread.execNextCode(instructionExector)){
						if(thread.needRedraw()){
							needRedraw = true;
						}else{
							hasActiveThread = true;
						}
						break;
					}
				}
			}
			return !needRedraw && hasActiveThread;
		}
	}
}