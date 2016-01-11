package cc.makeblock.interpreter
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	internal class PacketParser
	{
		private var buffer:Array = [];
		private const ba:ByteArray = new ByteArray();
		private var callback:Function;
		
		public function PacketParser(callback:Function)
		{
			ba.endian = Endian.LITTLE_ENDIAN;
			this.callback = callback;
		}
		
		public function append(bytes:Array):void
		{
			if(bytes == null || bytes.length <= 0){
				return;
			}
			buffer.push.apply(null, bytes);
			parse();
		}
		
		private function parse():void
		{
			for(;;){
				if(buffer.length < 4){
					return;
				}
				if(buffer[0] == 0xFF && buffer[1] == 0x55){
					break;
				}
				buffer.shift();
			}
			if(buffer[2] == 0x0D && buffer[3] == 0x0A){
				buffer.splice(0, 4);
				callback();
			}else{
				ba.clear();
				var index:int = buffer[2];
				var value:*;
				switch(buffer[3]){
					case 1:
						if(buffer.length < 7){
							return;
						}
						value = buffer[4];
						buffer.splice(0, 7);
						break;
					case 2:
					case 5:
						if(buffer.length < 10){
							return;
						}
						ba.writeByte(buffer[4]);
						ba.writeByte(buffer[5]);
						ba.writeByte(buffer[6]);
						ba.writeByte(buffer[7]);
						ba.position = 0;
						value = ba.readFloat();
						buffer.splice(0, 10);
						break;
					case 3:
						if(buffer.length < 8){
							return;
						}
						ba.writeByte(buffer[4]);
						ba.writeByte(buffer[5]);
						ba.position = 0;
						value = ba.readShort();
						buffer.splice(0, 8);
						break;
					case 4:
						if(buffer.length < 5){
							return;
						}
						var n:int = buffer[4];
						if(buffer.length < n + 7){
							return;
						}
						for(var i:int=0; i<n; ++i){
							ba.writeByte(buffer[5+i]);
						}
						ba.position = 0;
						value = ba.readUTFBytes(n);
						buffer.splice(0, n + 7);
						break;
					default:
						buffer.splice(0, 4);
						return;
				}
				if(index == 0x80){//button pressed
					MBlock.app.runtime.mbotButtonPressed.notify(Boolean(value));
				}else{
					callback(value);
				}
			}
			parse();
		}
	}
}