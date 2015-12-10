package cc.makeblock.interpreter
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import blockly.runtime.Thread;
	
	import extensions.ScratchExtension;
	import extensions.SerialDevice;

	internal class RemoteCallMgr
	{
		static private const PACKET_MIN_SIZE:int = 4;
		private const ba:ByteArray = new ByteArray();
		
		private const requestList:Array = [];
		private const recvBytes:Array = [];
		private var timerId:uint;
		
		public function RemoteCallMgr()
		{
			ba.endian = Endian.LITTLE_ENDIAN;
			SerialDevice.sharedDevice().dataRecvSignal.add(__onSerialRecv);
		}
		
		private function __onSerialRecv(bytes:Array):void
		{
			if(bytes.length <= 0){
				return;
			}
			recvBytes.push.apply(null, bytes);
			for(;;){
				if(recvBytes.length < PACKET_MIN_SIZE){
					return;
				}
				if(recvBytes[0] == 0xFF && recvBytes[1] == 0x55){
					break;
				}
				recvBytes.shift();
			}
			if(recvBytes[recvBytes.length-2] != 0xD || recvBytes[recvBytes.length-1] != 0xA){
				return;
			}
			ba.clear();
			for(var i:int=2, n:int=recvBytes.length-2; i<n; ++i){
				ba.writeByte(recvBytes[i]);
			}
			recvBytes.length = 0;
			if(ba.length > 0){
				ba.position = 0;
				switch(ba.readUnsignedByte()){
					case 0x80://button pressed
						MBlock.app.runtime.mbotButtonPressed.notify(Boolean(readValue()));
						break;
					default:
						onPacketRecv(readValue());
				}
			}else{
				onPacketRecv();
			}
			clearTimeout(timerId);
			send();
		}
		
		private function onPacketRecv(value:Object=null):void
		{
			if(requestList.length <= 0){
				return;
			}
			var info:Array = requestList.shift();
			var thread:Thread = info[0];
			if(arguments.length > 0){
				thread.push(value);
			}
			thread.resume();
		}
		
		public function call(thread:Thread, method:String, param:Array, ext:ScratchExtension):void
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
			while(requestList.length > 0){
				var info:Array = requestList.pop();
				var thread:Thread = info[0];
				thread.interrupt();
			}
		}
		
		private function readValue():*
		{
			var valueType:uint = ba.readUnsignedByte();
			switch(valueType){
				case 1:
					return ba.readUnsignedByte();
				case 2:
				case 5:
					return ba.readFloat();
				case 3:
					return ba.readShort();
				case 4:
					return ba.readUTFBytes(ba.readUnsignedByte());
			}
		}
	}
}