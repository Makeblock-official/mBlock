package cc.makeblock.interpreter
{
	import flash.utils.ByteArray;
	
	import blockly.runtime.Thread;
	
	import blocks.Block;
	
	import extensions.SocketManager;
	
	import scratch.ScratchObj;

	internal class NetExtension
	{
		private var recvMsgList:Array = [];
		private var parser:PacketParser;
		
		public function NetExtension()
		{
			parser = new PacketParser(onRecvValue);
			SocketManager.sharedManager().dataRecvSignal.add(__onRecvData);
		}
		
		private function onRecvValue(value:String):void
		{
			value = value.replace(/^\s+|\s+$/g, "");
			recvMsgList.push(value);
			
			MBlock.app.runtime.allStacksAndOwnersDo(function(stack:Block, target:ScratchObj):void{
				if(stack.op != "Communication.whenReceived"){
					return;
				}
				MBlock.app.interp.runThread(stack, target);
			});
		}
		
		private function __onRecvData(bytes:ByteArray):void
		{
			var buffer:Array = [];
			for(var i:int=0; i<bytes.length; ++i){
				buffer.push(bytes[i]);
			}
			parser.append(buffer);
		}
		
		public function exec(thread:Thread, op:String, argList:Array):void
		{
			switch(op){
				case "isAvailable":
					thread.push(recvMsgList.length > 0);
					break;
				case "isEqual":
					thread.push(argList[0] == argList[1]);
					break;
				case "readLine":
					if(recvMsgList.length > 0){
						thread.push(recvMsgList.shift());
					}else{
						thread.push("");
					}
					break;
				case "writeLine":
					sendMsg(argList[0]);
					break;
				case "writeCommand":
					sendMsg(argList[0] + "=" + argList[1]);
					break;
				case "readCommand":
					if(recvMsgList.length > 0){
						var key:String = argList[0];
						var line:String = recvMsgList.shift();
						var index:int = line.indexOf(key + "=");
						if(index == 0){
							thread.push(line.slice(key.length+1));
							return;
						}
					}
					thread.push("");
					break;
				case "clearBuffer":
					recvMsgList.length = 0;
					break;
			}
		}
		
		private function sendMsg(msg:String):void
		{
			if(!SocketManager.sharedManager().isConnected){
				return;
			}
			var bytes:ByteArray = new ByteArray();
			bytes.writeByte(0xFF);
			bytes.writeByte(0x55);
			bytes.writeByte(0);
			bytes.writeByte(4);
			bytes.writeByte(0);
			if(msg.length > 0){
				bytes.writeUTFBytes(msg);
				bytes[4] = bytes.length - 5;
			}
			bytes.writeByte(0xD);
			bytes.writeByte(0xA);
			SocketManager.sharedManager().sendBytes(bytes);
		}
	}
}