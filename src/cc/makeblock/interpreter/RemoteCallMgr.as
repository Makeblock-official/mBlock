package cc.makeblock.interpreter
{
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import blockly.runtime.Thread;
	
	import extensions.ScratchExtension;
//	import extensions.SerialDevice;
//	import extensions.SocketManager;

	public class RemoteCallMgr
	{
		static public const Instance:RemoteCallMgr = new RemoteCallMgr();
		
		private const requestList:Array = [];
		private var timerId:uint;
		private var reader:PacketParser;
		private var oldValue:Object=0;
		public function RemoteCallMgr()
		{
			reader = new PacketParser(onPacketRecv);
		}
		public function init():void
		{
			//TODO: huzige: 需要重新调整，用了Air Runtime不支持目前的flash环境
//			SerialDevice.sharedDevice().dataRecvSignal.add(__onSerialRecv);
		}
	
		//TODO: huzige: 需要重新调整，用了Air Runtime不支持目前的flash环境
		
		public function interruptThread():void
		{
			if(requestList.length <= 0){
				return;
			}
			var info:Array = requestList.shift();
			var thread:Thread = info[0];
			thread.interrupt();
			clearTimeout(timerId);
			send();
		}/*
		private function __onSerialRecv(bytes:Array):void
		{
			if(SocketManager.sharedManager().isConnected){
			}else{
					reader.append(bytes);
			}
		}
		*/

		public function onPacketRecv(value:Object=null):void
		{
			if(requestList.length <= 0){
				return;
			}
			var info:Array = requestList.shift();
			var thread:Thread = info[0];
			if(thread != null){
				if(info[4] > 0){
					if(arguments.length > 0){
						thread.push(value);
					}else{
						thread.push(0);
					}
				}
				thread.resume();
			}
			clearTimeout(timerId);
			send();
			oldValue = value||oldValue;
		}
		
		public function call(thread:Thread, method:String, param:Array, ext:ScratchExtension, retCount:int):void
		{
			var needSend:Boolean = (0 == requestList.length);
			requestList.push(arguments);
			if(needSend){
				send();
			}
		}
		
		private function send():void
		{
			if(requestList.length <= 0){
				return;
			}
			var info:Array = requestList[0];
			var ext:ScratchExtension = info[3];
			ext.js.call(info[1], info[2], ext);
			if(info[1]=="runBuzzer")
			{
				timerId = setTimeout(onTimeout, 5000);
			}
			else
			{
				timerId = setTimeout(onTimeout, 500);
			}
			
		}
		
		private function onTimeout():void
		{
			if(requestList.length <= 0){
				return;
			}
			var info:Array = requestList[0];
			if(info[4] > 0){
				onPacketRecv(oldValue);
			}else{
				onPacketRecv();
			}
		}
	}
}