package cc.makeblock.util
{
	public class UploadSizeInfo
	{
		static private const begin:RegExp = /writing flash \((\d+) bytes\):/;
		static private const regExp:RegExp = /\[\w+\]/g;
		
		private var bytesTotal:int;
		private var bytesLoad:int;
		
		private var buffer:String;
		
		public function UploadSizeInfo()
		{
		}
		
		public function reset():void
		{
			bytesTotal = 0;
			bytesLoad = 0;
			buffer = "";
		}
		
		public function update(msg:String):int
		{
			buffer += msg;
			if(bytesTotal > 0){
				calcBytesLoad();
				return 100 * bytesLoad / bytesTotal;
			}
			var result:Object = begin.exec(buffer);
			if(result != null){
				bytesTotal = parseInt(result[1]);
				buffer = buffer.slice(result.index + result[0].length);
			}
			return 0;
		}
		
		private function calcBytesLoad():void
		{
			var n:int = buffer.length;
			var index:int = 0;
			for(var i:int=0; i < n; ++i){
				switch(buffer.charAt(i)){
					case "S":
					case "R":
						break;
					default:
						continue;
				}
				switch(buffer.substr(i, 5)){
					case "Send:":
						index = buffer.indexOf("\r", i);
						if(index > 0 && buffer.charAt(i+6) == "d"){
							bytesLoad += buffer.slice(i+7, index).match(regExp).length - 5;
						}
						break;
					case "Recv:":
						index = buffer.indexOf("\r", i);
						break;
					default:
						continue;
				}
				if(index < 0){
					index = i;
					break;
				}
				i = index;
			}
			if(index > 0){
				buffer = buffer.slice(index);
			}
		}
	}
}