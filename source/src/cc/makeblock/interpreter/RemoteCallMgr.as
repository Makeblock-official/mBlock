package cc.makeblock.interpreter
{
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import blockly.runtime.Thread;
	
	import extensions.ScratchExtension;
	import extensions.SerialDevice;
	import extensions.SocketManager;

	public class RemoteCallMgr
	{
		static public const Instance:RemoteCallMgr = new RemoteCallMgr();
		
		private const requestList:Array = [];
		private var timerId:uint;
		
		private var reader:PacketParser;
		
		public function RemoteCallMgr()
		{
			reader = new PacketParser(onPacketRecv);
		}
		
		public function init():void
		{
			SerialDevice.sharedDevice().dataRecvSignal.add(__onSerialRecv);
		}
		
		private function __onSerialRecv(bytes:Array):void
		{
			if(SocketManager.sharedManager().isConnected){
				
			}else{
				reader.append(bytes);
			}
		}
		
		private function onPacketRecv(value:Object=null):void
		{
			if(requestList.length <= 0){
				return;
			}
			var info:Array = requestList.shift();
			var thread:Thread = info[0];
			if(thread != null){
				if(arguments.length > 0){
					thread.push(value);
				}
				thread.resume();
			}
			clearTimeout(timerId);
			send();
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
			ext.js.call(info[1], info[2], null);
			timerId = setTimeout(onTimeout, 5000);
		}
		
		private function onTimeout():void
		{
			if(requestList.length <= 0){
				return;
			}
			var info:Array = requestList[0];
			if(info[4] > 0){
				onPacketRecv(0);
			}else{
				onPacketRecv();
			}
		}
	}
}